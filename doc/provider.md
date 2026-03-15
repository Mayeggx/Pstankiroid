# Pstankidroid 交接文档

## 1. 当前目标

本轮开发的目标是把 `doc/introduction.md` 中描述的 Python 项目 `PicSubToAnki` 的核心流程，迁移为安卓端 Demo：

- 在 App 内配置原来 `config.ini` 的参数
- 选择单张或多张字幕截图
- 逐张填写目标词
- 调用兼容 OpenAI 的接口生成词条信息
- 将结果写入 AnkiDroid
- 支持按词查重后更新，而不是只做新增

当前实现已经完成一个可运行的端到端基础版本。

## 2. 已完成内容

### 2.1 UI 与页面流

已将原来的测试型 Demo 改为可操作的业务流界面：

- 首页状态卡显示：
  - AnkiDroid 是否安装
  - Provider 是否可用
  - 数据库权限是否已授予
  - 当前状态消息
- 操作按钮：
  - `刷新`
  - `授权`
  - `查询`
  - `单张`
  - `批量`
  - `制卡`
- 支持弹出“设置”对话框，编辑所有原 `config.ini` 中的重要配置项

对应文件：

- `app/src/main/java/com/mayegg/pstanki/MainActivity.kt`
- `app/src/main/java/com/mayegg/pstanki/MainViewModel.kt`
- `app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt`

### 2.2 配置替代 config.ini

已将 Python 项目中的 `config.ini` 改为安卓内置可编辑配置，使用 `SharedPreferences` 存储。

当前可配置项包括：

- OpenAI 相关
  - `apiKey`
  - `baseUrl`
  - `modelName`
- Anki 相关
  - `jpDeck`
  - `enDeck`
  - `ankiModelName`
  - `wordField`
  - `pronunciationField`
  - `meaningField`
  - `noteField`
  - `exampleField`
  - `voiceField`
- 图片压缩相关
  - `maxWidth`
  - `maxHeight`
  - `imageQuality`

### 2.3 文件选择与草稿列表

已支持：

- 选单张图片
- 选多张图片
- 将文件名去掉扩展名后作为字幕 `subtitle`
- 为每张图片单独填写目标词

当前草稿结构：

- 图片 Uri
- 显示名称
- 字幕文本
- 目标词
- 处理状态

### 2.4 LLM 调用

已实现兼容 OpenAI 的 `/chat/completions` 请求。

当前逻辑：

- 从设置页读取 `apiKey`、`baseUrl`、`modelName`
- 发送批量请求
- Prompt 中要求模型返回 JSON 数组
- 每项字段包含：
  - `单词`
  - `音标`
  - `意义`
  - `例句`
  - `笔记`
- 自动兼容 markdown 代码块包裹的 JSON

当前实现位置：

- `app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt`

### 2.5 模式判断

已按原文档保留自动模式判断：

- 若目标词首字符编码值大于 `10000`，按日语模式处理
- 否则按英语模式处理

模式当前影响：

- 写入的牌组
- 发音链接生成方式

### 2.6 AnkiDroid 写入

当前改为使用安卓端 `AnkiDroid provider API`，不再依赖桌面版 `AnkiConnect`。

已实现：

- 查询牌组与模板
- 若牌组不存在则自动创建
- 根据模板字段顺序构造 `flds`
- 通过内容提供者插入 note
- 通过媒体 provider 导入压缩后的图片
- 通过搜索查询现有 note，命中后更新字段

已实现的更新逻辑：

- `意义` 追加
- `笔记` 追加
- `例句` 追加，并带新图片
- `单词` / `音标` / `发音` 更新为最新值

### 2.7 图片压缩与导入

已实现：

- 将选中图片读入内存
- 压缩到配置的最大宽高
- 转 JPG
- 使用 `FileProvider` 暴露临时文件
- 调用 AnkiDroid 的 `media` provider 导入媒体
- 返回 `<img src="...">` 写入例句字段

对应清单改动：

- 添加 `INTERNET`
- 添加 `FileProvider`

相关文件：

- `app/src/main/AndroidManifest.xml`
- `app/src/main/res/xml/file_paths.xml`

## 3. 已验证结果

### 3.1 编译

已验证以下命令通过：

```powershell
. .\scripts\use-e-drive-android-env.ps1
./gradlew.bat assembleDebug --console=plain --no-daemon
```

结果：

- `BUILD SUCCESSFUL`

### 3.2 ADB 安装与启动

已完成实际设备联调：

- 检测到在线设备：
  - `ce12182c78ce3c32027e device`
- 安装成功：
  - `adb install -r app\build\outputs\apk\debug\app-debug.apk`
- 启动成功：
  - `adb shell am start -n com.mayegg.pstanki/.MainActivity`
- 进程存在：
  - `pidof com.mayegg.pstanki -> 12630`

### 3.3 启动日志

已抓取启动阶段日志。

结论：

- 没有看到 `AndroidRuntime` 崩溃
- App 可以正常启动到前台
- 当前前台一度切到系统文档选择器 `com.android.documentsui/.picker.PickActivity`
- 说明目前主要卡在用户交互阶段，而不是启动崩溃

### 3.4 Provider 问题已解决

最初联调时，页面显示：

- `installed = true`
- 其他状态基本正常
- 但 `providerAvailable = false`

经过 ADB 排查后确认：

- 设备上的 AnkiDroid 实际 provider authority 是：
  - `com.ichi2.anki.flashcards`
- 不是早期代码里写的：
  - `com.ichi2.anki.api.provider`

随后已完成两步修复：

1. 将 provider authority 改为：
   - `com.ichi2.anki.flashcards`
2. 将 provider 可用性检测从单一的：
   - `resolveContentProvider(...)`
   扩展为双重检测：
   - `resolveContentProvider(...)`
   - `acquireUnstableContentProviderClient(...)`

原因是：

- 设备上 provider 实际存在
- 但某些环境下单靠 `resolveContentProvider(...)` 可能误判为不可用

修复后，用户已确认：

- `providerAvailable` 已恢复正常
- 当前这一问题已关闭

## 4. 当前实现与原 Python 项目的差异

虽然功能方向一致，但当前安卓实现并不等同于桌面 Python 项目的全部能力。

### 4.1 通信方式不同

Python 版：

- 用桌面 Anki 的 `AnkiConnect`
- 通过 `http://localhost:8765`

安卓版当前：

- 用 `AnkiDroid provider API`
- 直接读写手机上的 AnkiDroid

这意味着：

- 不再需要桌面 AnkiConnect
- 但字段、模板、牌组必须与手机端 AnkiDroid 内已有结构匹配

### 4.2 Prompt 还不是 Python 版完整复刻

目前 prompt 是一个合并后的简化版，已经能要求模型输出结构化 JSON，但还没有逐字复刻 Python 版中：

- 日语单条 prompt
- 英语单条 prompt
- 日语批量 prompt
- 英语批量 prompt

如果后续要提高输出稳定性，建议把 Python 版的 prompt 语义更完整地迁移过来。

### 4.3 目前只做了批量路径

当前 LLM 调用内部统一走批量处理，即使只有一张图也按一项批量走。

这不影响功能，但与 Python 版的：

- `explain_single`
- `explain_batch`

的结构还不完全一致。

### 4.4 查重逻辑是近似实现

Python 版通过 `findNotes + notesInfo + 字段核对` 实现较细的查重。

安卓版当前采用：

- provider 查询
- 基于字段搜索条件匹配

这在多数场景可用，但复杂模板、特殊搜索语法或 provider 行为差异下，可能需要再强化。

### 4.5 Provider 兼容性依赖真实设备版本

本项目当前已按真机上的 AnkiDroid authority 实现：

- `com.ichi2.anki.flashcards`

不要再回退为：

- `com.ichi2.anki.api.provider`

如果后续换设备或换 AnkiDroid 版本，优先用 ADB 再确认一次设备上实际暴露的 authority。

## 5. 已知风险与待验证点

### 5.1 模板字段列名

当前代码假设在 `models` provider 中能正确拿到模板字段顺序 `flds`，并与用户配置的字段名一致。

风险：

- 如果设备上模板名存在，但字段名不一致
- 或 provider 返回列结构与预期不同

则可能导致：

- 插卡失败
- 更新错字段

优先验证项：

- 手机上实际使用的模板是否为 `划词助手Antimoon模板`
- 字段名是否与设置页完全一致

### 5.2 LLM 返回格式脆弱性

当前仍依赖模型返回严格 JSON。

风险：

- 若模型返回自然语言说明
- 或字段名不是 `单词/音标/意义/例句/笔记`

则解析会失败

可改进方向：

- 更强的 JSON 截取
- 字段别名兼容
- 对单项失败做更明确的 UI 提示

### 5.3 图片读取 API

当前图片解码使用普通位图读取方案，适合 Demo，但大图时存在内存压力。

可改进方向：

- 改为按采样率解码
- 使用 `ImageDecoder` 或流式缩放

### 5.4 ADB 联调尚未覆盖“制卡成功”

已完成：

- 安装
- 启动
- 前台切换
- provider 不可用问题定位与修复

尚未完成：

- 实际填写设置
- 选择图片
- 点击制卡
- 验证 AnkiDroid 中 note 成功新增/更新

这是下一轮最优先事项。

## 6. 建议的下一步

建议按下面顺序继续联调。

### 第一步：验证权限、Provider 与查询

在手机上：

1. 打开 App
2. 点击 `授权`
3. 点击 `查询`

期望：

- 状态中能看到已授权
- `providerAvailable = true`
- 能读取牌组和模板数量

如果失败：

- 抓 logcat
- 重点看 provider 权限或列名问题

### 第二步：验证模板字段

在手机 AnkiDroid 中确认：

- 模板名称
- 字段名称

然后在 App 设置页中逐项对齐：

- `ankiModelName`
- `wordField`
- `pronunciationField`
- `meaningField`
- `noteField`
- `exampleField`
- `voiceField`

### 第三步：验证单次制卡

建议先只选一张图，填一个目标词，验证：

- LLM 返回 JSON 正常
- 图片能成功导入 Anki 媒体
- Note 能成功插入

### 第四步：验证重复更新

对同一个词再次制卡，观察：

- 是否命中已有 note
- 是否正确追加 `例句/笔记/意义`

## 7. 关键文件清单

### 核心业务代码

- `app/src/main/java/com/mayegg/pstanki/MainActivity.kt`
- `app/src/main/java/com/mayegg/pstanki/MainViewModel.kt`
- `app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt`
- `app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt`

其中本轮与 provider 修复直接相关的是：

- `app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt`

### 配置与清单

- `app/src/main/AndroidManifest.xml`
- `app/src/main/res/xml/file_paths.xml`

### 参考文档

- `doc/introduction.md`
- `doc/anki-connect-api.md`
- `doc/adb联调说明.md`

## 8. 交接结论

当前项目已经从“测试型 Pstankidroid”推进到“可配置、可选图、可调用 LLM、可写入 AnkiDroid”的业务型 Demo。

目前最关键的剩余工作不是重构，而是继续联调验证：

- 手机上实际模板字段是否匹配
- LLM 返回是否稳定
- 制卡链路是否能完整走通
- 重复更新是否符合预期

需要特别记住的已解决问题：

- `providerAvailable = false` 的根因不是设置页
- 根因是 provider authority 和检测方式
- 当前正确实现已经修复，不要再改回旧值

下一位接手的人，优先从真机点击“授权 -> 查询 -> 选图 -> 制卡”开始，不要先做大规模代码重写。
