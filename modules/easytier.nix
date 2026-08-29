{config, lib, pkgs, ...}: {
  # EasyTier：点对点虚拟组网（P2P VPN / 内网穿透）
  # 暂直接引用仓库外的配置文件 ~/Downloads/easytier.toml（含组网密钥，
  # 不纳入 git / nix store）。后续可改为声明式配置 + 密钥外置。
  services.easytier.enable = true;

  # 允许本机作为转发节点（多跳 / 出口流量需要）
  services.easytier.allowSystemForward = true;

  services.easytier.instances.default = {
    enable = true;
    configFile = /home/tiantian/Downloads/easytier.toml;
  };
}
