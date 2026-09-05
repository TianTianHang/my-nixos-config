# kylin-virtual-keyboard 调查记录

## 结论

`kylin-virtual-keyboard` 不是 Fcitx5 addon，而是一个独立的 Qt GUI
程序。Fcitx5 自带 `virtualkeyboard` addon，键盘 GUI 与 Fcitx5 通过两组
D-Bus 接口通信。

niri 是 Wayland 合成器，但上游的原生 Wayland 支持只适用于 UKUI/wlcom，
因为它依赖以下 UKUI 私有窗口属性：

- `ukui_surface_role`
- `ukui_surface_state`
- `ukui_surface_anchor`
- `ukui_surface_no_titlebar`
- `ukui_surface_blur`

niri 不实现这些属性。因此 niri 应使用上游提供的 XWayland/XCB 路径，依赖
`xwayland-satellite` 提供 `DISPLAY`。

## 反复打开和关闭的原因

上游的可见性由 Fcitx5 统一管理：

```text
托盘/悬浮球/QML
  -> org.fcitx.Fcitx5 /virtualkeyboard
  -> Fcitx5 virtualkeyboard addon
  -> org.fcitx.Fcitx5.VirtualKeyboard
  -> kylin-virtual-keyboard
```

程序隐藏时会销毁 `QQuickView`。非 preload 模式的状态机流程为：

```text
Show -> 创建 QQuickView -> Hide -> 隐藏动画 -> 销毁 QQuickView
     -> 新的 Show -> 再次创建 QQuickView
```

在 niri 下，Fcitx5 可能因没有有效输入上下文或窗口状态不符合 UKUI 预期，
在 Show 后立即发出 Hide。托盘、悬浮球和 QML 关闭按钮继续通过 Fcitx5
转发请求，会放大这个反馈循环。

## 代码中的关键位置

- `src/virtualkeyboard/virtualkeyboardmanager.cpp`
  - `showVirtualKeyboard()` 显示本地窗口
  - `hideVirtualKeyboard()` 隐藏并最终销毁窗口
  - `hide()` 上游实现会通过 callback 请求 Fcitx5 隐藏
- `src/virtualkeyboardentry/virtualkeyboardtrayicon.cpp`
  - 上游托盘切换通过 Fcitx5 D-Bus 请求显示/隐藏
- `src/virtualkeyboardentry/floatbuttonmanager.cpp`
  - 创建悬浮球时请求 Fcitx5 隐藏
  - 点击悬浮球时请求 Fcitx5 显示
- `src/virtualkeyboard/virtualkeyboardview.cpp`
  - UKUI + Wayland 才设置 UKUI 私有属性
  - 其他环境使用 X11 风格窗口 flags
- `data/org.ukui.virtualkeyboard.start.sh.in`
  - UKUI + Wayland 使用 Qt 原生 Wayland
  - 其他环境强制 `QT_QPA_PLATFORM=xcb`

## Nix 配置注意事项

`kylin-virtual-keyboard` 不应放入
`i18n.inputMethod.fcitx5.addons`。该列表用于 Fcitx5 addon 包，而该项目
没有 Fcitx addon `.so` 或 addon 配置文件。

正确关系是：

```text
fcitx5 自带 virtualkeyboard addon
  <-> kylin-virtual-keyboard 独立 GUI
```

打包时需要提供 GSettings schema 路径，否则会出现：

```text
INCORRECT GSETTINGS ID :org.ukui.virtualkeyboard
g_settings_schema_source_lookup: assertion 'source != NULL' failed
```

## 当前适配方向

当前包补丁将托盘、悬浮球和 QML 关闭路径改为直接操作
`VirtualKeyboardManager`，避免入口侧重复经过 Fcitx5 的显示/隐藏反馈链。
Fcitx5 D-Bus 仍用于输入内容、候选词和 backend 通信。

点击按键崩溃的另一个根因是 `VirtualKeyboardModel::processKeyEvent()` 和
`selectCandidate()` 在 `org.fcitx.Fcitx5.VirtualKeyboardBackend` 未注册时，
仍直接对空的 `QDBusInterface` 调用 `asyncCall()`。core dump 栈顶为
`QDBusAbstractInterface::asyncCallWithArgumentList`，随后是
`VirtualKeyboardModel::processKeyEvent` 和 QML 的触摸事件处理。当前包补丁
在 backend 不可用时跳过操作并记录 warning。

niri 配置使用：

```kdl
window-rule {
  match app-id="kylin-virtual-keyboard"
  open-floating true
}
```

## 验证命令

```bash
systemctl --user cat 'app-kylin\\x2dvirtual\\x2dkeyboard@autostart.service'
pgrep -a -f kylin-virtual-keyboard
niri msg windows
busctl --user status org.fcitx.Fcitx5.VirtualKeyboard
```

确认 niri 会话使用 XWayland 路径：

```bash
pid=$(pgrep -n -f kylin-virtual-keyboard)
tr '\\0' '\\n' < /proc/$pid/environ | rg \
  'QT_QPA_PLATFORM|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|WAYLAND_DISPLAY|DISPLAY'
```

预期为 `XDG_CURRENT_DESKTOP=niri`、`XDG_SESSION_TYPE=wayland`，并且启动
脚本为非 UKUI 分支，设置 `QT_QPA_PLATFORM=xcb`。

查看 Fcitx5 可见性请求：

```bash
dbus-monitor --session \
  "interface='org.fcitx.Fcitx.VirtualKeyboard1',path='/virtualkeyboard'"
```

查看 GUI 服务请求：

```bash
dbus-monitor --session \
  "interface='org.fcitx.Fcitx5.VirtualKeyboard1',path='/org/fcitx/virtualkeyboard/impanel'"
```
