{config, lib, pkgs, ...}: let
  cfg = config.services.easytier.netns;

  # veth 网段拆成 prefix + hostHost 两部分：
  #   linkPrefix    链路网段（不含掩码），如 192.168.100
  #   hostLastOctet 宿主侧 veth 地址的末位，如 253 → 192.168.100.253
  # netns 侧固定取 .1。这样两台机器只要改 linkPrefix 即可错开，无需重写多处。
  linkPrefix = cfg.linkPrefix;
  linkCidr = "${linkPrefix}.0/24";
  hostAddr = "${linkPrefix}.${toString cfg.hostLastOctet}";
  peerAddr = "${linkPrefix}.1";
  netnsName = cfg.name;
  vethHost = cfg.vethHost;    # 宿主侧，≤15 字符（IFNAMSIZ）
  vethPeer = "${cfg.vethHost}-p"; # netns 内侧临时名
  vethPeerFinal = "veth-wan"; # 移入 netns 后改名

  # 宿主侧需要经 veth 路由进 netns 的网段，手动维护。
  #
  # 隔离后远端内网段只存在于 netns 内 easytier 的路由表，宿主看不到；宿主
  # 需要自己的静态路由才能经 veth 访问它们（含 mihomo 的上游代理）。
  # 对方增减 subnet proxy 时要手工同步这里，查当前值：
  #   sudo ip netns exec easytier ip route show dev easytier0
  #
  # 两条必须遵守的约束（改地址前务必读一遍）：
  #   1. linkPrefix 是"宿主访问通道"，取本机 proxy_network 声明导出的段
  #      （组网设备靠这个声明把流量路由到本机）。绝不能取远端内网段 ——
  #      那会占用远端真实设备的地址（如 192.168.100.253），导致访问不到。
  #   2. linkPrefix 绝不能与组网虚拟网段（如 10.126.126.0/24）重叠 ——
  #      宿主若也直连该段，回程包会被送回 veth 形成环路。
  #
  # routes 里不要填 linkPrefix 自身：那段是直连的，加 via 路由反而冲突。
  virtualRoutes = cfg.routes;

  # mihomo 出站用的 SO_MARK 及其放行规则。
  #
  # mihomo 的 auto-detect-interface 只按「接口地址前缀」选网卡，不读路由表，
  # 而通道 veth 的前缀（192.168.10.0/24）不覆盖远端代理（192.168.100.254），
  # 所以 auto-detect 会回落到物理网卡导致出站全断。改用 routing-mark：
  # 标记过的出站 socket 不绑任何网卡，纯由内核路由表决定去向 —— 静态
  # 路由把远端段指向 veth，于是自动经组网出去。
  # 这条 ip rule 必须比 mihomo 自己生成的规则（pref 9000+）更靠前。
  mihomoMark = 6666;
  mihomoMarkRule = "pref 8999 fwmark ${toString mihomoMark} lookup main";

  # netns + veth 的建立脚本。整个脚本设计为可重复执行：
  # 宿主异常重启可能留下没有对端的 veth，先无条件清理再建。
  setupScript = pkgs.writeShellScript "easytier-netns-setup" ''
    set -euo pipefail

    # 1. 命名空间。已存在则跳过（systemd 重启服务时不重复建）
    if ! ip netns list | grep -qw ${netnsName}; then
      ip netns add ${netnsName}
    fi

    # 2. 清理可能残留的 veth（宿主异常重启后可能只留下单边）
    ip link del ${vethHost} 2>/dev/null || true

    # 3. 建立 veth 对，一端留宿主、一端进 netns
    ip link add ${vethHost} type veth peer name ${vethPeer}
    ip link set ${vethPeer} netns ${netnsName}
    ip -n ${netnsName} link set ${vethPeer} name ${vethPeerFinal}

    # 4. 宿主侧地址。linkPrefix 是本机 proxy_network 声明导出的段，
    #    组网设备靠它把流量路由到宿主，从而访问 <hostAddr>。
    #    绝不在这里配远端内网段（会占用远端真实设备地址），
    #    也绝不能配组网虚拟网段（如 10.126.126.0/24）：那与 netns 内
    #    easytier0 同段，宿主若也直连该段，回程包会被送回 veth 形成环路。
    ip addr replace ${hostAddr}/24 dev ${vethHost}
    ip link set ${vethHost} up

    # 5. netns 侧地址与默认路由。默认路由回宿主，隧道出向流量由宿主 NAT，
    #    这样对端 peer 看到的源 IP 与隔离前（easytier 直跑宿主）一致，
    #    不需要对方放行新网段。
    ip -n ${netnsName} addr replace ${peerAddr}/24 dev ${vethPeerFinal}
    ip -n ${netnsName} link set ${vethPeerFinal} up
    ip -n ${netnsName} link set lo up
    ip -n ${netnsName} route replace default via ${hostAddr} dev ${vethPeerFinal}

    # 6. netns 内需要转发：组网流量进 tunnel，隧道流量出 tunnel
    ip netns exec ${netnsName} sysctl -qw net.ipv4.ip_forward=1

    # 7. 宿主侧到组网网段的显式路由。这些网段只存在于 netns 内，
    #    宿主靠这些静态路由经 veth 访问（含 mihomo 的上游代理）。
    ${lib.concatMapStringsSep "\n" (r: "ip route replace ${r} via ${peerAddr} dev ${vethHost}") virtualRoutes}

    # 8. 放行带 mihomo 标记的出站流量。
    #    mihomo 开启 routing-mark 后不绑任何网卡，纯走内核路由表；这条规则
    #    把它从 mihomo 自己的 TUN 路由表（pref 9000+）里摘出来，否则出站会
    #    被自己的 TUN 捕获形成回环。pref 必须小于 9000。
    ip rule del ${mihomoMarkRule} 2>/dev/null || true
    ip rule add ${mihomoMarkRule}
  '';
in {
  # EasyTier 隔离到独立网络命名空间时的参数。
  #
  # 每台机器必须用不同的 linkPrefix：两台机器若用同一段，各自 netns 里的
  # easytier 仍能工作（组网地址由 easytier 分配，互不冲突），但宿主侧的
  # 路由会指向各自的 netns，容易在排障时混淆。错开段也让"从组网访问某台
  # 宿主机"的地址天然可区分。
  options.services.easytier.netns = {
    enable = lib.mkEnableOption "running EasyTier inside a dedicated network namespace";

    name = lib.mkOption {
      type = lib.types.str;
      default = "easytier";
      description = "Network namespace name (and /run/netns path).";
    };

    vethHost = lib.mkOption {
      type = lib.types.str;
      default = "veasy0";
      description = ''
        Host-side veth interface name. Must be at most 15 characters
        (IFNAMSIZ). The peer is temporarily named "<name>-p" and renamed
        to "veth-wan" after being moved into the namespace.
      '';
    };

    linkPrefix = lib.mkOption {
      type = lib.types.str;
      default = "192.168.10";
      description = ''
        Link subnet prefix without mask, e.g. "192.168.10" yields
        192.168.10.0/24 on the link, 192.168.10.1 inside the namespace
        and 192.168.10.<hostLastOctet> on the host.

        This is the host's access channel: peers reach the host at
        "<linkPrefix>.<hostLastOctet>" because this host advertises the
        subnet through proxy_network. Pick a segment that belongs to this
        host — never a remote subnet, since occupying e.g. 192.168.100.253
        would shadow the real device at that address.

        It must NOT overlap the EasyTier virtual subnet (e.g.
        10.126.126.0/24) or return traffic will loop back into the veth.
        Give each host its own prefix.
      '';
    };

    hostLastOctet = lib.mkOption {
      type = lib.types.port;
      default = 253;
      description = ''
        Last octet of the host-side veth address, i.e.
        "<linkPrefix>.<hostLastOctet>". Keep it out of .0 and .255.
      '';
    };

    routes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "10.126.126.0/24"
        "192.168.100.0/24"
      ];
      description = ''
        Subnets the host routes into the namespace through the veth, as
        static routes via <linkPrefix>.1.

        Must include the EasyTier virtual subnet and every remote subnet
        reachable through the tunnel — those only exist inside the
        namespace's routing table, so the host needs its own routes.
        mihomo's upstream proxy lives in one of them, which is how it
        reaches the proxy across the tunnel. Maintain manually; inspect
        the current set with:

          sudo ip netns exec easytier ip route show dev easytier0

        Do not list linkPrefix itself: that segment is directly connected
        and a via route for it would conflict.
      '';
    };
  };

  config = {
  # EasyTier：点对点虚拟组网（P2P VPN / 内网穿透）
  # 配置文件在 /var/lib 下由本机维护，避免密钥进入 Git 或 Nix store。
  services.easytier.enable = true;

  # 允许本机作为转发节点（多跳 / 出口流量需要）
  # netns 内的 forwarding 由下面的 oneshot 单独打开，这个选项影响的是宿主。
  services.easytier.allowSystemForward = true;

  services.easytier.instances.default = {
    enable = true;
    configFile = "/var/lib/easytier/easytier.toml";
  };

  # EasyTier 不负责创建这个目录；目录本身也不能让普通用户读取。
  systemd.tmpfiles.rules = [
    "d /var/lib/easytier 0700 root root -"
  ];

  # 创建命名空间与 veth。netns 本身是 /run 下的运行时对象，重启即消失，
  # 所以这一步必须由 systemd 在 easytier 之前执行。脚本整体可重复运行。
  systemd.services.easytier-netns = lib.mkIf cfg.enable {
    description = "EasyTier network namespace and veth pair";
    wantedBy = [ "multi-user.target" ];
    before = [ "easytier-default.service" ];
    # 脚本用到 ip / grep
    path = [
      pkgs.iproute2
      pkgs.gnugrep
      pkgs.coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # veth 与路由操作需要 root 能力；用 root 而非 DynamicUser。
      # 写成脚本而非多行 ExecStart：systemd 按空白切分命令，无法处理换行与 `||`
      ExecStart = "${setupScript}";
    };
  };

  # netns 内要用到 ip（easytier 自己会拉起接口），补上 PATH 依赖
  systemd.services.easytier-default = lib.mkMerge [
    { path = [ pkgs.easytier ]; }
    (lib.mkIf cfg.enable {
      requires = [ "easytier-netns.service" ];
      after = [ "easytier-netns.service" ];
      serviceConfig = {
        # systemd 261 支持：把服务放进指定 netns
        NetworkNamespacePath = "/run/netns/${netnsName}";
        # netns 由外部 oneshot 提供，这里不能再让 systemd 自己造一个
        PrivateNetwork = false;
        # 需要在 netns 内创建 TUN 设备，不要限制命名空间相关调用
        RestrictNamespaces = false;
      };
    })
  ];

  # 宿主 NAT：netns 内的隧道出向流量 masquerade 到物理网卡。
  # 这样 easytier 连公共服务器（11010-11012）时源 IP 是宿主地址，
  # 与隔离前的行为一致，对端无需放行新网段。
  # 依赖 modules/networking.nix 里开启的 networking.nftables.enable。
  networking.nftables.tables = lib.mkIf cfg.enable {
    nat = {
      family = "ip";
      content = ''
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          # netns 内隧道出向流量 masquerade 到物理网卡
          ip saddr ${peerAddr} masquerade
        }
      '';
    };
  };
  };
}