# 《零网寻踪》无搜索通关与独立网站重构设计

## 状态与优先级

- 状态：用户已于 2026-07-25 批准。
- 适用范围：序章、01《凌晨两点的门禁》、02《死者在线》，以及后续所有关卡的网站设计。
- 优先级：本规格覆盖旧文档中关于自由搜索、关键词别名、搜索噪音结果、搜索提示和“猜出长明”盲测的要求。
- 不变项：Godot 4 原生桌面、终端核心玩法、密码拼接、证据取回、三级提示、恐怖强度、第 39 格演出、结案报告和最终自首结局。

## 背景问题

阶段 1 玩家反馈集中在两个阻断点：

1. 自由搜索把主线推进隐藏在未公开的关键词组合里。玩家即使读过材料，也无法判断应该搜索、扫描、打开附件还是等待新消息。
2. 六个网站场景都由同一个 `SiteView` 生成，页面结构固定为身份条、标题、分隔线和长文本，只改变颜色与少量顶部文字。不同机构、年代与内容类型因此呈现相同轮廓。

本次重构不再通过增加答案提示修补搜索，而是取消搜索作为通关门槛，并把网站发现、页面构图和正确方向反馈重新定义为数据驱动系统。

## 目标

1. 玩家无需猜搜索词即可完成序章、01 和 02。
2. 玩家阅读关键材料后立即获得轻量、沉浸式的方向确认。
3. 浏览器仍是独立 App，但职责变为查看已经发现的虚构网站。
4. 每个网站开工前必须从 `getdesign.md` 选择一个主参考。
5. 同一网站保持品牌连续性，不同页面仍拥有独立主体构图。
6. 自动化测试可以在不调用 `submit_search()` 的情况下完整跑通阶段 1。

## 非目标

- 不删除浏览器 App。
- 不自动打开新发现的网站，不自动阅读页面，不自动整理案情。
- 不取消密码、凭证、文件路径、证据判断和结案题等知识门。
- 不在游戏运行时访问互联网或嵌入真实网页。
- 不复制 getdesign.md 参考品牌的 Logo、图片、商标或原文。
- 不在本次重构中补做 03～06 关内容。

## 玩家交互

### 浏览器外壳

浏览器保留返回、前进和只读地址栏。原搜索输入框与“检索”按钮删除。浏览器默认页改为“已发现站点”，每条记录显示：

- 网站名称与虚构地址；
- 发现来源，例如“来自：LW_最后一次校对.zlog.link”或“来自：数字资产托管协议”；
- 未读、已读或需要凭证状态；
- 与网站身份一致的小型标记，不使用统一卡片瀑布流。

新网站加入列表后不自动打开。玩家必须主动打开浏览器并点击记录，才能阅读内容并推进后续调查。

### 发现反馈

首次发现网站时同时触发：

1. 产生发现动作的当前窗口播放约 0.45 秒边框脉冲；
2. `AudioDirector.play_progress_soft()` 播放一次非恐怖短双音；
3. 浏览器任务栏图标出现未读点；
4. 通讯器投递一句剧情内反馈，例如“公开索引新增一条离线镜像记录”。

同一发现事件幂等。读档、重复打开材料和反复进入页面不会重播声音或重复消息。C 级演出和 sting 后静默期间，反馈延迟到喘息段。

### 玩家忽略入口时的提示

- 第一级：通讯器提示某个 App 出现新记录，不写网站名称。
- 第二级：浏览器图标再次低强度脉冲，提示“索引中仍有未读记录”。
- 第三级：说明具体操作“打开浏览器的已发现站点，核对最新记录”，但不解释网页证据结论。

## 阶段 1 流程调整

### 序章《一封死人的邮件》

九步教程保留，第三步从“自由搜索”改为“打开新发现的镜像站点”：

1. 阅读死者邮件；
2. 打开附件并看到 `MIRROR-17`；
3. 附件阅读完成后发现零时邮局镜像，玩家从浏览器打开；
4. 镜像页面说明只读缓存仍响应网络探测，玩家执行 `scan`；
5. `probe` 镜像节点；
6. `crack` 并处理反向追踪；
7. 进入文件系统；
8. 阅读原文并 `get` 证据；
9. 完成结案报告。

教程文本不再要求组合“零时邮局”和 `MIRROR-17` 作为搜索词。附件只负责证明镜像编号，镜像站点负责把调查交给终端。

### 01《凌晨两点的门禁》

- 阅读门禁相关邮件或附件后发现澄岚学院设备维护页和旧网论坛入口。
- 阅读设备维护页与论坛内容后，相关校园缓存页和网络节点按证据条件出现。
- 原 `kg_device_search` 与 `kg_lab_account` 中的搜索通道拆为站点发现条件；需要玩家拼接的账号、密码或凭证仍保留为 `KnowledgeGate`。
- 教程只确认新入口与有效终端动作，不显示固定任务清单。

### 02《死者在线》

- 渡鸦直播页作为案件入口已经可见。
- 取得并阅读《数字资产托管协议》后，发现长明数字纪念馆与旧网从业者爆料入口。
- 玩家亲自阅读爆料帖、回复、官网和合同，拼出员工凭证，进入 CM-OPS 工单系统。
- 原 `kg_search_changming` 改为合同阅读触发的站点发现，不再要求输入“长明”或别名。
- 第 39 格演出、工单证据、排班、身份池和结案题保持原逻辑。

## 数据契约

### Site

```json
{
  "id": "site_raven_live",
  "title": "渡鸦的直播间",
  "addresses": ["raven.zhibo-lan.cn"],
  "scene": "res://scenes/sites/raven/raven_channel_page.tscn",
  "siteFamily": "raven_live",
  "pageLayout": "channel_archive",
  "designReference": {
    "name": "Runway",
    "url": "https://getdesign.md/runwayml/design-md",
    "adopt": [
      "media-first hierarchy",
      "dark editing workspace",
      "timeline emphasis"
    ],
    "reject": [
      "brand logo",
      "modern AI gradients",
      "marketing CTA layout"
    ]
  }
}
```

`scene`、`siteFamily`、`pageLayout` 和 `designReference` 为必填字段。`skin` 只换颜色的旧契约退出运行数据。

### SiteDiscovery

```json
{
  "id": "discover_changming_from_contract",
  "completeWhen": {
    "type": "file_opened",
    "node": "10.24.7.115",
    "path": "/docs/合同扫描件.pdf"
  },
  "reveals": [
    "site_changming_official",
    "site_changming_leak"
  ],
  "sourceLabel": "数字资产托管协议",
  "feedback": {
    "appId": "viewer",
    "sound": "progress_soft",
    "pulse": "soft",
    "messageId": "msg_public_index_updated"
  }
}
```

支持的 `completeWhen.type` 包括 `mail_opened`、`attachment_opened`、`file_opened`、`evidence_collected`、`site_read`、`node_authenticated` 和 `gate_resolved`。每个发现可以开放一个或多个网站。

### 存档

存档 schema 升级为 v3，新增：

- `discoveredSites`；
- `readSites`；
- `siteDiscoverySources`；
- `consumedDiscoveryFeedback`；
- `unreadSiteIds`。

schema v2 迁移时，根据 `resolvedGates` 中已完成的旧搜索门补齐对应网站；已经读过的网站不重新标未读。迁移后保存为 v3，不删除旧字段，保留一个版本周期用于回滚诊断。

## 浏览器与运行架构

### CaseRuntime

- 新增 `observe_discovery_action(action_type, target, metadata)`；
- 新增 `discover_sites(discovery_id)`；
- 新增 `get_discovered_sites()` 与 `mark_site_read(site_id)`；
- 发出 `site_discovered(site_id, source_label)` 与 `site_unread_changed(site_id, unread)`；
- 移除阶段 1 对 `SearchService.matching_gates()` 和 `submit_search()` 的调用。

### BrowserApp

- 删除搜索框、搜索提交信号、搜索历史和噪音结果逻辑；
- 历史记录改为访问过的 `site_id`，返回/前进重新渲染已发现网站；
- 地址栏只显示当前虚构地址，不接受文本；
- 首页渲染 `CaseRuntime.get_discovered_sites()`；
- 页面场景只从 `Site.scene` 加载，不存在通用搜索皮肤回退。

### 页面场景

旧 `SiteView` 不再负责标题、身份条和正文拼装。共享层只允许提供：

- 字体与颜色令牌加载；
- 链接和页面动作事件；
- 通用滚动行为；
- 图片资产占位框；
- 可访问性字号和主题适配。

每个页面主体必须由独立场景和脚本组织。相同网站可以共享 `SiteFamilyTheme`，但不同 `pageLayout` 不得绑定同一个主体场景。

## getdesign.md 参考流程

每个网站开始设计前执行以下步骤：

1. 打开 `https://getdesign.md/` 网站目录；
2. 按机构身份、内容用途、信息密度、年代和情绪选择一个主参考；
3. 创建 `docs/design_references/<site_family>.md`；
4. 记录参考 URL、选择理由、采用特征、年代化调整、剧情化调整、禁止照搬项和页面结构草图；
5. 将相同信息写入关卡 JSON 的 `Site.designReference`；
6. 先完成页面构图测试，再编写 Godot 场景；
7. 视觉 QA 对照参考检查层级与节奏，同时检查没有复制商标、图片和原文。

使用单一主参考，避免把两个 DESIGN.md 混成缺乏身份的折中页面。需要补充某个交互细节时，可以记录次要观察来源，但不得改变主参考定义的视觉骨架。

## 阶段 1 已批准参考

| 游戏网站 | 主参考 | 采用方向 |
|---|---|---|
| 浏览器“已发现站点”首页 | [Raycast](https://getdesign.md/raycast/design-md) | 快速启动器结构、键盘感、紧凑导航 |
| 零时邮局镜像 | [Nintendo 2001](https://getdesign.md/nintendo-2001/design-md) | Y2K 金属面板、早期网络层级、过时服务感 |
| 澄岚学院门户 | [IBM](https://getdesign.md/ibm/design-md) | 严格网格、官方蓝、信息系统密度 |
| 旧网论坛 | [Dell 1996](https://getdesign.md/dell-1996/design-md) | 黑色页面框、色块栏目、Times 正文、旧网页质感 |
| 渡鸦直播 | [Runway](https://getdesign.md/runwayml/design-md) | 深色媒体工作台、播放器主导、时间轴取证 |
| 长明数字纪念馆 | [Notion](https://getdesign.md/notion/design-md) | 暖色留白、衬线标题、克制的服务叙事 |
| CM-OPS 工单系统 | [Sentry](https://getdesign.md/sentry/design-md) | 数据密集后台、异常状态层级、夜班监控感 |

## 内容与视觉约束

- 同一网站共享品牌色、字体比例和基础控件，不共享页面主体网格。
- 不同网站如果出现相同的顶部高度、侧栏宽度、标题位置和正文列宽组合，视觉 QA 判失败。
- 禁止用“顶部栏＋大标题＋圆角卡片列表”覆盖所有页面。
- 禁止把 getdesign.md 参考的现代营销区、价格 CTA、真实品牌名称或 Logo 搬入游戏。
- 所有页面必须适配 1280×720、1600×900 和 1920×1080；长内容必须能滚动且不遮挡浏览器导航。
- 图片继续遵守资产占位与 `assets/art_manifest.md` 规则。

## 内容校验

`ContentValidator` 新增以下失败条件：

- 任意 `KnowledgeGate.channel == "search"`；
- 任意运行数据包含 `defaultNoiseResults`、搜索别名或搜索提示；
- `Site.scene`、`siteFamily`、`pageLayout` 或 `designReference` 缺失；
- `designReference.url` 不属于 `https://getdesign.md/`；
- `adopt` 或 `reject` 为空；
- 两个不同 `siteFamily` 使用同一个主体场景；
- 一个网站的不同 `pageLayout` 没有显式布局映射；
- 教程步骤仍引用自由搜索或完整搜索词。

## 测试与验收

### 单元测试

- `SiteDiscovery` 只在满足证据条件后触发；
- 重复动作不会重复发现、发消息或播放反馈；
- 浏览器只列出已发现网站；
- 未发现或需要凭证的网站保持不可访问；
- 返回/前进只访问历史中的已发现页面；
- v2 存档迁移到 v3 后保留正确网站状态；
- 内容校验拒绝全部旧搜索字段与缺失设计参考的网站。

### 集成测试

- 序章通过“读邮件 → 开附件 → 打开镜像 → scan”推进；
- 01 通过阅读材料发现校园与论坛页面；
- 02 通过阅读合同发现长明与爆料入口；
- 阶段 1 全流程不调用 `submit_search()`；
- 每个首次正确方向动作产生边框、双音和未读标记；
- 第 39 格演出、结案题和存档恢复保持通过。

### 视觉 QA

- 为每个页面生成 1280×720、1600×900、1920×1080 截图；
- 对照对应 getdesign.md 参考检查视觉层级、密度和交互节奏；
- 将不同网站截图转为灰度轮廓，检查没有相同模板骨架；
- 检查网站内部品牌连续，同时确认不同页面主体构图独立；
- 检查中文长文本、逐帧查看器联动、未读状态和窗口缩放。

### 盲测通过条件

未读设计文档的玩家可以根据邮件、附件、终端文件、网页内容和 App 未读反馈完成序章、01 与 02；测试者不需要猜任何搜索词，仍需要亲自阅读证据、拼接凭证、使用终端并完成结案判断。02 的第 39 格按照恐怖强度设置触发对应演出。
