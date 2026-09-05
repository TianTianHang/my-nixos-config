{...}: {
  # EasyTier：点对点虚拟组网（P2P VPN / 内网穿透）
  # 配置文件在 /var/lib 下由本机维护，避免密钥进入 Git 或 Nix store。
  services.easytier.enable = true;

  # 允许本机作为转发节点（多跳 / 出口流量需要）
  services.easytier.allowSystemForward = true;

  services.easytier.instances.default = {
    enable = true;
    configFile = "/var/lib/easytier/easytier.toml";
  };

  # EasyTier 不负责创建这个目录；目录本身也不能让普通用户读取。
  systemd.tmpfiles.rules = [
    "d /var/lib/easytier 0700 root root -"
  ];
}
