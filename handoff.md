# Pstankidroid Handoff

## 当前状态

- 路径：`E:\Mega\Pstankiroid`
- 包名：`com.mayegg.pstanki`
- 技术栈：Android + Kotlin + Jetpack Compose
- 目标：从截图批量制卡，调用 LLM 生成词条内容，并写入 AnkiDroid

核心文件：
- [MainActivity.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainActivity.kt)
- [MainViewModel.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/MainViewModel.kt)
- [AnkiDroidClient.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt)
- [ConfigRepository.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/ConfigRepository.kt)

## 近期完成

### LLM / Prompt

- prompt 已拆到 assets 文件中读取：
  - [batch_jp.txt](/E:/Mega/Pstankiroid/app/src/main/assets/prompts/batch_jp.txt)
  - [batch_en.txt](/E:/Mega/Pstankiroid/app/src/main/assets/prompts/batch_en.txt)
- prompt 模式支持：
  - `auto`
  - `jp`
  - `en`
- `auto` 模式参考 `PicSubToAnki`，按第一张卡片目标词首字符判断
- 整批只发一次请求，不按语言拆分请求
- prompt 已补上示例输入 / 示例 JSON 输出

### 去重与更新

- 已补强去重逻辑，参考 `PicSubToAnki`
- 添加单词前会先查重
- 命中已有 note 时更新，不再直接新增
- 当前实现位于 [AnkiDroidClient.kt](/E:/Mega/Pstankiroid/app/src/main/java/com/mayegg/pstanki/AnkiDroidClient.kt)

### 界面

- 顶部保留：`状态`、prompt 模式下拉、`日志`、`设置`
- prompt 模式切换已改成顶部下拉，不再是按钮组
- `刷新状态 / 申请权限 / 查询牌组` 已移到状态弹窗
- 已取消“全部制卡”
- `清空列表` 现在不仅清空 UI，还会删除当前文件夹下的图片
- 状态弹窗会显示当前选择的文件夹

## 当前界面行为

- 选择文件夹后：
  - 记录当前文件夹 URI 和显示名
  - 递归扫描图片
  - 加入草稿列表
- 批量制卡只处理勾选项
- 单条制卡仍可逐项执行
- 清空列表会删除当前文件夹内识别到的图片文件

注意：
- `清空列表` 现在有真实删除行为，存在误删风险
- 目前还没有二次确认弹窗

## AnkiDroid 侧

- 使用 `ContentProvider` 方式写入，不是桌面版 `AnkiConnect`
- 当前 authority 使用：
  - `com.ichi2.anki.flashcards`
- 已验证 provider 可用性检测和基础写入链路

## 构建与 ADB

构建命令：

```powershell
. .\scripts\use-e-drive-android-env.ps1
./gradlew.bat assembleDebug --console=plain --no-daemon
```

ADB 调试命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-adb-debug.ps1 -InstallApk -LaunchApp
```

最近状态：
- 构建通过
- 设备在线：`SM-T830`
- 应用已成功安装并启动
- 前台 Activity 已确认是 `com.mayegg.pstanki/.MainActivity`

日志文件：
- [adb-logcat-latest.txt](/E:/Mega/Pstankiroid/logs/adb-logcat-latest.txt)

## 下一步建议

优先验证这几项：

1. 状态弹窗里的三个按钮是否都可用
2. 顶部 prompt 模式下拉是否生效
3. 同一单词重复制卡时是否变成更新而不是新增
4. `清空列表` 是否真的删除当前文件夹图片，是否需要补二次确认

## 参考资料

- [doc/anki-connect-api.md](/E:/Mega/Pstankiroid/doc/anki-connect-api.md)
- [doc/provider.md](/E:/Mega/Pstankiroid/doc/provider.md)
- [PicSubToAnki/anki_connect.py](/E:/Mega/PicSubToAnki/anki_connect.py)
