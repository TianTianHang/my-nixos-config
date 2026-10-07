{config, lib, pkgs, ...}: let
  cfg = config.networking.mihomo;
in {
  # mihomo（Clash.Meta 内核）：TUN 透明代理 + 国内外分流
  #
  # 默认关闭，需要的机器在 hosts/<host>/default.nix 里打开：
  #   networking.mihomo.enable = true;
  #
  # 上游出口写死在 mihomo/config.yaml（虚拟组网另一侧的 HTTP 代理），
  # 本机不保存任何订阅链接或节点密钥，所以配置文件可以入库。
  #
  # 出站网卡选择依赖 auto-detect-interface（保持默认开启）。它按「接口地址
  # 前缀」匹配目标地址来决定绑哪张网卡，因此要求 easytier 已被隔离到独立
  # netns、宿主侧留一张带 192.168.100.0/24 前缀的 veth（见 modules/easytier.nix）。
  # 若直接在宿主上跑 easytier，该网段只是静态路由而非接口地址，探测会回落到
  # 物理网卡，所有出站都会超时。
  options.networking.mihomo = {
    enable = lib.mkEnableOption "the mihomo rule-based proxy daemon";
  };

  config = lib.mkIf cfg.enable {
    services.mihomo = {
      enable = true;
      package = pkgs.mihomo;

      # 仓库内跟踪的规则配置，经 systemd LoadCredential 注入
      # （服务用 DynamicUser + PrivateUsers，配置文件本身不落到 /etc）
      configFile = ../config/mihomo/config.yaml;

      # 本地 Web UI（metacubexd），只在 127.0.0.1:9090 监听
      webui = pkgs.metacubexd;

      # TUN 模式需要额外能力，并放宽 mihomo.nix 默认的沙箱设置
      tunMode = true;
    };

    # TUN 设备由内核 tun 模块提供，nixpkgs 默认已带，这里显式声明以防内核裁剪
    boot.kernelModules = [ "tun" ];
    # geodata 缓存、cache.db 等由服务自身的 StateDirectory 承载，
    # services.mihomo 用了 DynamicUser，systemd 会自动建目录，无需 tmpfiles
  };
}