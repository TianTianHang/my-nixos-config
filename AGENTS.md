# AGENTS.md

NixOS flake 配置仓库，管理两台个人 x86_64 机器。动手改任何东西之前，先读完「第一步：确定当前机器」。

## 第一步：确定当前机器

本仓库是**两台机器共用**的。同一份代码在不同机器上含义不同，因此每次会话开始、以及在切换上下文时，必须先确认 agent 正在操作哪台机器：

```bash
hostname          # 期望输出 kuangshi 或 vivobook
# 或
cat /etc/hostname
```

- 与 `hosts/` 下的目录名一致，即为当前机器。
- 若 `hostname` 不匹配两台机器中的任何一台（例如在容器、chroot 或 CI 中），按「无法确定机器」处理：**只做纯静态检查**（读文件、`nix flake check`、`nix eval`），不要执行 `nixos-rebuild switch`，不要写 `/etc`、不要假定硬件状态。
- 判断结果要影响行为：改共享模块前，先想清楚会不会波及另一台机器（见下文「改共享代码 vs 主机专属代码」）。

## 两台机器

| 项目 | `kuangshi` | `vivobook` |
| --- | --- | --- |
| hostName | `kuangshi` | `vivobook` |
| 主机目录 | `hosts/kuangshi/` | `hosts/vivobook/` |
| 桌面 | Niri + Noctalia（`desktop.niri.enable = true`） | Denial（`desktop.denial.enable = true`） |
| 浏览器 | Zen（`zen-browser` flake 输入，`programs.firefox.enable = false`） | Firefox（共享模块 `mkDefault true`） |
| 图形 | NVIDIA 双显卡 offload（Intel + NVIDIA PRIME） | 集显，默认配置 |
| 特有模块 | — | `modules/acpi-fix.nix` |
| sudo | 免密（`wheelNeedsPassword = false`） | 默认（需密码） |
| stateVersion | `26.05` | `26.05` |

两台机器都走 `flake.nix` 里的 `mkX86Host`，因此都加载：`hosts/common.nix`（→ `modules/*.nix` 共享模块）+ 各自主机目录 + home-manager（用户 `tiantian`，配置在 `home/`）。

## 目录结构

```
flake.nix              # 入口：inputs、overlay、nixosConfigurations（vivobook / kuangshi）
hosts/
  common.nix           # 两台机器共享的模块导入清单
  kuangshi/            # 主机专属：default.nix + hardware-configuration.nix
  vivobook/            # 主机专属：default.nix + hardware-configuration.nix
modules/               # 系统级共享模块（boot、btrfs、networking、nix、user、waydroid…）
  desktops/            # denial.nix / niri.nix，由 desktop.<name>.enable 控制开关
home/tiantian/         # home-manager 用户配置（bash、git、ghostty、niri、noctalia…）
pkgs/                  # 自定义包（overlay 注入）
docs/                  # 专题文档
```

## 改共享代码 vs 主机专属代码

- **两台机器都要的行为** → 放 `modules/` 或 `home/`；若需可选，用 `lib.mkEnableOption` / `mkIf` 做成开关，再在 `hosts/<host>/default.nix` 里打开。
- **只给一台机器的行为** → 放 `hosts/<host>/default.nix`（或该主机目录下的新文件），**不要**改共享模块来迁就单机。
- **硬件相关**（显卡、ACPI、磁盘、内核参数）→ 只在对应主机的 `hardware-configuration.nix` / 主机 `default.nix` 里改。
- **切换桌面**：`desktop.niri.enable` 与 `desktop.denial.enable` 互斥，改一个要确认另一个。注意 `flake.nix` 里只有 Niri 启用时才注入 Noctalia 的 home 模块，别把 Niri 专属配置塞进共享 home 文件。
- 改共享模块后，默认假设**另一台机器也会构建到它**，必须两台都验证（见下）。

## 常用命令

```bash
# 只构建、不切换（安全，先验证再 apply）
nixos-rebuild build --flake .#kuangshi      # 当前是 kuangshi 时
nixos-rebuild build --flake .#vivobook      # 当前是 vivobook 时

# 确认当前机器后再切换
sudo nixos-rebuild switch --flake .#$(hostname)

# 本机之外的另一台机器：只做评估/构建验证，绝不要对它 switch
OTHER=$( [ "$(hostname)" = kuangshi ] && echo vivobook || echo kuangshi )
nix build .#nixosConfigurations.$OTHER.config.system.build.toplevel

# 语法/结构检查
nix flake check
nix eval .#nixosConfigurations.$(hostname).config.networking.hostName
```

- 仓库没有 justfile / makefile，命令以 `nixos-rebuild --flake` 为准。
- 构建走国内镜像（SJTU/NJU）+ noctalia/denial cachix，`nix.nix` 里已配置 substituters。
- 改动 `.nix` 后至少对**受影响的两台主机**跑一遍 `nix build`，通过才算完成。

## 注意事项

- github.com 直连超时的网络里，需要代理 `http://192.168.100.254:7890`：kuangshi 已在 `hosts/kuangshi/default.nix` 给 `systemd.services.nix-daemon.environment` 配了代理（拉 flake 输入、构建时下载 FOD 源码都靠它）；命令行里临时拉取可 `export https_proxy=...`。vivobook 未配置，若其网络同样受限需自行添加。
- 不要提交或泄露 `hardware-configuration.nix` 里的文件系统 UUID 之外的敏感信息；密钥、token 一律不入库。
- `flake.lock` 的更新要单独、有理由地进行，不要顺手升级依赖。
- 新增 host 需要同时改三处：`hosts/<name>/`、`flake.nix` 的 `nixosConfigurations`、以及本文档的机器表格。
- 提交信息沿用现有风格：`feat:` / `fix:` + 简短英文描述（参考 `git log`）。
- 代码注释用中文，保持与现有文件一致。
