{
  lib,
  stdenvNoCC,
  fetchurl,
  zstd,
  gnutar,
}:

let
  version = "0.1.0-20";
  baseUrl = "https://github.com/denialwm/droidloom/releases/download/packages";

  runtime = fetchurl {
    url = "${baseUrl}/droidloom-runtime-${version}-x86_64.pkg.tar.zst";
    hash = "sha256-K24ogIgCFzKB5RCiu/DMJ55dkmHcJc1vXwCf5DLBcOk=";
  };

  image = fetchurl {
    url = "${baseUrl}/droidloom-image-${version}-x86_64.pkg.tar.zst";
    hash = "sha256-0OFN74bJ4FnUfoKq2R92QTG54NCx5eAtaPyM4G01Mmc=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "droidloom";
  inherit version;

  dontUnpack = true;
  nativeBuildInputs = [ zstd gnutar ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    for archive in ${runtime} ${image}; do
      tar --zstd -xf "$archive" -C "$out" \
        --exclude=.PKGINFO --exclude=.BUILDINFO --exclude=.MTREE
    done

    runHook postInstall
  '';

  meta = {
    description = "Android applications in native Wayland windows";
    homepage = "https://github.com/denialwm/droidloom";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
