{ pkgs, lib, ... }: {
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 默认内核改为 CachyOS（三台主机都在 hosts/*/default.nix 里覆盖成
  # 各自合适的变体，这里只是给未来新增机器一个安全默认：v1 基线、
  # 不带 LTO，任何 x86_64 都能跑）。用 mkDefault 是因为 modules/boot.nix
  # 里这是普通赋值（优先级 100），主机侧再普通赋值会报 defined multiple times。
  boot.kernelPackages = lib.mkDefault pkgs.cachyosKernels.linuxPackages-cachyos-latest;
}
