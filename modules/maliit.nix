{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    maliit-framework
    maliit-keyboard
  ];

  # maliit 环境变量配置
  environment.sessionVariables = {
    # 让 Qt 应用使用 maliit
    QT_IM_MODULE = "maliit";
    # 让 GTK 应用使用 maliit
    GTK_IM_MODULE = "maliit";
  };
}
