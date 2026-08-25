{
  networking.networkmanager.enable = true;

  # GitHub520 加速访问，定期从 https://raw.hellogithub.com/hosts 更新 github520.hosts
  networking.extraHosts = builtins.readFile ./github520.hosts;

  services.openssh.enable = true;
}
