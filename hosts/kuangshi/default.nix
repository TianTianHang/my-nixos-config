{...}: {
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "kuangshi";

  desktop.denial.enable = false;
  desktop.niri.enable = true;

  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:2:0:0";
    };
  };

  users.users.tiantian.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILF47iRw0YgSWTbmYgnLMLyDeKXb0POLi80SINgeGl52 nix-builder-key"
  ];
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
