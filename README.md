# Pstankidroid

Pstankidroid 是一个 Android 词卡辅助应用。它会从图片中整理待处理内容，调用兼容 OpenAI 的 LLM 接口生成词条信息，并把结果写入 AnkiDroid。

## 功能概览

- Kotlin + Jetpack Compose 单应用模块项目
- 支持选择单张图片或整个文件夹批量导入
- 支持 `auto`、`jp`、`en` 三种 prompt 模式
- 调用 `/chat/completions` 生成单词、音标、释义、例句、备注
- 通过 AnkiDroid `ContentProvider` 查询牌组和模型
- 支持 note 新增、查重、命中后更新
- 支持图片压缩后导入 AnkiDroid 媒体库
- 内置状态查看、日志查看和配置编辑

## 项目信息

- 应用名：`Pstankidroid`
- 包名：`com.mayegg.pstanki`
- `minSdk`：`26`
- `targetSdk`：`34`
- `compileSdk`：`35`
- JDK：`17`

## 目录说明

- `app/src/main/java/com/mayegg/pstanki`
  核心业务代码。
- `app/src/main/assets/prompts`
  LLM prompt 模板。
- `scripts`
  构建、ADB 调试、环境初始化脚本。
- `doc`
  调试记录、provider 说明和交接文档。

## 核心文件

- [MainActivity.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainActivity.kt)
- [MainViewModel.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainViewModel.kt)
- [AnkiDroidClient.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt)
- [ConfigRepository.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt)

## 环境准备

项目当前依赖本地 `E:` 盘的 Android 和 Java 环境。可直接使用脚本设置环境变量：

```powershell
. .\scripts\use-e-drive-android-env.ps1
```

脚本会设置：

- `JAVA_HOME=E:\Development\jdk17`
- `ANDROID_HOME=E:\Android\Sdk`
- `ANDROID_SDK_ROOT=E:\Android\Sdk`
- `ANDROID_USER_HOME=E:\Android\UserHome`
- `GRADLE_USER_HOME=E:\Gradle\user-home`

## 构建

```powershell
. .\scripts\use-e-drive-android-env.ps1
.\gradlew.bat assembleDebug --console=plain --no-daemon
```

构建输出：

- `app\build\outputs\apk\debug\app-debug.apk`

## ADB 调试

安装并启动应用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-adb-debug.ps1 -InstallApk -LaunchApp
```

仅构建：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\build-debug.ps1
```

## 应用内配置

应用内需要配置以下内容后才能正常制卡：

- LLM 接口地址
- API Key
- 模型名
- 日语牌组和英语牌组
- Anki 模型名
- 各字段名
- 图片压缩参数

这些配置由 [ConfigRepository.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt) 持久化保存。

## 当前限制

- `清空列表` 会尝试删除当前文件夹下的图片，缺少二次确认。
- 对 LLM 输出格式有依赖，返回非预期 JSON 时会失败。
- AnkiDroid 侧的模型名和字段名必须与应用配置一致。
- 目前没有自动化测试。

## 相关文档

- [handoff.md](/E:/Mega/Pstankiroid/handoff.md)
- [doc/provider.md](/E:/Mega/Pstankiroid/doc/provider.md)
- [doc/adb联调说明.md](/E:/Mega/Pstankiroid/doc/adb联调说明.md)
