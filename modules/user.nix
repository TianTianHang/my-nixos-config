{ pkgs, ... }: {
  users.users.tiantian = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
