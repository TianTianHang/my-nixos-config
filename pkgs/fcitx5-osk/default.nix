{
  lib,
  rustPlatform,
  pkg-config,
  makeWrapper,
  dbus,
  wayland,
  libxkbcommon,
  openssl,
  freetype,
  fontconfig,
  libGL,
  expat,
  fetchFromGitHub,
  substitute,
}:

rustPlatform.buildRustPackage rec {
  pname = "fcitx5-osk";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "fortime";
    repo = "fcitx5-osk";
    rev = "${version}";
    hash = "sha256-g1klvPXGWMZlxVZHEP8JPQT6P1I260vvqU4npyLP4cQ=";
  };

  cargoLock.lockFile = ./Cargo.lock;
  cargoLock.outputHashes = {};

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    dbus
    wayland
    libxkbcommon
    openssl
    freetype
    fontconfig
    libGL
    expat
  ];

  postInstall = ''
    # Wrap binaries with LD_LIBRARY_PATH for dlopen'd libraries
    wrapProgram $out/bin/fcitx5-osk \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"
    wrapProgram $out/bin/fcitx5-osk-key-helper \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"
    wrapProgram $out/bin/fcitx5-osk-kwin-launcher \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}"

    # Install desktop files
    mkdir -p $out/share/applications
    substitute $src/pkg/share/applications/fyi.fortime.Fcitx5Osk.desktop.in \
      $out/share/applications/fyi.fortime.Fcitx5Osk.desktop \
      --replace-fail '@INSTALL_BIN_DIR@' "$out/bin"
    substitute $src/pkg/share/applications/fyi.fortime.Fcitx5Osk.KwinLauncher.desktop.in \
      $out/share/applications/fyi.fortime.Fcitx5Osk.KwinLauncher.desktop \
      --replace-fail '@INSTALL_BIN_DIR@' "$out/bin"

    # Install D-Bus service files
    mkdir -p $out/share/dbus-1/services
    substitute $src/pkg/share/dbus-1/services/fyi.fortime.Fcitx5Osk.service.in \
      $out/share/dbus-1/services/fyi.fortime.Fcitx5Osk.service \
      --replace-fail '@INSTALL_BIN_DIR@' "$out/bin"
    substitute $src/pkg/share/dbus-1/services/fyi.fortime.Fcitx5Osk.KwinLauncher.service.in \
      $out/share/dbus-1/services/fyi.fortime.Fcitx5Osk.KwinLauncher.service \
      --replace-fail '@INSTALL_BIN_DIR@' "$out/bin"

    # Install D-Bus system config
    mkdir -p $out/etc/dbus-1/system.d
    cp $src/pkg/share/dbus-1/system.d/fyi.fortime.Fcitx5OskKeyHelper.conf \
      $out/etc/dbus-1/system.d/

    # Install systemd service
    mkdir -p $out/lib/systemd/system
    substitute $src/pkg/lib/systemd/system/fcitx5-osk-key-helper.service.in \
      $out/lib/systemd/system/fcitx5-osk-key-helper.service \
      --replace-fail '@INSTALL_BIN_DIR@' "$out/bin"

    # Install icon
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp $src/assets/icons/fcitx5-osk.svg $out/share/icons/hicolor/scalable/apps/fyi.fortime.Fcitx5Osk.svg

    # Install license
    mkdir -p $out/share/licenses/fcitx5-osk
    cp $src/LICENSE $out/share/licenses/fcitx5-osk/

    # Install fcitx5-osk data (themes, custom_actions, layouts)
    mkdir -p $out/share/fcitx5-osk
    cp -r $src/pkg/share/fcitx5-osk/* $out/share/fcitx5-osk/

    # Install example layouts and key sets
    mkdir -p $out/share/fcitx5-osk/examples
    cp -r $src/assets/layouts $out/share/fcitx5-osk/examples/
    cp -r $src/assets/key_sets $out/share/fcitx5-osk/examples/

    # Create default theme symlink
    mkdir -p $out/etc/xdg/fcitx5-osk/themes
    ln -s $out/share/fcitx5-osk/themes/breeze-light.toml \
      $out/etc/xdg/fcitx5-osk/themes/breeze-light.toml
  '';

  meta = with lib; {
    description = "An on-screen keyboard working with fcitx5";
    homepage = "https://github.com/fortime/fcitx5-osk";
    license = licenses.mit;
    maintainers = [];
    platforms = platforms.linux;
    mainProgram = "fcitx5-osk";
  };
}
