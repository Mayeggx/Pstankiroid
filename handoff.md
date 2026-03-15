# Pstankidroid Handoff

## 项目概况

- 项目路径: `E:\Mega\Pstankiroid`
- 应用名称: `Pstankidroid`
- 包名: `com.mayegg.pstanki`
- 技术栈: Android + Kotlin + Jetpack Compose
- 目标: 从图片批量生成词卡内容，并写入 AnkiDroid

## 当前能力

- 选择单张图片或整个文件夹中的多张图片
- 递归扫描图片并生成待处理草稿列表
- 支持 `auto`、`jp`、`en` 三种 prompt 模式
- 调用兼容 OpenAI 的 `/chat/completions` 接口生成词条内容
- 通过 AnkiDroid `ContentProvider` 查询牌组、模型并插入或更新 note
- 导入图片到 AnkiDroid 媒体库，并写入 note 的 HTML 字段
- 同词重复制卡时优先更新已有 note，而不是直接新增
- 支持查看状态、LLM 日志和应用内配置

## 本轮已完成

- 设置界面改为三级入口结构:
  - `LLM 设置`
  - `Anki 设置`
  - `图片设置`
  - 用户先进入分类页，再编辑具体配置项
- 日志界面改为“每次 LLM 请求一栏”:
  - 列表页按一次请求分组展示
  - 点击某一栏后进入请求详情页，查看该次请求的完整日志
- 主界面图片卡片调整:
  - 文件名标题改为可选中文本对象，长按后使用 Android 系统原生文本选择菜单复制
  - 不再使用自定义“长按直接复制”逻辑
  - 缩略图从 `96.dp` 缩小到 `84.dp`
  - 卡片内边距、输入框和按钮 padding 略微缩小

## 核心文件

- [MainActivity.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainActivity.kt)
- [MainViewModel.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainViewModel.kt)
- [AnkiDroidClient.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt)
- [ConfigRepository.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt)
- [Theme.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ui/Theme.kt)

## 主要结构

- `MainActivity`
  - 负责 Compose UI、文件夹/图片选择、图片预览、状态/日志/设置弹窗
- `MainViewModel`
  - 负责页面状态、草稿列表、批量处理入口、状态刷新和配置保存
- `AnkiDroidClient`
  - 负责 AnkiDroid provider 访问、LLM 请求、prompt 拼装、图片压缩导入、note 新增/更新
- `ConfigRepository`
  - 负责将应用配置持久化到 `SharedPreferences`
- `AppLogger`
  - 负责应用内日志收集和展示

## 关键行为

- 选择文件夹后会递归扫描图片并填充草稿列表
- 批量制卡只处理当前勾选的草稿
- 单条制卡仍支持逐条执行
- `清空列表` 不只清空 UI，也会尝试删除当前所选文件夹中的图片文件
- 主界面文件名现在是 `SelectionContainer` 包裹的文本，可调用系统文本选择菜单

## 风险和注意事项

- `清空列表` 带真实删除行为，目前仍没有二次确认弹窗，存在误删风险
- LLM 返回依赖 JSON 结构，接口返回不稳定时，批处理会受影响
- AnkiDroid 的模型名、字段名、牌组名必须和应用设置一致，否则插入或更新会失败
- 当前写入依赖设备上的 AnkiDroid provider authority: `com.ichi2.anki.flashcards`
- 日志分组逻辑依赖 `AppLogger` 当前的 LLM 日志格式:
  - `Request`
  - `Response`
  - `HTTP ...`
  - `Request failed ...`
  - 如果后续日志格式变更，需要同步调整分组函数 `buildLogGroups`

## Prompt 与资源

- Prompt 文件位于:
  - [batch_jp.txt](/E:/Mega/Pstankiroid/app/src/main/assets/prompts/batch_jp.txt)
  - [batch_en.txt](/E:/Mega/Pstankiroid/app/src/main/assets/prompts/batch_en.txt)
- `auto` 模式会根据词首字符判断更偏向日语还是英语处理

## 构建与调试

构建命令:

```powershell
. .\scripts\use-e-drive-android-env.ps1
.\gradlew.bat assembleDebug --console=plain --no-daemon
```

ADB 调试命令:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-adb-debug.ps1 -InstallApk -LaunchApp
```

当前已验证:

- Debug 构建通过
- APK 已生成: `app\build\outputs\apk\debug\app-debug.apk`
- 已通过 ADB 安装并拉起应用
- 前台 Activity 已验证为 `com.mayegg.pstanki/.MainActivity`

## 建议优先验证

1. 主界面文件名长按后，是否能稳定弹出 Android 原生文本选择工具并复制
2. 设置界面三级入口在手机上是否足够清晰，是否需要增加分类说明或图标
3. 日志分组在成功请求、HTTP 错误和请求异常三种情况下是否都能正确分栏
4. `清空列表` 是否需要补二次确认，避免误删图片
5. 设备上的 Anki 模型和字段配置是否与应用设置完全一致

## 参考资料

- [README.md](/E:/Mega/Pstankiroid/README.md)
- [doc/provider.md](/E:/Mega/Pstankiroid/doc/provider.md)
- [doc/anki-connect-api.md](/E:/Mega/Pstankiroid/doc/anki-connect-api.md)
