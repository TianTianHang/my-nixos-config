# AGENTS.md

NixOS flake 配置仓库，管理三台个人 x86_64 机器。动手改任何东西之前，先读完「第一步：确定当前机器」。

## 第一步：确定当前机器

本仓库是**三台机器共用**的。同一份代码在不同机器上含义不同，因此每次会话开始、以及在切换上下文时，必须先确认 agent 正在操作哪台机器：

```bash
hostname          # 期望输出 kuangshi / vivobook / tuf
# 或
cat /etc/hostname
```

- 与 `hosts/` 下的目录名一致，即为当前机器。
- 若 `hostname` 不匹配三台机器中的任何一台（例如在容器、chroot 或 CI 中），按「无法确定机器」处理：**只做纯静态检查**（读文件、`nix flake check`、`nix eval`），不要执行 `nixos-rebuild switch`，不要写 `/etc`、不要假定硬件状态。
- 判断结果要影响行为：改共享模块前，先想清楚会不会波及另外两台机器（见下文「改共享代码 vs 主机专属代码」）。

## 三台机器

主机名按**厂商产品线**取，不用通用厂商名（`vivobook` 是 ASUS Vivobook，`tuf` 是 ASUS TUF Gaming）。

| 项目 | `kuangshi` | `vivobook` | `tuf` |
| --- | --- | --- | --- |
| hostName | `kuangshi` | `vivobook` | `tuf` |
| 主机目录 | `hosts/kuangshi/` | `hosts/vivobook/` | `hosts/tuf/` |
| 机型 | 桌面机 | ASUS Vivobook | ASUS TUF Gaming F15 (FX506HC) |
| 桌面 | Niri + Noctalia（`desktop.niri.enable = true`） | Denial（`desktop.denial.enable = true`） | Niri + Noctalia（`desktop.niri.enable = true`） |
| 浏览器 | Zen（`zen-browser` flake 输入，`programs.firefox.enable = false`） | Firefox（共享模块 `mkDefault true`） | Zen（同 kuangshi，见 `hosts/tuf/default.nix`） |
| 图形 | NVIDIA 双显卡 offload（Intel + NVIDIA PRIME） | 集显，默认配置 | Intel Iris Xe 驱动内屏 + RTX 3050 PRIME offload |
| 内核 | `linuxPackages_latest`（共享） | `linuxPackages_latest`（共享） | `linuxPackages_zen`（`mkForce` 覆盖，见下） |
| 特有模块 | AAGL 游戏启动器 | `modules/acpi-fix.nix` | 无（ACPI bug 与 vivobook 不同，见下） |
| 组网 | easytier netns + mihomo | easytier netns + mihomo | **均关闭**（尚未加入组网） |
| sudo | 免密（`wheelNeedsPassword = false`） | 默认（需密码） | 默认（需密码） |
| stateVersion | `26.05` | `26.05` | `26.05` |

三台机器都走 `flake.nix` 里的 `mkX86Host`，因此都加载：各自主机 `default.nix` 里自己列出的 `modules/*.nix` + 该机 `hardware-configuration.nix` + home-manager（用户 `tiantian`，配置在 `home/`）。

**没有 `hosts/common.nix`**：每台主机在 `hosts/<host>/default.nix` 的 `imports` 里直接列出自己需要的模块。这样每个主机文件自解释「这台到底加载了什么」，也让「某台不该加载某模块」变得自然可写（见下）。

`hosts/tuf/` 的三处特别说明：

- **不引 `modules/acpi-fix.nix`**。那份 SSDT 修的是 Vivobook 固件独有的 `CTDP` / `SxCT` 符号缺失。tuf 同样带 Intel DPTF 表，但本机日志里没有对应的 `AE_NOT_FOUND` 报错（只有另一类 `H_EC.SEN2/SEN4/CHRG` 缺失，该模块不覆盖），引了只是白压一个 ACPI override。
- **`boot.kernelPackages` 用 `lib.mkForce`**。`modules/boot.nix` 那处是普通赋值（优先级 100），主机侧直接写会报 `defined multiple times`。
- **不引 `btrfs.nix` / `easytier.nix` / `mihomo.nix`**。tuf 根分区是 ext4，而 `btrfs.nix` 无条件开 `services.btrfs.autoScrub`，NixOS 断言要求至少挂载一个 btrfs 文件系统；tuf 也尚未加入组网（无 `/var/lib/easytier/easytier.toml`）。不引这些模块，根因就被移除，不需要再用 `lib.mkForce false` 去压 `btrfs.nix` 的无条件赋值和 `easytier.nix` 的无条件 `services.easytier.enable`。

## 目录结构

```
flake.nix              # 入口：inputs、overlay、nixosConfigurations（vivobook / kuangshi / tuf）
hosts/
  kuangshi/            # 主机专属：default.nix（含完整 imports）+ hardware-configuration.nix
  vivobook/            # 主机专属：default.nix（含完整 imports）+ hardware-configuration.nix
  tuf/                 # 主机专属：default.nix（含完整 imports）+ hardware-configuration.nix
modules/               # 系统级共享模块（boot、btrfs、networking、nix、user、waydroid…）
  desktops/            # denial.nix / niri.nix，由 desktop.<name>.enable 控制开关
home/tiantian/         # home-manager 用户配置（bash、git、ghostty、niri、noctalia…）
pkgs/                  # 自定义包（overlay 注入）
docs/                  # 专题文档
```

### 三台的 imports 差异

| 模块 | kuangshi | vivobook | tuf |
| --- | --- | --- | --- |
| `boot` `desktop` `flatpak` `greeter` `input-method` `localization` `networking` `nix` `packages` `user` | ✓ | ✓ | ✓ |
| `btrfs` `easytier` `mihomo` | ✓ | ✓ | — |
| `desktops/niri` | ✓ | — | ✓ |
| `desktops/denial` | — | ✓ | — |
| `waydroid` | — | — | — |
| `inputs.aagl` | ✓ | — | — |
| `acpi-fix` | — | ✓ | — |

`waydroid.nix` 三台都不引：模块自身写 `virtualisation.waydroid.enable = false`，而 NixOS 默认即 false，不引等价于不引。

`flatpak.nix` 三台都引（底座）。它只开 `services.flatpak.enable`，**不装任何应用** —— 本版 nixpkgs 没有 `services.flatpak.packages` 这类声明式安装选项。Zotero 走 Nix 包，在 `home/tiantian/packages.nix`。

## 改共享代码 vs 主机专属代码

- **三台机器都要的行为** → 放 `modules/` 或 `home/`；若需可选，用 `lib.mkEnableOption` / `mkIf` 做成开关，再在 `hosts/<host>/default.nix` 里打开。
- **新增共享模块要改三个地方**：`modules/<name>.nix` + 三台 `hosts/*/default.nix` 的 `imports`。仓库没有 common.nix 兜底，漏改哪台就哪台静默缺配置 —— 改完记得对三台都求值验证。
- **只给一台机器的行为** → 放 `hosts/<host>/default.nix`（或该主机目录下的新文件），**不要**改共享模块来迁就单机。
- **硬件相关**（显卡、ACPI、磁盘、内核参数）→ 只在对应主机的 `hardware-configuration.nix` / 主机 `default.nix` 里改。
- **切换桌面**：`desktop.niri.enable` 与 `desktop.denial.enable` 互斥，改一个要确认另一个。注意 `flake.nix` 里只有 Niri 启用时才注入 Noctalia 的 home 模块，别把 Niri 专属配置塞进共享 home 文件。
- 改共享模块后，默认假设**另外两台机器也会构建到它**，必须三台都验证（见下）。
- **某台不该加载某模块时，正确做法是不引它**，而不是引了再 `mkForce` 压掉。前者让 imports 列表如实反映实际生效的配置，后者会掩盖「这个模块本不该上这台」的设计问题。
- **`modules/easytier.nix` 的坑**：`services.easytier.enable` 与 `instances.default.enable` 是无条件打开的，**不受** `netns.enable` 控制。组网中的机器无害（它们 `netns.enable = true`），但这意味着**任何新主机只要引了这个模块就会中招**。根治办法是把那两处收进 `lib.mkIf cfg.enable`，改前先三台验证。

## 常用命令

```bash
# 只构建、不切换（安全，先验证再 apply）
nixos-rebuild build --flake .#$(hostname)

# 确认当前机器后再切换
sudo nixos-rebuild switch --flake .#$(hostname)

# 本机之外的其他机器：只做评估/构建验证，绝不要对它 switch
nix build .#nixosConfigurations.<other>.config.system.build.toplevel

# 语法/结构检查
nix flake check
nix eval .#nixosConfigurations.$(hostname).config.networking.hostName

# 网络受限时：flake 输入已缓存的话，加 --offline 可完全避开网络
nix eval --offline .#nixosConfigurations.$(hostname).config.networking.hostName
```

- 仓库没有 justfile / makefile，命令以 `nixos-rebuild --flake` 为准。
- 构建走国内镜像（SJTU/NJU）+ noctalia/denial cachix，`nix.nix` 里已配置 substituters。
- 改动 `.nix` 后至少对**受影响的三台主机**跑一遍 `nix build`，通过才算完成。
- 新增的 `.nix` 文件必须先 `git add` 才能被 flake 看到 —— Nix 只读 git 跟踪的文件，未跟踪会报 `Path ... is not tracked by Git`。

## 注意事项

- github.com 直连超时的网络里，需要代理 `http://192.168.100.254:7890`：kuangshi 与 tuf 都已在各自 `hosts/<host>/default.nix` 给 `systemd.services.nix-daemon.environment` 配了代理（`sudo nixos-rebuild` 以 root 拉 flake 输入要用它）；命令行里临时拉取可 `export https_proxy=...`。vivobook 未配置，若其网络同样受限需自行添加。
- **tuf 直连全断**（`mirror.sjtu.edu.cn:443`、`github.com:443` 实测都连不上，只有 `192.168.100.254:7890` 通）。由此两个后果：一是命令行里 eval/build 必须先 `export https_proxy=...`，否则拉不到 flake 输入；二是 `nix.nix` 里的 SJTU substituter 在 tuf 上是纯负担（每次都超时重试），实际生效的只有 `cache.nixos.org`。
- **`nix.buildMachines` 的远程 builder（`192.168.100.202`）在 tuf 上不可用**：`nix build` 会卡在远程构建上一个 trivial 派生（实测停在 `unit-nix-daemon.service.drv` 四分钟零进展、无报错），本地 `--builders ''` 则瞬间推进。要在 tuf 上验证构建就加 `--builders ''`，或先修好那台机器。
- 不要提交或泄露 `hardware-configuration.nix` 里的文件系统 UUID 之外的敏感信息；密钥、token 一律不入库。
- `flake.lock` 的更新要单独、有理由地进行，不要顺手升级依赖。
- 新增 host 需要同时改三处：`hosts/<name>/`、`flake.nix` 的 `nixosConfigurations`、以及本文档的机器表格。
- 提交信息沿用现有风格：`feat:` / `fix:` + 简短英文描述（参考 `git log`）。
- 代码注释用中文，保持与现有文件一致。
