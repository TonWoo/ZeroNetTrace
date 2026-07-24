# 《零网寻踪》阶段 1 MVP

Godot 4.7.1 Standard + GDScript 制作的 Windows 原生桌面探案恐怖游戏。当前版本包含序章《一封死人的邮件》、01《凌晨两点的门禁》和 02《死者在线》，新档可连续通关三段内容。

## 打开与运行

1. 安装 Godot 4.7.1 Standard（非 Mono），或使用工程内本地工具目录 `.tools/godot-4.7.1/`。
2. 在 Godot Project Manager 中导入本目录的 `project.godot`。
3. 等待字体与 shader 首次导入完成，按 F5 运行主场景。F11 可切换独占全屏与窗口模式。

命令行运行：

```powershell
.\.tools\godot-4.7.1\Godot_v4.7.1-stable_win64_console.exe --path .
```

## 游戏操作

- 任务栏可打开终端、浏览器、邮件、通讯器、查看器、笔记本和结案报告。
- 窗口支持拖动、缩放、最小化、最大化和左右吸附。
- 输入 `help` 可查看分组命令索引，输入 `help <命令>` 可查看用途、语法、使用时机和不含案件答案的通用示例；未知命令会给出相近拼写建议，缺少参数会直接返回正确语法。
- 终端命令包括 `scan`、`probe <地址>`、`crack <地址>`、`login <地址> -u <用户> -p <密码>`、`ls`、`cd`、`cat`、`open`、`get`、`trace`、`note`、`disconnect`、`help` 和 `tutorial`。
- `crack` 在后台异步推进；反向追踪出现中继提示后，可用 `trace <中继>` 降压。终端失焦时追踪速度降至 25%；达到 100% 会断线、破解归零、锁定节点 20 秒并增加污点。
- 浏览器接受任意文本或虚构地址。知识门按关键词、别名与上下文命中，关键搜索词和密码需要从全文材料中自行推导。
- 查看器支持图片缩放、47 格视频逐格检查和截图钉入笔记。02 的唯一 C 级事件绑定第 39 格。

## 沉浸式序章教学

- 序章不显示固定任务面板、步骤编号、箭头或答案高亮。方向来自林薇邮件、附件错误页、终端诊断、恢复便签和通讯器消息。
- 玩家首次完成正确方向的动作时，对应应用窗口会短暂进行两次低亮边框脉冲，并播放独立于恐怖 sting 的短双音；错误方向不播放进度反馈，重复动作也不会反复闪烁。
- 输入 `help tutorial` 可读取当前最近一条剧情内操作备忘，不显示答案或完成清单。
- 输入 `tutorial skip` 可关闭序章教学消息与进度反馈；输入 `tutorial restart` 会按当前案件状态重新同步，不回滚节点、证据、搜索门、污点或结案进度。
- 逐步教学仅覆盖序章。进入 01 和 02 后仍可使用全局 `help`、命令错误恢复和原有 6/12/18 分钟三级提示。

## 工程结构

- `scenes/os/`：桌面外壳主场景。
- `scenes/apps/`：终端、浏览器、邮件、通讯器、查看器、笔记本、结案报告。
- `scenes/sites/`：具有独立 Theme 和年代感身份的虚构网站。
- `scripts/engine/`：数据仓库、案件运行时、存档、事件、音频、恐怖调度与命令解析。
- `data/cases/`：严格 JSON 案件数据；剧情、节点、文件系统、知识门、答案和恐怖事件均由数据驱动。
- `assets/`：字体、CRT shader、美术清单及正式资产投放目录。
- `tests/`：无界面单元、集成和场景测试。

六个 Autoload 服务为 `DataRepository`、`CaseRuntime`、`SaveService`、`EventBus`、`AudioDirector`、`HorrorDirector`。App 只提交玩家动作并渲染状态，不写死案件流程。

## 剧情解锁与内容生成

邮件、聊天和其他可读条目使用 JSON `unlockWhen` 条件按调查进度解锁，支持 `start`、`site`、`gate`、`evidence`、`horror`、`report_complete`、`all` 和 `any`。开局不会提前显示密码、棚区、第 39 格或结案答案。

`tools/generate_content.py` 是序章、01、02 运行 JSON 与美术清单的可重复成文源。修改生成器后运行：

```powershell
python .\tools\generate_content.py
```

## 美术与声音

- 阶段 1 默认显示深灰资产占位框。完整资产 ID、用途、尺寸和英文 Prompt 见 `assets/art_manifest.md`。
- 正式 PNG 放入 `assets/art/<资产ID>.png`，Godot 完成导入后，查看器会自动按 `assetId` 加载，无需改剧情数据。
- 正文使用 Noto Sans SC，终端使用 Sarasa Mono SC；许可证位于 `assets/fonts/`。
- 当前声音由 `AudioStreamGenerator` 生成，包括低频嗡鸣、键击脉冲、硬盘寻道、非恐怖进度双音、恐怖 sting 与 sting 后静默。进度双音会在恐怖静默结束后排队播放。正式素材和最终混音属于阶段 3。

## 存档

单档自动存档写入 `user://save.json`，同目录保留 `.bak`。当前 `schemaVersion = 2`，保存内容包括当前案件、已发现/探测/认证节点、证据、阅读状态、知识门、提示计时与等级、笔记、截图、恐怖事件、恐怖强度、主题、CRT、污点、结案首答、各关评级和教程步骤/消息/定时提示状态。schema v1 旧存档仍可读取，教程会根据已有知识门、认证节点、已读文件、证据和报告答案重建可确认的进度。写入采用临时文件替换，损坏文件会保留备份。

## 自动测试

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\test.ps1
```

当前测试包含 768 项断言，并额外执行窗口状态、恐怖关闭档和主场景无头烟雾测试。覆盖严格 JSON、内容厚度、终端解析、`help` 与错误恢复、教程状态机、九步真实序章流程、窗口反馈、进度音排队、schema v2 恢复、路径与补全、破解状态机、反向追踪、搜索别名、三级提示、剧情解锁、恐怖幂等、结案评级、站点身份、查看器第 39 格事件，以及 10 个 GPT Image 2 提示词的结构、文字、空间连续性和清单可复制格式。脚本还会检查根工程扫描没有嵌套 Godot 项目警告；导出探针位于 `.tools/export_probe/`。

## Windows 导出

安装 Godot 4.7.1 官方 Export Templates 后运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\export_windows.ps1
```

脚本先运行完整测试，再导出 Windows x86_64，并验证 PCK 包含运行资源且排除 QA 产物。输出为 `builds/windows/ZeroNetTrace.exe` 与 `builds/windows/ZeroNetTrace.pck`。

阶段 1 的详细交付、内容数量、构建哈希和隔离启动记录见 `STAGE1_REPORT.md`。
