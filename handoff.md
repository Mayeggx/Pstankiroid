# Pstankidroid Handoff (精简)

## 项目概况

- 路径: `E:\Mega\Pstankiroid`
- 包名: `com.mayegg.pstanki`
- 技术栈: Android + Kotlin + Jetpack Compose
- 目标: 从图片批量生成词卡并写入 AnkiDroid

## 当前可用功能

- 选择单图/文件夹，递归扫描图片并生成草稿
- 支持 `auto / jp / en` 三种模式
- 调用兼容 OpenAI 的 `/chat/completions` 生成词卡内容
- 写入 AnkiDroid（查重后更新或新增）
- 支持状态、日志、设置、关于页面

## 本轮关键改动

- 列表项布局调整（每张图片一栏保持不变）：
  - 勾选框移动到“目标词输入框”所在行，并放在输入框左侧
  - 取消“字幕：xxx”小字展示
  - “状态”行改为仅展示简化状态词
- 状态流转标准化为 `wait / proceed / updated / created`
- 修改文件:
  - `app/src/main/java/com/mayegg/pstanki/MainActivity.kt`
  - `app/src/main/java/com/mayegg/pstanki/MainViewModel.kt`

## 最近验证结果

- `scripts/build-debug.ps1` 构建成功
- APK: `app/build/outputs/apk/debug/app-debug.apk`
- `scripts/start-adb-debug.ps1 -InstallApk -LaunchApp` 成功返回（脚本内已启动 adb daemon）
- 额外说明：当前终端会话中 `adb` 命令不在 PATH，未直接执行 `adb devices`

## 主要风险

- `清空列表` 会删除文件夹内图片，当前无二次确认
- Anki 写入依赖模型名/字段名/牌组名配置一致
- provider 依赖: `com.ichi2.anki.flashcards`

## 核心文件

- `app/src/main/java/com/mayegg/pstanki/MainActivity.kt`
- `app/src/main/java/com/mayegg/pstanki/MainViewModel.kt`
- `app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt`
- `app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt`
- `scripts/release.ps1`

## 常用命令

```powershell
. .\scripts\use-e-drive-android-env.ps1
.\gradlew.bat assembleDebug --console=plain --no-daemon
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-adb-debug.ps1 -InstallApk -LaunchApp
```

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release.ps1 -VersionName 1.0.2 -CreateRelease
```

## 建议下一步

1. 给 `清空列表` 增加二次确认
2. 真机复测横屏/窄屏/大字体下顶部布局
3. 评估是否切到正式 `release APK` 发布流程
