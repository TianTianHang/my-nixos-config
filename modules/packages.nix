{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    vim
    wget
    kylin-virtual-keyboard
  ];
}
