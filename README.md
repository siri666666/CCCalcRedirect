# CCCalcRedirect

一个极简、零 `CCSupport` 依赖的 iOS 15–16 越狱插件：将**控制中心原版计算器按钮**直接重定向到任意第三方计算器 App（如 Solves、PCalc 等）或自定义 URL Scheme，同时保留苹果原版控制中心图标与布局。

## 功能特性

- **保留原版图标与零依赖**：直接 Hook `ControlCenterUIKit` 的 `CCUIAppLauncherModule` 与 `CCUIContentModuleContext`，不需要安装 `CCSupport`。
- **自带中文设置菜单**：在 **设置 → 控制中心计算器** 中通过 `AltList` 自由选择已安装的目标 App，支持搜索 Bundle ID。
- **即时生效**：开启、关闭、切换目标 App 通过 Darwin Notification 实时同步到 SpringBoard，无需反复注销桌面。
- **自定义 URL Scheme（可选）**：支持跳转到快捷指令（`shortcuts://run-shortcut?name=...`）或任意 URL Scheme。
- **长按菜单接管（可选）**：支持连带接管长按预览对应的目标应用，且带安全回退（目标 App 被卸载时自动回退系统计算器）。
- **原生双架构支持**：同时编译原生 `RootHide (iphoneos-arm64e)` 与 `Rootless (iphoneos-arm64)` `.deb` 包。

## 环境要求

- iOS 15.0 – 16.x（Dopamine RootHide / Dopamine Rootless）
- `ellekit` / `MobileSubstrate`
- `preferenceloader`
- `com.opa334.altlist` (`AltList`)

## 使用方法

1. 从 [Releases](https://github.com/siri666666/CCCalcRedirect/releases) 下载对应越狱架构（`roothide` 或 `rootless`）的 `.deb` 并用 Sileo / Filza 安装。
2. 首次安装后 Respring 注销一次。
3. 打开 **设置 → 控制中心计算器 → 选择目标 App**，挑好你的第三方计算器（可点「测试打开目标 App」验证），即可在控制中心直接点击原版计算器图标秒开。

## 编译构建

项目已配置 GitHub Actions 自动编译 RootHide 与 Rootless 包。如需在 macOS 本地编译（需配置 `roothide/theos` 与 `iPhoneOS16.5.sdk`）：

```bash
# RootHide (iphoneos-arm64e)
make package FINALPACKAGE=1 DEBUG=0 THEOS_PACKAGE_SCHEME=roothide

# Rootless (iphoneos-arm64)
make package FINALPACKAGE=1 DEBUG=0 THEOS_PACKAGE_SCHEME=rootless
```

## 开源协议与致谢

- 本项目基于 [MIT License](LICENSE) 开源。
- 使用了 [opa334/AltList](https://github.com/opa334/AltList) 与 [roothide/theos](https://github.com/roothide/theos)。
