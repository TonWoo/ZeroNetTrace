# 《零网寻踪》网站设计参考登记规范

## 强制流程

每次新增或重做一个虚构网站，必须先完成参考登记，再创建 Godot 页面场景：

1. 打开 [getdesign.md](https://getdesign.md/) 网站目录；
2. 选择一个与网站身份、年代、内容密度和剧情情绪匹配的主参考；
3. 创建 `docs/design_references/<site_family>.md`；
4. 写明参考 URL、选择理由、采用特征、年代化调整、剧情化调整、禁止照搬项和页面结构草图；
5. 将相同参考信息写入 `Site.designReference`；
6. 页面通过构图审查后再编写 `.tscn` 与 GDScript；
7. 最终截图与参考并排检查层级和节奏，不复制真实商标、Logo、图片或原文。

一个网站只使用一个主参考。可以为单个交互细节记录次要观察来源，但主体构图、字号关系和信息密度必须服从主参考。

## 页面独立性

- 同一网站可以共享品牌色、字体比例、按钮和基础控件。
- 不同页面必须使用不同主体构图，不得只替换标题和正文数据。
- 不同网站不得共享同一个主体场景。
- 若两个网站在灰度截图中仍呈现相同的顶部高度、栏宽、标题位置和正文骨架，视觉验收判失败。
- 禁止通用的“顶部栏＋大标题＋圆角卡片列表”成为默认回退布局。

## 单站登记模板

```markdown
# <site_family> 设计参考

- 游戏网站：<虚构网站名称>
- 页面范围：<本网站包含的页面>
- 主参考：<getdesign.md 名称>
- 参考 URL：https://getdesign.md/<slug>/design-md
- 选择理由：<与机构身份、年代、内容和情绪的对应关系>

## 采用特征

- <明确的构图、层级、密度或排版关系>

## 年代化与剧情化调整

- <如何改造成游戏所需年代和叙事氛围>

## 禁止照搬

- <Logo、商标、图片、原文、营销区或其他不应复制内容>

## 页面构图

- <页面 ID>：<主体空间结构和主要交互>
```

正式登记文件不得保留尖括号占位内容。

## 阶段 1 批准映射

| `siteFamily` | 游戏网站 | 主参考 | 采用方向 |
|---|---|---|---|
| `discovered_sites` | 浏览器“已发现站点”首页 | [Raycast](https://getdesign.md/raycast/design-md) | 快速启动器结构、键盘感、紧凑导航 |
| `deadletter_mirror` | 零时邮局镜像 | [Nintendo 2001](https://getdesign.md/nintendo-2001/design-md) | Y2K 金属面板、早期网络层级、过时服务感 |
| `chenglan_campus` | 澄岚学院门户 | [IBM](https://getdesign.md/ibm/design-md) | 严格网格、官方蓝、信息系统密度 |
| `oldbbs_zero` | 旧网论坛 | [Dell 1996](https://getdesign.md/dell-1996/design-md) | 黑色页面框、色块栏目、Times 正文、旧网页质感 |
| `raven_live` | 渡鸦直播 | [Runway](https://getdesign.md/runwayml/design-md) | 深色媒体工作台、播放器主导、时间轴取证 |
| `changming_memorial` | 长明数字纪念馆 | [Notion](https://getdesign.md/notion/design-md) | 暖色留白、衬线标题、克制的服务叙事 |
| `changming_ops` | CM-OPS 工单系统 | [Sentry](https://getdesign.md/sentry/design-md) | 数据密集后台、异常状态层级、夜班监控感 |

每个 `siteFamily` 在进入页面实现任务前，必须补齐独立登记文件。
