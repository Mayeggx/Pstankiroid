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

- 修复日志详情关闭逻辑:
  - `日志 -> 请求详情 -> 关闭` 现在优先返回日志列表层，不再直接走整层退出
  - `LogDialog` 从 `AlertDialog` 改为自定义 `Dialog`，并显式接管返回键与关闭按钮行为
- 修复日志详情页返回闪退:
  - 根因是 `LogDialog` 详情列表在状态切换时读取了 `selectedGroup!!`，导致空指针崩溃
  - 现已改为使用稳定快照 `currentGroup` 渲染详情列表，移除强制非空断言
  - 将 `DialogProperties.dismissOnBackPress` 设为 `false`，统一由 `BackHandler` 处理返回链路
- 顶栏重新整理:
  - 顶部仅保留左侧 `已选` 与 `模式`
  - `状态 / 日志 / 设置 / 关于` 收拢进 `更多` 下拉菜单
  - `更多` 与操作项放在右侧，避免和左侧状态信息混排
- 列表统计文案调整:
  - 顶栏统计由 `列表` 改为 `已选`
  - 展示当前已勾选图片数量，而不是草稿总数
- 主界面与弹窗文案清理:
  - 修正了 `MainActivity.kt` 与 `MainViewModel.kt` 中一批乱码中文文案
  - 状态、设置、图片预览、关于等弹窗文案已恢复为正常中文
- 已完成本地构建与设备拉起验证:
  - `assembleDebug` 构建通过
  - 已通过 ADB 检测到在线设备 `SM-T830`
  - 应用前台 Activity 确认为 `com.mayegg.pstanki/.MainActivity`

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
- 应用图标已替换为自定义 adaptive icon，风格为“图片 + 卡片”
- 已完成 `v1.0.1` 发版:
  - `versionName = "1.0.1"`
  - `versionCode = 2`
  - git tag: `v1.0.1`
  - GitHub Release 已创建
  - Release 资产已上传 APK
- 已新增并完善自动化发布脚本:
  - [release.ps1](/E:/Mega/Pstankiroid/scripts/release.ps1)
  - [release.bat](/E:/Mega/Pstankiroid/scripts/release.bat)
- 主界面顶部和操作入口已调整:
  - 取消顶部左上角 `PicSubToAnki` 标题
  - 取消顶部独立的模式切换按钮
  - 新增顶部 `操作` 下拉菜单，包含:
    - `选择文件夹`
    - `全选`
    - `取消全选`
    - `批量制卡`
    - `清空列表`
  - 顶部新增 `关于` 按钮
  - `关于` 弹窗显示应用信息、版本和作者 `mayegg`
- 主界面模式入口已调整:
  - 主界面保留 `模式: auto/jp/en` 的可点击组件
  - 点击后可直接切换模式
  - 设置页里的 `Prompt 模式(auto/jp/en)` 输入仍然保留
- 已多次通过 ADB 重新安装和启动 Debug 包:
  - 使用过 `adb install -r`
  - 也验证过先 `adb uninstall com.mayegg.pstanki` 再重新安装
  - 设备上当前包信息确认存在:
    - `versionName=1.0.1`
    - `versionCode=2`
    - 一次卸载重装后的 `firstInstallTime/lastUpdateTime = 2026-03-15 22:58:45`

## 当前未解决问题

- 顶部状态栏布局仍需再次确认
  - 本轮已将 `已选/模式` 固定在左侧，其他入口收拢到 `更多`
  - 仍建议在真机上复测横屏、窄屏和字体放大场景，确认不会挤压

## 核心文件

- [MainActivity.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainActivity.kt)
- [MainViewModel.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainViewModel.kt)
- [AnkiDroidClient.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt)
- [ConfigRepository.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt)
- [Theme.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ui/Theme.kt)
- [release.ps1](/E:/Mega/Pstankiroid/scripts/release.ps1)

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
- `关于` 按钮会弹出应用信息窗口，显示作者 `mayegg`
- 主界面模式组件可以直接切换 `auto / jp / en`

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
- GitHub Release 页面即使只上传 APK，也仍会自动显示:
  - `Source code (zip)`
  - `Source code (tar.gz)`
  - 这是 GitHub 默认行为，不能通过当前脚本移除

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

自动发布命令:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\release.ps1 -VersionName 1.0.2 -CreateRelease
```

发布脚本当前行为:

- 自动更新 `app/build.gradle.kts` 中的 `versionName` 与 `versionCode`
- 默认执行 `assembleDebug`
- 生成重命名产物:
  - `release\Pstankidroid-v<version>.apk`
- 自动 commit / tag / push
- 可自动创建 GitHub Release 并上传 APK
- 支持自定义:
  - `-AppName`
  - `-ReleaseTitle`
  - `-ReleaseNotes`
  - `-Branch`
  - `-Repo`

当前已验证:

- Debug 构建通过
- APK 已生成: `app\build\outputs\apk\debug\app-debug.apk`
- 已通过 ADB 安装并拉起应用
- 前台 Activity 已验证为 `com.mayegg.pstanki/.MainActivity`
- 也验证过卸载后重新安装，设备包信息可正常读取
- `v1.0.1` tag 已推送
- `v1.0.1` GitHub Release 已创建并上传 APK
- 用户实机反馈:
  - 当前版本整体“大致没问题”
  - `日志 -> 日志详情 -> 关闭/返回手势` 退出与闪退问题已修复

## 建议优先验证

1. 主界面文件名长按后，是否能稳定弹出 Android 原生文本选择工具并复制
2. 设置界面三级入口在手机上是否足够清晰，是否需要增加分类说明或图标
3. 日志分组在成功请求、HTTP 错误和请求异常三种情况下是否都能正确分栏
4. `清空列表` 是否需要补二次确认，避免误删图片
5. 是否要把发布流程从 `debug APK` 切换为真正的 `release APK`

## 参考资料

- [README.md](/E:/Mega/Pstankiroid/README.md)
- [doc/provider.md](/E:/Mega/Pstankiroid/doc/provider.md)
- [doc/anki-connect-api.md](/E:/Mega/Pstankiroid/doc/anki-connect-api.md)

## 补充说明

- 本轮开发遇到过 Windows 命令长度限制问题。
- 直接用超长 `apply_patch` 或一次性 PowerShell 写整文件时，可能触发 `文件名或扩展名太长`。
- 如果后续还要做大段文本替换，优先使用较小的补丁，或分段写入文件，避免被平台限制阻塞。
