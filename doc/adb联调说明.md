# Pstankidroid ADB 联调说明

## 当前状态

- APK 已成功编译：
  - `E:\Mega\Pstankiroid\app\build\outputs\apk\debug\app-debug.apk`
- `adb` 已可正常运行
- 本次检查时间：`2026-03-15`
- 当前设备状态：
  - `adb devices` 返回空列表
  - 说明当前没有已授权并在线的安卓设备

## 一、联调前准备

请先在安卓手机上完成以下设置：

1. 打开开发者选项
2. 开启 USB 调试
3. 用 USB 线连接电脑
4. 手机上弹出“是否允许 USB 调试”时，点击“允许”
5. 建议提前在手机中安装 AnkiDroid

如果你打算走无线调试，也可以先用 USB 完成一次配对。

## 二、进入项目目录

在 PowerShell 中进入：

```powershell
cd E:\Mega\Pstankiroid
```

加载项目环境：

```powershell
. .\scripts\use-e-drive-android-env.ps1
```

## 三、确认 adb 和设备连接

查看 adb 版本：

```powershell
adb version
```

查看设备列表：

```powershell
adb devices -l
```

正常情况下你应该能看到类似输出：

```text
List of devices attached
1234567890abcdef device usb:1-1 product:xxx model:xxx device:xxx transport_id:1
```

如果看到 `unauthorized`：

1. 看手机屏幕
2. 接受 USB 调试授权
3. 再执行一次：

```powershell
adb devices -l
```

如果设备列表为空：

1. 换一根支持数据传输的 USB 线
2. 换 USB 接口
3. 重新插拔设备
4. 手机上确认 USB 模式不是“仅充电”
5. 执行：

```powershell
adb kill-server
adb start-server
adb devices -l
```

## 四、安装 Demo APK

安装或覆盖安装：

```powershell
adb install -r .\app\build\outputs\apk\debug\app-debug.apk
```

如果安装成功，通常会看到：

```text
Success
```

## 五、启动 App

本项目包名：

- `com.mayegg.pstanki`

主 Activity：

- `com.mayegg.pstanki.MainActivity`

可直接启动：

```powershell
adb shell am start -n com.mayegg.pstanki/.MainActivity
```

## 六、联调时应该验证什么

打开 app 后，首页有四个按钮：

1. `Check AnkiDroid`
2. `Check Permission`
3. `Insert Test Note`
4. `Query Simple Data`

建议按这个顺序测试。

### 1. Check AnkiDroid

目标：

- 检查 AnkiDroid 是否安装
- 检查 provider 是否可用
- 检查权限状态

预期：

- 页面状态区会刷新安装状态、provider 状态和权限状态

### 2. Check Permission

目标：

- 触发 `READ_WRITE_DATABASE` 权限请求

预期：

- 如果系统/AnkiDroid 版本允许，状态会更新
- 如果没有弹窗或权限不生效，说明目标版本的权限模型可能与当前实现不一致，需要进一步看日志

### 3. Query Simple Data

目标：

- 读取 deck 和 model 摘要

预期：

- 页面会显示 deck 数量和 model 数量
- 如果失败，通常是 provider URI、列名或权限问题

### 4. Insert Test Note

目标：

- 直接插入一条测试 note
- 如果直接插入失败，则尝试跳转到 AnkiDroid 的 add-note 页面

预期：

- 成功时页面会显示插入成功信息
- 若 provider 插入返回 `null`，会打开 AnkiDroid 的 add-note 页面作为 fallback

## 七、抓日志的方法

先清空旧日志：

```powershell
adb logcat -c
```

启动实时日志：

```powershell
adb logcat
```

如果想缩小范围，可以先查应用进程：

```powershell
adb shell pidof com.mayegg.pstanki
```

或者先按关键词过滤：

```powershell
adb logcat | findstr Pstankidroid
```

如果要看崩溃，可重点关注：

```powershell
adb logcat | findstr "AndroidRuntime ActivityManager"
```

## 八、常用 adb 命令

查看已安装包：

```powershell
adb shell pm list packages | findstr pstanki
adb shell pm list packages | findstr com.ichi2.anki
```

卸载 demo：

```powershell
adb uninstall com.mayegg.pstanki
```

重新安装：

```powershell
adb install -r .\app\build\outputs\apk\debug\app-debug.apk
```

查看当前前台 Activity：

```powershell
adb shell dumpsys activity activities | findstr mResumedActivity
```

## 九、如果你要我继续帮你联调

你把手机连上并确保 `adb devices -l` 出现 `device` 状态后，我就可以继续执行：

1. 安装 APK
2. 启动 app
3. 检查 AnkiDroid 是否已安装
4. 抓日志定位运行时问题
5. 根据实际报错继续改代码
