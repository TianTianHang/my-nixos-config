final: prev:
let
  patchedUnwrapped = prev.anime-game-launcher.unwrapped.overrideAttrs (old: {
    patches = (old.patches or []) ++ [
      ./patches/aagl.patch
      ./patches/aagl-cargo-lock.patch
    ];

    # AAGL 将 anime-launcher-sdk 和 anime-game-core 作为 Cargo git 依赖
    # vendor 进 cargoDeps。cargoSetupHook 会在 postUnpack 阶段把它复制为
    # 可写目录，因此在 postPatch 阶段对这两个依赖应用本地补丁。
    postPatch = (old.postPatch or "") + ''
      sdk_dir="$(find "$cargoDepsCopy/source-git-1" -maxdepth 1 -type d -name 'anime-launcher-sdk-*' -print -quit)"
      core_dir="$(find "$cargoDepsCopy/source-git-0" -maxdepth 1 -type d -name 'anime-game-core-*' -print -quit)"
      test -n "$sdk_dir"
      test -n "$core_dir"

      patch -d "$cargoDepsCopy" -p1 < ${./patches/aagl-cargo-lock.patch}
      patch -d "$sdk_dir" -p1 < ${./patches/sdk-cargo.patch}
      patch -d "$sdk_dir" -p1 < ${./patches/sdk-env.patch}
      patch -d "$sdk_dir" -p1 < ${./patches/sdk-game.patch}
      patch -d "$core_dir" -p1 < ${./patches/core-downloader.patch}
    '';
  });
in {
  anime-game-launcher = prev.anime-game-launcher.override {
    unwrapped = patchedUnwrapped;
  };
}
