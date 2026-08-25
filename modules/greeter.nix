{
  # noctalia-greeter 登录界面（greetd）。
  # 模块默认：启用 greetd、accounts-daemon（用户头像）与 polkit，
  # 并将 greetd default_session 指向 noctalia-greeter-session
  programs.noctalia-greeter = {
    enable = true;

    settings = {
      # 启动时预选 Niri 会话；名称需与 `noctalia-greeter sessions` 输出一致，
      # 无效名称会被忽略并回退到上次选择
      session.default = "Niri";

      # 跳过用户列表，直接进入该账户的密码输入（Esc 可返回列表）
      user.default = "tiantian";
    };
  };
}
