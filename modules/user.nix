{ pkgs, ... }: {
  users.users.tiantian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # 登录 shell 为 zsh（home/tiantian/zsh.nix 配置本体）。
    # 切回 bash：改为 pkgs.bash 并 rebuild
    shell = pkgs.zsh;
  };

  # NixOS 断言要求：shell 设为 zsh 时系统级必须启用，
  # 否则 zsh 缺少基础 PATH 无法登录（与 home-manager 的用户级 programs.zsh 各管各的）
  programs.zsh.enable = true;
}
