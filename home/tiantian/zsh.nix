{pkgs, ...}: {
  # 登录 shell 切换在系统级 modules/user.nix（users.users.tiantian.shell），
  # 切回 bash：把那里的 pkgs.zsh 改为 pkgs.bash 并 rebuild（bash.nix 模块保留，互不干扰）
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    history = {
      size = 100000;
      save = 100000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      # 主题交给 powerlevel10k（见下方 initContent），omz 自带主题不加载
      theme = "";
      plugins = ["git" "sudo" "extract"];
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        src = pkgs.zsh-nix-shell;
        file = "share/zsh/plugins/zsh-nix-shell/nix-shell.plugin.zsh";
      }
    ];

    # initContent 位于 zshrc 末尾，保证 p10k 在 oh-my-zsh 之后加载。
    # 首次启动 p10k 会进入交互式配置向导，选完样式自动写入 ~/.p10k.zsh。
    initContent = ''
      # 补全大小写不敏感：foo 能补全出 Foo
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';
  };
}
