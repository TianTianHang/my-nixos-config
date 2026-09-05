{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  glib,
  spdlog,
  fcitx5,
  kdePackages,
  lomiri-qt6,
  qt6,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kylin-virtual-keyboard";
  version = "0-unstable-2025-08-25";

  src = fetchFromGitHub {
    owner = "GXDE-OS";
    repo = "kylin-virtual-keyboard";
    rev = "9c8ca6addbe27fadd6178e83b7a5a9e7c303e506";
    hash = "sha256-ybm64aNzlJ783A+lsOIR1EjdJEVF5IVoQUO4IVAYZrY=";
  };

  patches = [
    ./patches/generic-wayland.patch
    ./patches/guard-missing-fcitx-backend.patch
    ./patches/native-wayland-launch.patch
    ./patches/wayland-layer-shell.patch
    ./patches/wayland-layer-position.patch
    ./patches/drag-and-startup.patch
    ./patches/persist-wayland-drag-position.patch
    ./patches/use-tracked-drag-position.patch
    ./patches/visibility-actions.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    glib
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    spdlog
    fcitx5
    kdePackages.kwindowsystem
    lomiri-qt6.gsettings-qt
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qt5compat
    qt6.qtwayland
    kdePackages.fcitx5-qt
    kdePackages.layer-shell-qt
  ];

  postPatch = ''
    substituteInPlace data/CMakeLists.txt \
      --replace-fail "/etc/xdg/autostart" "${placeholder "out"}/etc/xdg/autostart"

  '';

  postInstall = ''
    glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  postFixup = ''
    wrapProgram $out/bin/kylin-virtual-keyboard \
      --prefix XDG_DATA_DIRS : "$out/share/gsettings-schemas/$name"
  '';

  meta = {
    description = "Virtual keyboard for GXDE desktop environment";
    homepage = "https://github.com/GXDE-OS/kylin-virtual-keyboard";
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "kylin-virtual-keyboard";
  };
})
