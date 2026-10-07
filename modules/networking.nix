{
  networking.networkmanager.enable = true;

  # 显式开启 nftables 后端。默认的 networking.firewall 也走 nftables，
  # 但只有这一项为真时 networking.nftables.tables 才会生成规则文件，
  # 供需要自己追加 NAT / 过滤规则的模块使用（例如 modules/easytier.nix
  # 为隔离出去的 netns 加 masquerade）。
  networking.nftables.enable = true;

  # GitHub520 加速访问，定期从 https://raw.hellogithub.com/hosts 更新 github520.hosts
  networking.extraHosts = builtins.readFile ./github520.hosts;

  services.openssh.enable = true;
}
