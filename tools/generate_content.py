from __future__ import annotations

import json
from datetime import datetime, timedelta
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CASE_DIR = ROOT / "data" / "cases"
ART_STYLE_SUFFIX = "muted colors, early-2000s Chinese internet aesthetic, slightly low-res, candid documentary realism, no futuristic neon"
HORROR_STYLE_SUFFIX = "muted colors, low-bitrate early-2000s Chinese internet video, slightly low-res, liminal documentary realism, no gore, no futuristic neon"
HORROR_ART_IDS = {"art_raven_stream_base", "art_frame39"}


def compose_art_prompt(
    *,
    purpose: str,
    composition: str,
    scene: str,
    readable_text: str,
    continuity: str,
    lighting: str,
    exclusions: str,
    output: str,
    horror: bool = False,
) -> str:
    style = HORROR_STYLE_SUFFIX if horror else ART_STYLE_SUFFIX
    return " ".join([
        f"Purpose and medium: {purpose}",
        f"Camera and composition: {composition}",
        f"Scene and required details: {scene}",
        f"Required readable text: {readable_text}",
        f"Continuity: {continuity}",
        f"Lighting and image defects: {lighting}",
        f"Do not include: {exclusions}",
        f"Output requirements: {output} Shared visual style: {style}.",
    ])


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def result(title: str, url: str, snippet: str) -> dict:
    return {"title": title, "url": url, "snippet": snippet}


def story_mail(subject: str, sender: str, time: str, body: str, signature: str, attachments: list[dict] | None = None, unlock_when: dict | None = None, mail_id: str | None = None) -> dict:
    mail = {
        "subject": subject,
        "from": sender,
        "time": time,
        "body": body,
        "signature": signature,
        "attachments": attachments or [],
    }
    if unlock_when is not None:
        mail["unlockWhen"] = unlock_when
    if mail_id is not None:
        mail["id"] = mail_id
    return mail


def flatten_chat(name_a: str, name_b: str, start: str, pairs: list[tuple[str, str]]) -> list[dict]:
    base = datetime.fromisoformat(start)
    messages: list[dict] = []
    for index, (a_text, b_text) in enumerate(pairs):
        at = base + timedelta(minutes=index * 2)
        messages.append({"from": name_a, "time": at.strftime("%H:%M"), "text": a_text})
        messages.append({"from": name_b, "time": (at + timedelta(minutes=1)).strftime("%H:%M"), "text": b_text})
    return messages


def stage_messages(messages: list[dict], stages: list[tuple[int, int, dict]]) -> list[dict]:
    for start, end, condition in stages:
        for index in range(start, end):
            messages[index]["unlockWhen"] = condition
    return messages


def log_lines(prefix: str, count: int, key_lines: dict[int, str]) -> str:
    lines = []
    base = datetime(2026, 7, 14, 0, 0, 0)
    for index in range(count):
        if index in key_lines:
            lines.append(key_lines[index])
            continue
        stamp = (base + timedelta(seconds=index * 37)).strftime("%Y-%m-%d %H:%M:%S")
        lines.append(f"{stamp} {prefix} seq={index:04d} actor=svc_{index % 7:02d} result=OK latency={18 + (index * 13) % 91}ms")
    return "\n".join(lines)


def common_noise() -> list[dict]:
    return [
        result("零网城市服务状态", "status.zero.local", "公共服务节点运行正常，过去二十四小时共处理 28,041,392 次请求。"),
        result("旧站归档索引更新公告", "archive-index.zero", "一批 2021—2023 年的个人主页镜像完成迁移，部分链接仍会失效。"),
        result("怎样整理数字遗物", "life.bbs.zero/thread/8831", "网友讨论账号继承、照片备份和纪念页管理，观点互相矛盾。"),
        result("夜间网络延迟统计", "netwatch.zero/reports/night", "凌晨两点至四点的平均延迟上升 7%，原因仍在排查。"),
        result("搜索帮助：缩短句子通常更有效", "help.zerosou.local/query", "尝试人物名、机构名、设备编号或材料中反复出现的短语。"),
    ]


def base_compliance() -> dict:
    return {
        "noRealExploit": "所有网络操作使用虚构地址、虚构锁层和不可迁移到现实环境的命令结果。",
        "crimeHasCost": "涉案人员与机构在后续案件中进入警方调查和司法程序。",
        "playerNotGlorified": "越界访问累计污点，并在最终自首情节中承担责任。",
        "horrorBounded": "无血腥猎奇，每关至多一次可降级或关闭的跳吓。",
        "allFictional": "人物、学校、平台、企业与城市系统均为架空设定。",
    }


def build_prologue() -> dict:
    last_log = """陈默：如果你读到这里，说明我已经没机会当面解释。官方会把那晚写成一次普通事故，他们甚至会拿我最近失眠、加班和情绪不稳作证。别跟他们争，也别急着证明我聪明；先把原始记录留下。零网的审核历史会改，人的记忆也会被更体面的说法改掉。你要找的不是某个神秘凶手，而是那些修改从哪里开始、又被谁批准。第一步，从我的账号开始查。不要相信自动汇总页，只看时间戳、原始文件和互相对不上的那一行。还有，看到 REN-0 时先别声张。它不是用户名，更像一把被很多人用过的钥匙。最后一件事：查完之后去找警方，把你的访问记录一起交出去。我们都越过线，但越过线不等于可以假装没有代价。——林薇，02:13"""
    delivery_log = log_lines("DEADLETTER", 24, {
        7: "2026-07-21 02:13:00 DEADLETTER schedule sender=linwei recipient=chenmo deliver_at=2026-07-24T03:17:00 rule=MIRROR-17",
        19: "2026-07-24 03:17:00 DEADLETTER delivered sender=linwei recipient=chenmo status=SIGNED_BY_DECEASED_ACCOUNT",
    })
    tutorial_messages = [
        {"id": "tut_mail_read", "sender": "ZERO-SHELL / LOCAL", "text": "原始邮件已展开并保留签名头。正文反复要求核对随信文件；附件仍在本地沙箱中，打开它不会向外部网络发送内容。"},
        {"id": "tut_attachment_opened", "sender": "林薇的离线签名盒", "text": "恢复片段 01：编号本身不是地址。把它和邮件里那个已经停运的服务放在一起核对，别让搜索引擎替你省略任何一半。"},
        {"id": "tut_search_resolved", "sender": "ZERO-SHELL / LOCAL MANUAL", "text": "缓存监测记录显示远端仍有响应。搜索能证明它存在，终端才能确认它现在暴露了什么。"},
        {"id": "tut_scan_complete", "sender": "ZERO-SHELL / DIAGNOSTIC", "text": "检测到一条只读镜像响应。当前防护状态未知；在启动任务前先识别访问模式和锁层。"},
        {"id": "tut_probe_complete", "sender": "林薇的离线签名盒", "text": "恢复片段 02：先看清锁是什么，再决定用钥匙还是让破解器慢慢磨。别把每扇门都当成同一种门。"},
        {"id": "tut_counter_ping", "sender": "林薇的离线签名盒", "text": "恢复片段 03：中继不是敌人，是你甩掉视线的出口。盯住终端刚刚报出的名字。"},
        {"id": "tut_filesystem", "sender": "ZERO-SHELL / RECOVERED NOTE", "text": "林薇：先看目录。文本要读原文，需要交给警方复核的文件再复制回本机。看过不等于取证。"},
        {"id": "tut_evidence", "sender": "林薇的离线签名盒", "text": "恢复片段 04：别只记结论，保留能让别人独立复核的原件。你的访问记录也一样，最后一起交出去。"},
        {"id": "tut_report_ready", "sender": "本地证据目录", "text": "封存条件已满足。结论必须逐项引用原始证据；证据不足的问题宁可暂不提交。"},
        {"id": "tut_complete", "sender": "林薇的离线签名盒", "text": "教学签名盒已封存。后面的案子不会再替你排列步骤；忘记工具时，ZERO-SHELL 的本地手册仍在。"},
    ]
    tutorial_nudges = [
        {"id": "tut_nudge_mail", "sender": "ZERO-SHELL / LOCAL", "text": "邮件列表里有一封主动留给你的信。先读她写下的原文，不要只看主题。"},
        {"id": "tut_nudge_attachment", "sender": "林薇的离线签名盒", "text": "恢复提示：她在正文里反复强调附件。损坏提示本身也可能保存了编号。"},
        {"id": "tut_nudge_search", "sender": "林薇的离线签名盒", "text": "恢复提示：旧服务名和缓存编号各自都不完整，把两段已知信息放进同一次检索。"},
        {"id": "tut_nudge_scan", "sender": "ZERO-SHELL / LOCAL MANUAL", "text": "网页缓存只能说明远端存在。要确认当前网络里有哪些节点，需要先做一次边界扫描。"},
        {"id": "tut_nudge_probe", "sender": "ZERO-SHELL / LOCAL MANUAL", "text": "看到地址不等于知道门锁。启动任务前先读取目标的访问模式与锁层。"},
        {"id": "tut_nudge_trace", "sender": "林薇的离线签名盒", "text": "恢复提示：破解器运行时别离开终端太久。出现 COUNTER-PING 后，记住它报出的中继名。"},
        {"id": "tut_nudge_files", "sender": "ZERO-SHELL / RECOVERED NOTE", "text": "节点已经放行。先列出目录，再决定哪些文件需要读原文。忘记语法就查本地手册。"},
        {"id": "tut_nudge_evidence", "sender": "林薇的离线签名盒", "text": "恢复提示：读过只能形成印象，复制原始文件才能形成可复核的证据。"},
        {"id": "tut_nudge_report", "sender": "本地证据目录", "text": "证据已经封存。结案入口在桌面任务栏；每个判断都要对应已经取得的原始文件。"},
    ]
    tutorial_steps = [
        {"id": "read_dead_mail", "completeWhen": {"type": "mail_opened", "target": "mail_deadletter_primary"}, "delivery": [{"channel": "terminal", "contentId": "tut_mail_read"}], "feedback": {"appId": "mail", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 75, "channel": "messenger", "contentId": "tut_nudge_mail"}, "helpText": "先读取死者留下的原始邮件正文，不要只看主题。"},
        {"id": "open_attachment", "completeWhen": {"type": "attachment_opened", "target": "attachment_deadletter_link"}, "delivery": [{"channel": "messenger", "contentId": "tut_attachment_opened"}], "feedback": {"appId": "viewer", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 75, "channel": "messenger", "contentId": "tut_nudge_attachment"}, "helpText": "邮件正文反复要求核对附件；先看错误页留下了什么。"},
        {"id": "resolve_mirror_search", "completeWhen": {"type": "gate_resolved", "target": "kg_mirror_search"}, "delivery": [{"channel": "terminal", "contentId": "tut_search_resolved"}], "feedback": {"appId": "browser", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 90, "channel": "messenger", "contentId": "tut_nudge_search"}, "helpText": "把邮件中的旧服务称呼与附件编号作为同一次检索的两部分。"},
        {"id": "scan_network", "completeWhen": {"type": "command_succeeded", "target": "scan"}, "delivery": [{"channel": "terminal", "contentId": "tut_scan_complete"}], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 60, "channel": "messenger", "contentId": "tut_nudge_scan"}, "helpText": "网页缓存只证明远端存在；用终端确认当前网络边界。"},
        {"id": "probe_mirror", "completeWhen": {"type": "command_succeeded", "target": "probe", "where": {"addr": "mirror17.deadletter.zero"}}, "delivery": [{"channel": "messenger", "contentId": "tut_probe_complete"}], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 60, "channel": "messenger", "contentId": "tut_nudge_probe"}, "helpText": "对新出现的节点先识别访问模式与锁层，再决定如何进入。"},
        {"id": "evade_counter_trace", "completeWhen": {"type": "counter_trace_reduced", "target": "relay.deadletter-17"}, "delivery": [{"channel": "messenger", "contentId": "tut_counter_ping"}], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 75, "channel": "messenger", "contentId": "tut_nudge_trace"}, "helpText": "破解器运行时留意 COUNTER-PING；终端报出的中继能帮助降低追踪压力。"},
        {"id": "enter_filesystem", "completeWhen": {"type": "node_authenticated", "target": "mirror17.deadletter.zero"}, "delivery": [{"channel": "terminal", "contentId": "tut_filesystem"}], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 60, "channel": "messenger", "contentId": "tut_nudge_files"}, "helpText": "节点放行后先列出目录；阅读原文和复制证据是两件事。"},
        {"id": "collect_linwei_log", "completeWhen": {"allOf": [{"type": "command_succeeded", "target": "ls"}, {"type": "file_opened", "target": "/archive/LW_最后一次校对.zlog"}, {"type": "evidence_collected", "target": "ev_linwei_log"}]}, "delivery": [{"channel": "messenger", "contentId": "tut_evidence"}, {"channel": "messenger", "contentId": "tut_report_ready"}], "feedback": {"appId": "terminal", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 90, "channel": "messenger", "contentId": "tut_nudge_evidence"}, "helpText": "先看目录，再读林薇留下的日志原文，最后把原文件复制进证据目录。"},
        {"id": "complete_report", "completeWhen": {"type": "report_complete", "target": "prologue_dead_mail"}, "delivery": [{"channel": "messenger", "contentId": "tut_complete"}], "feedback": {"appId": "report", "pulse": "soft", "sound": "progress_soft"}, "fallback": {"afterSec": 90, "channel": "messenger", "contentId": "tut_nudge_report"}, "helpText": "证据封存后，从桌面任务栏打开结案报告并逐项引用原始文件。"},
    ]
    return {
        "caseId": "prologue_dead_mail",
        "title": "序章：一封死人的邮件",
        "order": 0,
        "estimatedMinutes": 15,
        "coreQuestion": "这封由死者账号送达的邮件从何而来，林薇真正留下了什么？",
        "unlockRequirements": [],
        "investigationLines": [
            {"id": "P-L1", "title": "死者来信", "beats": "阅读 03:17 邮件与附件错误码，确认投递发生在林薇死亡之后。"},
            {"id": "P-L2", "title": "零时镜像", "beats": "把零时邮局与 MIRROR-17 组合搜索，扫描只读缓存并保存原始日志。"},
        ],
        "twists": ["邮件不是灵异现象，而是林薇生前设置并由停运镜像完成的延迟投递。"],
        "hook": {
            "from": "林薇",
            "trigger": "葬礼后的凌晨 03:17，一封由死者账号签名的邮件抵达。",
            "playerGoal": "找到邮件附件真正指向的缓存，并保存林薇留下的第一段日志。",
        },
        "defaultNoiseResults": common_noise(),
        "network": [
            {
                "addr": "local.zero",
                "label": "陈默的本地工作区",
                "discoverWhen": {"type": "start"},
                "defense": {"mode": "public", "layers": [], "trace": {"enabled": False}},
                "files": [
                    {"path": "/home/陈默/凌晨便签.txt", "type": "text", "content": "03:17。邮件来自林薇。她的葬礼是昨天。先把每一步记下来。", "isEvidence": False}
                ],
            },
            {
                "addr": "mirror17.deadletter.zero",
                "label": "零时邮局 M-17 缓存",
                "discoverWhen": {"type": "gate", "id": "kg_mirror_search"},
                "defense": {
                    "mode": "crack",
                    "layers": [
                        {"id": "MIRROR_HANDSHAKE", "durationSec": 3.0},
                        {"id": "READONLY_SEAL", "durationSec": 4.0},
                    ],
                    "trace": {
                        "enabled": True,
                        "totalSeconds": 75.0,
                        "unfocusedRate": 0.25,
                        "lockoutSec": 20.0,
                        "signals": [
                            {"at": 0.06, "target": "relay.deadletter-17", "reduction": 0.20},
                            {"at": 0.45, "target": "cache.deadletter-17", "reduction": 0.22},
                        ],
                    },
                },
                "traceChain": ["deadletter.zero", "mirror-17", "林薇的离线签名盒"],
                "files": [
                    {"path": "/archive/LW_最后一次校对.zlog", "type": "doc", "content": last_log, "isEvidence": True, "evidenceId": "ev_linwei_log"},
                    {"path": "/meta/delivery.log", "type": "log", "content": delivery_log, "isEvidence": True, "evidenceId": "ev_delivery_log"},
                ],
            },
        ],
        "knowledgeGates": [
            {
                "id": "kg_mirror_search",
                "channel": "search",
                "where": "零索自由搜索",
                "howPlayerFigures": "邮件正文把『零时邮局』写成旧称，附件错误码只显示 MIRROR-17；玩家组合两段信息。",
                "accept": ["零时邮局 mirror17", "零时邮局 mirror-17", "零时邮局 m17"],
                "aliases": ["mirror17 零时邮局", "mirror-17 deadletter", "零时邮局17"],
                "hints": ["附件报错不是乱码，它像一个旧服务编号。", "邮件里提到的旧邮局，和附件上的 MIRROR-17 也许属于同一件事。", "把『零时邮局』和『MIRROR-17』一起放进搜索框。"],
                "unlockEffects": [{"type": "reveal_node", "target": "mirror17.deadletter.zero"}],
            }
        ],
        "tutorialMessages": tutorial_messages + tutorial_nudges,
        "tutorialFlow": {
            "enabled": True,
            "steps": tutorial_steps,
            "milestones": [
                {"id": "first_report_answer", "when": {"type": "report_answered"}, "feedback": {"appId": "report", "pulse": "soft", "sound": "progress_soft"}}
            ],
        },
        "sites": [
            {
                "id": "site_mirror_search",
                "gateId": "kg_mirror_search",
                "addresses": ["零时邮局 mirror17", "archive.deadletter.zero/mirror17"],
                "skin": "search",
                "title": "零索：零时邮局 MIRROR-17",
                "subtitle": "找到 5 条缓存结果，其中一条仍回应终端探测。",
                "results": [
                    result("零时邮局服务停止公告", "archive.deadletter.zero/notices/2024-09", "该服务曾为用户提供延迟投递与离线签名，MIRROR-17 为第十七号缓存镜像。"),
                    result("MIRROR 系列错误码说明", "kb.oldnet.zero/mirror-codes", "MIRROR-17 表示主站已停运但镜像仍保存一次只读副本。"),
                    result("有人还在用零时邮局吗", "sleepers.bbs.zero/thread/1172", "最后回复停在两年前：别把遗书交给会自动续费的服务。"),
                    result("延迟邮件与数字遗嘱的区别", "lawtalk.zero/archive/441", "文章讨论定时邮件不等同正式遗嘱，签名记录仍可能作为时间证据。"),
                    result("mirror17.deadletter.zero 状态快照", "cachewatch.zero/host/mirror17", "最近一次响应：03:17；协议标记：READ-ONLY。"),
                ],
            }
        ],
        "mails": [
            story_mail(
                "如果你还醒着，就从这里开始",
                "林薇 <linwei@deadletter.zero>",
                "2026-07-24 03:17",
                "陈默，收到这封信的时候，我大概已经被写进一份很短的事故通报里了。你先别去质问任何人，也别把附件直接转发。它经过一个叫『零时邮局』的旧服务，我把真正的日志放在那边的镜像里，附件只会留下一个编号。你总说我记东西像做审计，这次就按审计的办法来：看原始时间、看签名、看谁有权改动。找到以后，把它复制到本地证据目录。还有，任何时候觉得对方开始注意你，先断开。活着比逞强重要。",
                "林薇 / 延迟投递编号 DL-0317",
                [{"id": "attachment_deadletter_link", "name": "LW_最后一次校对.zlog.link", "path": "/mail/LW_最后一次校对.zlog.link", "type": "doc", "content": "附件解析失败。缓存代号：MIRROR-17。主站地址已失效。", "assetId": "art_deadletter_stamp", "description": "带有旧邮局戳记的错误页"}],
                mail_id="mail_deadletter_primary",
            ),
            story_mail(
                "系统回执：延迟投递已完成",
                "零时邮局自动回执 <no-reply@deadletter.zero>",
                "2026-07-24 03:17",
                "本邮件由停运服务的只读镜像自动发送。投递任务创建于 2026 年 7 月 21 日 02:13，签名账号为 linwei，接收账号为 chenmo。主站停运后，任务内容由 MIRROR-17 缓存保留，缓存只允许读取一次完整正文，但元数据可能继续存在。若收件人需要核对签名，请保留原始投递日志与附件头，不要使用截图代替原文件。此回执不代表平台对正文真实性作出保证。",
                "DEADLETTER M-17 / 自动签名",
                mail_id="mail_deadletter_receipt",
            ),
        ],
        "conversations": [],
        "horrorEvents": [
            {
                "id": "prologue_future_timestamp",
                "level": "B",
                "trigger": {"type": "evidence_collected", "target": "ev_linwei_log"},
                "once": True,
                "variants": {
                    "full": {"text": "邮件时间戳变成了明天。终端自行写下：别信官方结论。"},
                    "reduced": {"text": "邮件时间戳显示为明天，随后恢复。"},
                    "off": {"text": ""},
                },
            }
        ],
        "caseReport": [
            {"id": "p_q1", "q": "林薇要求你优先保存什么？", "options": ["事故新闻截图", "原始记录与时间戳", "她的社交头像", "葬礼名单"], "answer": 1, "evidence": ["ev_linwei_log"]},
            {"id": "p_q2", "q": "MIRROR-17 是什么？", "options": ["破解器", "直播间编号", "停运邮局的只读缓存", "警方档案号"], "answer": 2, "evidence": ["ev_delivery_log"]},
            {"id": "p_q3", "q": "林薇留下的第一条调查指令是什么？", "options": ["追查医院", "联系记者", "从她的账号开始查", "删除全部邮件"], "answer": 2, "evidence": ["ev_linwei_log"]},
        ],
        "resolution": {
            "surfaceTruth": "这不是死者复活，而是一封在她死亡前安排好的延迟邮件。",
            "clientOutcome": "陈默保存了原始日志，第一次在自己的笔记里写下 REN-0。",
            "darklineFragment": {"id": "frag_ren0_name", "content": "REN-0 不是用户名，更像一把被很多人用过的钥匙。"},
        },
        "contentManifest": ["林薇剧情邮件全文", "零时邮局回执全文", "延迟投递日志 24 行", "搜索结果 5 条", "林薇加密日志全文", "沉浸式教程推进消息 10 条", "沉浸式教程停滞提示 9 条"],
        "artAssets": [
            {
                "id": "art_deadletter_stamp",
                "usage": "序章附件错误页的旧邮局戳记",
                "size": "960x540",
                "prompt": compose_art_prompt(
                    purpose="Create a forensic attachment image for a desktop investigation game: a flatbed scan of a physical A4 error report printed by a defunct early-2000s Chinese delayed-email service. It must look like mundane office evidence recovered from an obsolete system, not like a website screenshot, cinematic prop, occult document, or designed horror poster.",
                    composition="Landscape 16:9 crop at 960 by 540 pixels. The off-white sheet fills roughly eighty-five percent of the frame and is rotated less than two degrees clockwise. Show the entire lower-right corner and most of the top edge. Keep the camera perfectly perpendicular like a flatbed scanner; no perspective-heavy desk photograph, no hands, and no envelope. Place the important faded service stamp in the lower-right quadrant, large enough to inspect but not centered like a logo.",
                    scene="Use thin gray monospaced printer rows, an obsolete form header, faint horizontal rules, two old staple holes near the upper-left corner, toner dropout, one vertical scanner streak, a soft fold across the lower third, and slightly darkened paper edges. The stamp should resemble an uneven thermal-receipt or rubber-service stamp with incomplete ink transfer. The surrounding metadata should suggest sender, recipient, scheduled delivery, and mirror routing through layout only; keep those minor rows too degraded to read. The paper must feel handled, archived, and rescanned several times.",
                    readable_text="The only fully readable text in the entire image must be the exact uppercase Latin string MIRROR-17, including the hyphen. Render MIRROR-17 once inside the faded lower-right stamp. All other printed rows must be authentic-looking but too blurred, clipped, or faded to decipher. Do not invent Chinese characters, dates, email addresses, logos, signatures, serial numbers, or extra English words.",
                    continuity="This is the physical-looking attachment that leads the player to search for MIRROR-17. Nothing in the image should prove a supernatural explanation; it should support the later discovery that the message came from an old read-only mail mirror. Preserve a restrained bureaucratic tone so it can coexist with the game's monochrome terminal and early-internet archive pages.",
                    lighting="Neutral gray flatbed-scanner illumination with no cast shadow, weak contrast, uneven toner density, subtle paper fibers, light JPEG ringing around dark characters, and a narrow band of overexposure along one edge. Avoid dramatic spotlighting. The degraded scan should remain legible enough to identify the single required stamp without looking artificially distressed.",
                    exclusions="No blood, skulls, ghosts, hands, candles, red wax seals, cyberpunk symbols, neon green code, holograms, modern smartphone UI, browser chrome, glossy graphic design, centered title card, decorative border, cinematic depth of field, random readable text, watermark, image-generation signature, or duplicate MIRROR-17 stamp.",
                    output="Produce one finished 960x540 raster image with no external caption, no mockup frame, no margin added by the generator, and no text outside the scanned sheet. Favor documentary plausibility and subtle evidence details over visual drama."
                )
            }
        ],
        "complianceCheck": base_compliance(),
    }


def build_case01_forum() -> list[dict]:
    detailed = [
        ("摄影社器材登记怎么又丢了", "旧器材柜的纸质表被搬走后，系统里只剩去年导入的半份名单。沈栀那台海鸥 DF-2 明明借去拍过迎新照，现在检索她的名字却显示空白。管理员说是退学账号清理，可照片社的人都记得她上个月还来洗底片。"),
        ("N17 门禁读头凌晨自己响", "我在兰圃楼值夜，最近十二天每天两点整，N17 都会短响一次。门没有真正打开，屏幕却记成有效刷卡。维修组换过电源也没用。我把秒表对过，误差不到一秒，这不像有人正好每天踩点。"),
        ("兰圃实验室旧成员页被改过", "搜索缓存还能看见沈栀是异常检测项目的第一作者，当前页面却只剩杜老师一个名字。连论文致谢的顺序也换了。网页管理员说是学生本人申请，我不信她会连自己的作品都删；摄影社存下的展板照片上，她的署名还排在最前面。"),
        ("休学流程真的能当天清空吗", "正常休学至少要学院、财务、宿管三处同步，哪怕效率再高也会留两三天延迟。沈栀的记录在 01:58 到 02:04 六分钟里同时消失，这更像有人拿了高权限批处理，而且没有留下任何线下签收编号。"),
        ("DF-2 的机背刻字是谁的", "器材室那台 DF-2 不是公物，是沈栀自己的。机背贴着 2023 入学纪念的小标签，她总拿这个组合记东西。她说数字比人可靠，但现在最不可靠的偏偏是系统里的数字。"),
    ]
    ambient = [
        ("二食堂夜宵窗口搬哪了", "今天去旧位置只看见一块封板，有人知道临时窗口开到几点吗？"),
        ("求一根老式快门线", "摄影社周末外拍，谁有机械快门线可以借两天，我押学生证。"),
        ("兰圃楼空调是不是坏了", "三楼冷得像机房，四楼又闷，报修单已经挂了一周。"),
        ("校园卡余额退款慢", "毕业退款第九天还没到，服务台说批次拥堵。"),
        ("有人捡到灰色笔袋吗", "里面只有几支针管笔和一张旧车票，对我挺重要。"),
        ("夜跑路线灯灭了一段", "西门到湖边那截路灯坏了，大家暂时结伴走。"),
        ("旧论坛登录验证码收不到", "邮箱换过后一直收不到验证码，管理员看到请帮忙。"),
    ]
    detailed_replies = [
        [
            {"author": "冲洗液", "body": "迎新那卷我帮她扫过，DF-2 的机背确实有一块掉漆，不可能突然变成器材室公用机。"},
            {"author": "旧胶卷", "body": "纸表被搬走前我拍过一页，沈栀签名旁边还有归还日期；我先把原图和拍摄时间一起备份。"},
            {"author": "暗房钥匙", "body": "管理员口中的退学清理说不通，个人器材从来不进公物回收名单。"},
        ],
        [
            {"author": "夜航员", "body": "我上周守到两点，响声先于屏幕亮起，走廊里没有脚步，时间却准得像定时任务。"},
            {"author": "电工阿梁", "body": "换电源只能排除供电毛刺；读头如果接着远程维护盒，后台照样能写一条假刷卡。"},
            {"author": "门房老周", "body": "N17 上个月接过维修盒，盒子编号印在机柜背面，交接单却没写是谁领走的。"},
        ],
        [
            {"author": "论文搬运工", "body": "学校知识库的五月快照还列着两位作者，六月版本才把沈栀整段删掉。"},
            {"author": "北窗", "body": "摄影社展板原图有拍摄日期，署名顺序也清楚，我已把原文件交给唐遥。"},
            {"author": "缓存猎人", "body": "别只存截图，把页面源文件、缓存时间和地址一起留着，之后才看得出是谁覆盖了版本。"},
        ],
        [
            {"author": "教务跑腿", "body": "我办过休学，纸表至少盖三枚章；六分钟全清空更像直接动了主库。"},
            {"author": "宿管值班", "body": "宿舍系统那晚 02:01 收到批量注销，备注栏是空的，也没有学生签字扫描件。"},
            {"author": "财务窗口", "body": "她的学费账户没有走退款流程，按正常规则学籍状态不该先变成『不存在』。"},
        ],
        [
            {"author": "负片", "body": "那块标签是她自己用刻字带打的，DF-2 和 2023 中间还有一道短横。"},
            {"author": "焦距不够", "body": "我借过一次，归还时她还开玩笑说这串记号比学生证号码好记。"},
            {"author": "暗房钥匙", "body": "器材登记册只记机身型号，不会替私人相机贴入学年份，所以这台肯定属于她。"},
        ],
    ]
    ambient_replies = [
        {"author": "饿到重影", "body": "临时窗口搬到二食堂西侧消防门旁，阿姨说这周都开到零点半。"},
        {"author": "机械快门", "body": "我有一根旧线，不过接口是三毫米螺纹；周五晚在摄影社门口拿。"},
        {"author": "报修单1142", "body": "三楼机房在排热，四楼阀门又卡住了，后勤回复周六统一检修。"},
        {"author": "毕业第十天", "body": "我的是第十个工作日到账，周末不算；再晚就拿流水号去窗口查。"},
        {"author": "打印室阿姨", "body": "昨晚打印室窗台有个灰笔袋，我交到一楼值班台了，你去对一下旧车票。"},
        {"author": "湖边慢跑", "body": "保卫处已经拉了反光带，通知说周五换灯，今晚最好还是从图书馆那边绕。"},
        {"author": "老站管理员", "body": "旧站只认原绑定邮箱，先看垃圾箱；仍收不到就把用户名和注册月份私信给我。"},
    ]
    posts: list[dict] = []
    for index, (title, body) in enumerate(detailed + ambient, start=1):
        if index <= 5:
            replies = detailed_replies[index - 1]
        else:
            replies = [ambient_replies[index - 6]]
        posts.append({"floor": index, "title": title, "author": ["负片", "夜猫子", "纸档案", "北窗", "门禁坏了"][index % 5], "time": f"2026-07-{8 + index:02d} 2{index % 4}:1{index % 10}", "body": body, "replies": replies})
    return posts


def build_case01_chat() -> list[dict]:
    pairs = [
        ("你是陈默吗？林薇以前说，如果系统里的人突然消失，可以找你。", "我是。先说名字，以及你最后一次见到她是什么时候。"),
        ("我叫唐遥。室友沈栀，十二天没回来。校方说她自愿退学。", "她有没有亲口告诉你要退学？"),
        ("没有。她连晾在阳台的被单都没收，桌上还有冲了一半的胶卷。", "把校方通知和她最近的账号信息发来，隐去真实证件号码。"),
        ("还有件更怪的，她的门禁卡每天凌晨两点都会刷进兰圃楼。", "同一台读卡器？时间有没有误差？"),
        ("N17。十二天，都是 02:00:00，最多差一秒。", "这种规律先考虑定时任务，不要把它当成她本人回来。"),
        ("我知道听起来像鬼故事，可昨晚我就在楼下，真的听见读头响了。", "声音是真的，不代表刷卡的人是真的。先查设备编号。"),
        ("学校论坛有人提过 N17，我把链接发你。", "保留页面正文和回复。设备维护记录往往比公告诚实。"),
        ("沈栀以前拍照，最常带一台很旧的 DF-2。", "这个细节先记着。密码习惯通常藏在重复使用的东西里。"),
        ("她 2023 年入学。你不会已经猜到密码了吧？", "我只有组合方向，仍要由登录结果验证。"),
        ("她的云盘要是还能进，会不会留下最后的文件？", "会，也可能留下别人改过的版本。先比时间线。"),
        ("我找到一张纸条：『杜老师又把我的名字往后挪。』", "杜老师全名、实验室名称、论文标题，三项一起查。"),
        ("杜承远，兰圃数据实验室。论文叫《低频异常中的群体偏差》。", "这能定位公开成员页和内部账号规则。"),
        ("门禁日志里真的是她的卡号。是不是说明她回来过？", "先看读卡器有没有远程重放标记，卡号出现不等于卡片出现。"),
        ("有一列 replay_source，我之前没注意。", "把那一行和正常刷卡行并排看，设备来源会不同。"),
        ("正常是 CARD，凌晨两点是 MAINT-BOX。", "第一层反转成立：有人在重放她的令牌。"),
        ("为什么非要用她的卡？", "让后续修改都落在她名下。去找实验室版本日志。"),
        ("云盘里有一段录音，我有点不敢听。", "你可以先把原文件取回，再断开，慢慢听。"),
        ("她说杜承远逼她签休学，不签就让她家里的助学金出问题。", "录音保留原时间和哈希，这会是关键证据。"),
        ("所以她还活着？", "录音只能证明录制时活着。继续找她主动留下的联系地址。"),
        ("照片冲印单背面有她姨妈家的旧地址。", "先交给警方核实，不要自己上门惊动对方。"),
        ("警方回我了。她在姨妈家，安全，只是不敢登录任何账号。", "好。现在要证明是谁清空了她的学籍。"),
        ("审计归档写着 REN-0，这是什么人？", "目前未知。先把它当权限签名，不要提前下结论。"),
        ("沈栀愿意作证，她问你为什么帮她。", "告诉她，我也在找一个被系统解释掉的人。"),
        ("她说谢谢。还有，她想把原始论文重新署名。", "证据交警方和校方调查组，别让恢复名誉再靠一次越界操作。"),
    ]
    return flatten_chat("唐遥", "陈默", "2026-07-25T21:04:00", pairs)


def build_case01() -> dict:
    chat_messages = stage_messages(build_case01_chat(), [
        (12, 14, {"type": "gate", "id": "kg_device_search"}),
        (14, 20, {"type": "gate", "id": "kg_cloud_login"}),
        (20, 24, {"type": "gate", "id": "kg_lab_account"}),
        (24, 32, {"type": "evidence", "id": "ev_gate_log"}),
        (32, 40, {"type": "evidence", "id": "ev_shenzhi_recording"}),
        (40, 44, {"type": "evidence", "id": "ev_ren0_authorization"}),
        (44, 48, {"type": "report_complete"}),
    ])
    gate_log = log_lines("GATE-N17", 46, {
        9: "2026-07-14 02:00:00 GATE-N17 token=S20417 source=MAINT-BOX-04 mode=REPLAY result=ACCEPT door_open=false",
        18: "2026-07-15 02:00:00 GATE-N17 token=S20417 source=MAINT-BOX-04 mode=REPLAY result=ACCEPT door_open=false",
        31: "2026-07-16 02:00:00 GATE-N17 token=S20417 source=MAINT-BOX-04 mode=REPLAY result=ACCEPT door_open=false",
        44: "2026-07-17 02:00:00 GATE-N17 token=CHENMO source=UNKNOWN-ROOM mode=INJECTED result=ACCEPT door_open=false",
    })
    version_log = log_lines("ORCHID-VCS", 48, {
        6: "2026-07-12 23:41:08 ORCHID-VCS commit=19ac author=shenzhi action=upload title=群体偏差原始模型 result=OK",
        17: "2026-07-13 01:58:17 ORCHID-VCS commit=19ac author=duchengyuan action=change_owner new_owner=duchengyuan result=OK",
        29: "2026-07-13 02:01:03 ORCHID-VCS actor=S20417 source=MAINT-BOX-04 action=delete_history range=01..18 result=PARTIAL",
        41: "2026-07-13 02:04:22 ORCHID-VCS actor=REN-0 action=approve_identity_purge subject=S20417 scope=campus_all result=OK",
    })
    recording = "\n".join([
        "00:00 门被关上，金属门舌回弹。",
        "00:04 沈栀：论文的原始数据和模型都是我做的，成员页为什么只剩你的名字？",
        "00:11 杜承远：署名顺序是项目安排，你先把休学表签了。",
        "00:18 沈栀：我没有申请休学。",
        "00:22 杜承远：你母亲的助学资格每学期都要复核，不要让一件小事影响家里。",
        "00:31 沈栀：这是威胁吗？",
        "00:34 杜承远：这是提醒。签完以后，账号暂时交给实验室做版本清理。",
        "00:43 椅子移动，纸张被推到桌面。",
        "00:48 沈栀：我会留一份原始记录。",
        "00:51 杜承远：系统里没有的东西，就不算记录。",
        "00:58 录音结束。",
    ])
    forum_posts = build_case01_forum()
    return {
        "caseId": "case_01_gate_2am",
        "title": "01：凌晨两点的门禁",
        "order": 1,
        "estimatedMinutes": 30,
        "coreQuestion": "谁在凌晨两点使用沈栀的门禁身份，又是谁把她从学院系统中抹除？",
        "unlockRequirements": ["prologue_dead_mail"],
        "investigationLines": [
            {"id": "C1-L1", "title": "两点整的门", "beats": "检索 N17，取得门禁与维护记录，发现刷卡没有伴随开门。"},
            {"id": "C1-L2", "title": "被拿走的署名", "beats": "拼出云盘凭证，核对原始论文与谈话录音，确认沈栀受到威胁。"},
            {"id": "C1-L3", "title": "克隆令牌", "beats": "渗透版本网关，找到 NIGHT-0200 定时重放任务和夜间删改记录。"},
            {"id": "C1-L4", "title": "六分钟消失", "beats": "进入学籍审计归档，确认 REN-0 批准跨系统身份清除。"},
        ],
        "twists": [
            "凌晨两点没有人刷卡；维护盒在不开门的情况下重放沈栀的克隆令牌。",
            "沈栀没有主动退学；杜承远借助例外通道抹除她，再把夜间改动栽到她名下。",
        ],
        "hook": {"from": "唐遥", "trigger": "失联室友的学籍已被清空，但她的门禁卡每天凌晨两点准时刷进封闭实验室。", "playerGoal": "确认刷卡者、找到沈栀，并证明谁删除了她的记录。"},
        "defaultNoiseResults": common_noise(),
        "network": [
            {
                "addr": "campus.zero.edu",
                "label": "澄岚学院公开门户",
                "discoverWhen": {"type": "start"},
                "defense": {"mode": "public", "layers": [], "trace": {"enabled": False}},
                "files": [
                    {"path": "/notice/学籍异动_0713.txt", "type": "doc", "content": "学籍异动公示：S20417 沈栀，数据科学系，状态由在籍调整为自愿退学。申请时间 01:58，学院审核 02:00，宿管同步 02:02，财务关闭 02:04。备注：本人线上提交，无纸质回执。", "isEvidence": True, "evidenceId": "ev_withdraw_notice"}
                ],
            },
            {
                "addr": "gate-cache.campus",
                "label": "N17 门禁缓存",
                "discoverWhen": {"type": "gate", "id": "kg_device_search"},
                "defense": {"mode": "crack", "layers": [{"id": "ECHO", "durationSec": 4.0}], "trace": {"enabled": False}},
                "files": [
                    {"path": "/logs/access_0714-0717.log", "type": "log", "content": gate_log, "isEvidence": True, "evidenceId": "ev_gate_log"},
                    {"path": "/maintenance/N17_更换记录.txt", "type": "doc", "content": "设备 N17 于 6 月 28 日接入 MAINT-BOX-04 远程维护盒。维护盒允许在不开门的情况下重放令牌，用于测试记录链。管理员：杜承远。测试任务应在当日结束后删除，但任务 NIGHT-0200 仍处于启用状态。", "isEvidence": True, "evidenceId": "ev_reader_notice"},
                ],
            },
            {
                "addr": "cloud.shenzhi.campus",
                "label": "沈栀的学生云盘",
                "discoverWhen": {"type": "gate", "id": "kg_device_search"},
                "defense": {"mode": "credential", "credentialGateId": "kg_cloud_login", "layers": [], "trace": {"enabled": False}},
                "files": [
                    {"path": "/research/群体偏差模型_原始版.md", "type": "doc", "content": "项目作者：沈栀。创建于 2025-11-08，连续提交 143 次。本文讨论低频异常识别中，训练数据对特定群体造成的系统性误判，并提出保留人工复核与可追溯撤销链。附录列出全部数据清洗记录、模型参数来源和沈栀本人签名。杜承远仅在 2026-06-20 添加一段经费说明。", "isEvidence": True, "evidenceId": "ev_original_version"},
                    {"path": "/audio/谈话_0712.ogg", "type": "audio", "content": recording, "assetId": "audio_shenzhi_recording", "description": "实验室谈话录音及完整文字稿", "isEvidence": True, "evidenceId": "ev_shenzhi_recording"},
                ],
            },
            {
                "addr": "lab-gateway.orchid",
                "label": "兰圃实验室版本网关",
                "discoverWhen": {"type": "gate", "id": "kg_lab_account"},
                "defense": {"mode": "crack", "layers": [{"id": "LATTICE", "durationSec": 5.0}, {"id": "PULSE", "durationSec": 5.0}], "trace": {"enabled": True, "totalSeconds": 120.0, "unfocusedRate": 0.25, "lockoutSec": 20.0, "signals": [{"at": 0.35, "target": "relay.orchid", "reduction": 0.18}, {"at": 0.7, "target": "acct.dc-yuan", "reduction": 0.22}]}},
                "files": [
                    {"path": "/vcs/version_history.log", "type": "log", "content": version_log, "isEvidence": True, "evidenceId": "ev_version_log"},
                    {"path": "/jobs/NIGHT-0200.task", "type": "text", "content": "job=NIGHT-0200\nowner=duchengyuan\ndevice=MAINT-BOX-04\ntoken=S20417\nschedule=02:00:00 daily\naction=replay_without_open\ncomment=保持账号活动轨迹，直至版本归属争议关闭", "isEvidence": True, "evidenceId": "ev_token_job"},
                ],
            },
            {
                "addr": "records-audit.campus",
                "label": "学籍审计归档",
                "discoverWhen": {"type": "gate", "id": "kg_lab_account"},
                "defense": {"mode": "crack", "layers": [{"id": "VEIL", "durationSec": 5.0}, {"id": "ARCHIVE", "durationSec": 6.0}], "trace": {"enabled": True, "totalSeconds": 90.0, "unfocusedRate": 0.25, "lockoutSec": 20.0, "signals": [{"at": 0.4, "target": "audit-hop-3", "reduction": 0.2}]}},
                "files": [
                    {"path": "/approvals/S20417.purge", "type": "doc", "content": "对象：S20417 沈栀。请求人：杜承远。理由：自愿退学后的账号回收。常规审核：缺失。例外通道：城市数据协同接口。批准签名：REN-0。批准范围：学籍、门禁、宿管、财务、实验室成员页。执行窗口：01:58—02:04。备注：保留令牌重放权限 30 日。", "isEvidence": True, "evidenceId": "ev_ren0_authorization"}
                ],
            },
        ],
        "knowledgeGates": [
            {"id": "kg_device_search", "channel": "search", "where": "搜索门禁编号", "howPlayerFigures": "唐遥给出 N17，论坛提到远程维护盒。", "accept": ["N17 门禁", "GATE-N17", "N17 维护"], "aliases": ["门禁 N17", "N17 reader", "兰圃楼 N17"], "hints": ["规律发生在同一台设备上。", "设备编号比学生姓名更适合查维护记录。", "把 N17 和『门禁』一起搜索。"], "unlockEffects": []},
            {"id": "kg_cloud_login", "channel": "login", "where": "沈栀云盘登录", "howPlayerFigures": "摄影社帖子写明她常用 DF-2，机背有 2023 入学标签。", "accept": [{"user": "S20417", "pass": "df22023"}], "aliases": [], "hints": ["她把最常带的东西当记忆锚点。", "摄影社反复提到相机型号，入学年份也在帖子里。", "相机型号小写加四位入学年。"], "unlockEffects": []},
            {"id": "kg_lab_account", "channel": "search", "where": "确认实验室负责人", "howPlayerFigures": "录音、论文致谢和旧成员缓存交叉指向杜承远。", "accept": ["杜承远 兰圃实验室", "兰圃 数据实验室 杜承远"], "aliases": ["duchengyuan orchid lab", "杜承远 群体偏差"], "hints": ["录音里被点名的人，在公开网页留下过痕迹。", "把负责人姓名和实验室名一起查。", "搜索『杜承远 兰圃实验室』。"], "unlockEffects": []},
        ],
        "sites": [
            {"id": "site_case01_device", "gateId": "kg_device_search", "addresses": ["campus.zero.edu/device/N17"], "skin": "campus", "title": "设备维护检索：N17", "subtitle": "澄岚学院设施服务中心 / 公开缓存", "results": [
                result("N17 读卡器维护记录", "campus.zero.edu/facility/N17", "6 月 28 日接入 MAINT-BOX-04，测试账号由兰圃实验室提供。"),
                result("兰圃楼夜间施工公告", "campus.zero.edu/notice/lanpu-night", "施工时段 00:00—05:00，门禁可能产生不开门的测试记录。"),
                result("门禁重放测试说明", "kb.campus.zero/replay", "维护模式允许重放令牌验证日志链，正常情况下任务当天删除。"),
                result("N17 电源报修单", "repair.campus.zero/R-7721", "电源稳定，异常短响与供电无关。"),
                result("旧设备编号目录", "archive.campus.zero/readers", "N17 位于兰圃楼二层数据实验室外侧。"),
            ]},
            {"id": "site_case01_forum", "gateId": "kg_device_search", "addresses": ["bbs.campus.zero/lanpu"], "skin": "forum", "title": "澄岚旧论坛 / 兰圃楼与摄影社", "subtitle": "访客计数 00387122　最后备份：昨夜 02:04", "posts": forum_posts},
            {"id": "site_case01_lab", "gateId": "kg_lab_account", "addresses": ["orchid.campus.zero/archive/team"], "skin": "campus", "title": "兰圃数据实验室旧成员缓存", "subtitle": "页面版本：2026-06-18", "results": [
                result("《低频异常中的群体偏差》项目页", "orchid.campus.zero/project/low-frequency", "第一作者沈栀，指导教师杜承远；当前正式页已删除学生作者。"),
                result("兰圃实验室成员：杜承远", "orchid.campus.zero/people/du", "内部账号前缀 dc-yuan，负责版本网关与设备测试。"),
                result("摄影社与数据实验室合作展", "news.campus.zero/2025/photo-data", "沈栀负责图像异常样本采集，使用海鸥 DF-2 胶片机。"),
                result("论文致谢缓存", "papers.zero/cache/LP-204", "感谢沈栀完成数据清洗、模型训练和误判分析。"),
                result("实验室访问规则", "orchid.campus.zero/rules/access", "夜间访问应使用本人令牌，不得保留离校成员权限。"),
            ]},
        ],
        "mails": [
            story_mail("有人每天凌晨两点用她的门禁卡", "唐遥 <tangyao@campus.zero>", "2026-07-25 21:02", "陈默，你可能不认识我。我和沈栀在澄岚学院合租，她十二天前突然不回消息，学校第二天就说她已经自愿退学。可她的衣服、相机药水和没交的社团照片都在房间里。最奇怪的是宿管系统：她的卡号每天凌晨两点整刷进兰圃楼，时间几乎一秒不差。昨晚我守在楼下，读卡器真的响了，但走廊里没有人。我把设备编号和退学通知附上。林薇曾经告诉我，如果一个人先从系统里消失，要找你。", "唐遥 / 宿舍 7-204", [{"name": "退学通知.txt", "path": "/notice/学籍异动_0713.txt", "type": "doc", "content": "S20417 沈栀：自愿退学，线上提交。四套系统在六分钟内同步关闭。"}]),
            story_mail("关于 S20417 的自动回复", "澄岚学院学生事务中心", "2026-07-25 21:18", "您查询的学生账号 S20417 已完成离校流程。根据系统记录，该生于 7 月 13 日在线提交自愿退学申请，学院、宿管、财务和校园卡服务均已同步。由于账号处于回收状态，中心不再提供联系方式、宿舍记录或学习材料。若您认为流程存在错误，请由本人携带有效证明到线下窗口申请复核。系统不接受室友、同学或社团成员代为提交的情况说明。此邮件由流程机器人生成，请勿直接回复。", "澄岚学院学生事务中心 / 工单 STU-88104"),
            story_mail("沈栀已由警方确认安全", "唐遥 <tangyao@campus.zero>", "2026-07-26 00:46", "警方刚刚回了我。沈栀在姨妈家，身体安全。她说杜承远拿她母亲的助学资格逼她签休学文件，又把实验室账号和学籍一起清掉。她不敢上线，因为每次登录都会收到『身份不存在』。她愿意把原始论文、录音和纸质表格交给警方，也愿意正式作证。她让我转告你：系统里没有她，不代表她没有做过那些工作。谢谢你没有把凌晨两点的刷卡声当成鬼故事，也没有擅自去找她。", "唐遥 / 已转交警方联络", unlock_when={"type": "report_complete"}),
        ],
        "conversations": [{"id": "chat_tangyao", "name": "唐遥", "messages": chat_messages}],
        "horrorEvents": [
            {"id": "c1_live_gate_injection", "level": "B", "trigger": {"type": "evidence_collected", "target": "ev_gate_log"}, "once": True, "variants": {"full": {"text": "门禁日志新增：陈默 / 当前房间 / 02:00。"}, "reduced": {"text": "日志末尾短暂出现你的名字。"}, "off": {"text": ""}}, "desktopEffect": {"type": "terminal_injection", "text": "scan 陈默 // LOCATION=CURRENT_ROOM"}},
            {"id": "c1_deleted_account_message", "level": "B", "trigger": {"type": "evidence_collected", "target": "ev_shenzhi_recording"}, "once": True, "variants": {"full": {"text": "已注销的沈栀账号发来：他知道你打开了。"}, "reduced": {"text": "通讯器闪过一条来自已注销账号的空消息。"}, "off": {"text": ""}}},
        ],
        "caseReport": [
            {"id": "c1_q1", "q": "凌晨两点的门禁记录由什么产生？", "options": ["沈栀本人刷卡", "宿管手工补录", "维护盒定时重放克隆令牌", "读卡器电源故障"], "answer": 2, "evidence": ["ev_gate_log", "ev_reader_notice"]},
            {"id": "c1_q2", "q": "杜承远为什么继续使用沈栀的身份？", "options": ["替她保留宿舍", "把夜间修改栽到她名下", "帮她申请奖学金", "测试摄影社设备"], "answer": 1, "evidence": ["ev_token_job", "ev_version_log"]},
            {"id": "c1_q3", "q": "沈栀为什么离开并停止登录？", "options": ["主动放弃论文", "受到助学资格威胁并被抹除账号", "加入别的实验室", "忘记了密码"], "answer": 1, "evidence": ["ev_shenzhi_recording", "ev_withdraw_notice"]},
            {"id": "c1_q4", "q": "谁批准了跨系统清除？", "options": ["唐遥", "普通宿管账号", "REN-0 权限签名", "摄影社管理员"], "answer": 2, "evidence": ["ev_ren0_authorization"]},
        ],
        "resolution": {"surfaceTruth": "每天两点出现的不是沈栀，而是用她身份执行的定时重放。", "clientOutcome": "沈栀安全并向警方提交原始材料；杜承远进入调查，论文归属启动复核。", "darklineFragment": {"id": "frag_ren0_purge", "content": "一份本不该跨越学籍、门禁和财务系统的删除命令，批准签名只有 REN-0。"}},
        "contentManifest": ["剧情邮件 3 封", "唐遥聊天 24 组双向往返", "校园论坛 12 帖", "门禁日志 46 行", "版本日志 48 行", "录音逐句文字稿", "搜索命中页各 5 条"],
        "artAssets": [
            {
                "id": "art_gate_n17",
                "usage": "N17 门禁设备照片",
                "size": "1024x768",
                "prompt": compose_art_prompt(
                    purpose="Create a documentary evidence photograph of an old access-control reader inside a Chinese university laboratory building at approximately 2:00 AM. The device must look like ordinary early-2010s institutional hardware that has been repaired and used for years, photographed by a student with a modest phone camera during an investigation.",
                    composition="Landscape 4:3 image at 1024 by 768 pixels. Eye-level camera about 1.55 meters high, standing one meter from the device with a mild three-quarter angle. Mount the old access-control reader on the right side of a scratched gray metal laboratory door; the corridor recedes toward the left background. Place the reader on the right third of the frame, large enough to inspect its screws, display, and label, while retaining enough corridor context to match the wide surveillance image.",
                    scene="The old access-control reader has yellowed light-gray ABS plastic, a tiny unlit monochrome LCD, a worn black RFID area, four small physical buttons, two mismatched screws, dust in the seams, an old maintenance sticker with its writing rubbed away, and a thin cable conduit entering from above. The adjacent door has chipped blue-gray paint around the latch and a dull stainless handle. The institutional corridor has blue-gray lower walls, dirty off-white upper walls, speckled tile flooring, a fire cabinet far away, and long fluorescent fixtures.",
                    readable_text="The exact uppercase label N17 must be clearly readable once on a small white laminated strip directly beneath the reader. N17 is the only fully readable text. Do not generate room names, warning labels, Chinese notices, dates, brand names, keypad numbers, logos, or other legible characters.",
                    continuity="This is a close evidence view of the same N17 reader visible farther down the hall in art_lanpu_corridor.png. Keep the reader on the right side of the same gray laboratory door, with the corridor extending left. The hardware must remain mundane and mechanically plausible because the mystery comes from the log records, not from a visibly supernatural machine.",
                    lighting="Cold aging fluorescent ceiling light with a slight green cast, weak phone-camera auto exposure, mild sensor grain in the shadows, imperfect white balance, a soft reflection on the door handle, and no flash hotspot. The LCD may catch a faint dull reflection but must not glow with symbols. Preserve realistic low-light softness without making the image too dark to inspect.",
                    exclusions="No futuristic biometric scanner, no face-recognition camera, no touchscreen, no bright LEDs, no neon, no green code, no sparks, no blood, no ghost, no person, no hand holding a card, no security guard, no dramatic Dutch angle, no cinematic fog, no luxury architecture, no pristine new hardware, no readable poster text, and no horror entity reflected in metal.",
                    output="Produce one realistic 1024x768 evidence photo with natural phone-camera imperfections, no added caption, no border, no watermark, and no interface overlay. The result should resemble an unedited photograph attached to a campus forum post."
                )
            },
            {
                "id": "art_shenzhi_df2",
                "usage": "沈栀的旧胶片机",
                "size": "800x600",
                "prompt": compose_art_prompt(
                    purpose="Create a candid evidence photograph of Shen Zhi's well-used 35mm film camera on a Chinese university dormitory desk. It should communicate that the owner is a serious student photographer with limited money and a habit of labeling equipment, not a collector displaying a luxury vintage camera.",
                    composition="Landscape 4:3 image at 800 by 600 pixels. Photograph from a seated person's viewpoint, about thirty-five degrees above the desk and slightly behind the camera, so the top plate, front-left shoulder, and rear film door can all be seen. Put the camera near the center-left, angled diagonally from lower-left to upper-right. Use a normal phone-camera focal length with a little edge softness; do not use a product-photo turntable or perfectly symmetrical composition.",
                    scene="Show a black-and-silver mechanical 35mm SLR with brassed corners, a cracked leatherette patch, a scratched manual-focus lens, a fabric strap repaired with black thread, fingerprints on the metal top plate, and a small dent near the rewind crank. Place two curled contact sheets, a strip of six developed negatives in a translucent sleeve, a red grease pencil, cotton gloves, handwritten exposure calculations that are not readable, an inexpensive desk lamp, and a chipped enamel mug nearby. The desk surface is cheap wood-grain laminate with chemistry stains and tape residue.",
                    readable_text="The engraved equipment label DF-2 must be clearly readable once on the camera's top plate. A small worn white tape sticker on the rear film door must show the handwritten numerals 2023 exactly once. DF-2 and 2023 are the only readable text. All notes, contact-sheet markings, and packaging must remain illegible scribbles or be turned away from the camera.",
                    continuity="This camera is the physical object remembered by photography-club members and used to prove that Shen Zhi remained active after the system claimed she had left. It should feel personally used and recently handled. Keep the modest dormitory context consistent with a student life, without visual clues suggesting wealth, professional studio ownership, or abandonment for many years.",
                    lighting="One warm practical desk lamp from the upper-left, weak cool spill from an unseen computer monitor, realistic mixed white balance, shallow but not extreme depth of field, subtle phone sensor noise, and soft reflections on scratched metal. Preserve detail in the DF-2 engraving and 2023 sticker while keeping the rest naturally imperfect.",
                    exclusions="No digital camera screen, no modern mirrorless body, no famous real-world brand logo, no pristine collector condition, no elaborate darkroom laboratory, no person or hand, no portrait photograph of Shen Zhi, no supernatural shadow, no blood, no neon, no cyberpunk styling, no decorative flowers, no commercial product lighting, no random readable words, and no duplicated labels.",
                    output="Produce one believable 800x600 phone photograph with no caption, no border, no watermark, and no generated UI. It must look like a file a student quickly sent through a messenger app for evidence review."
                )
            },
            {
                "id": "art_lanpu_corridor",
                "usage": "兰圃楼凌晨走廊",
                "size": "1280x720",
                "prompt": compose_art_prompt(
                    purpose="Create a fixed surveillance-camera still of an empty university laboratory corridor in China at 2:00 AM. The image is environmental evidence for a repeating access-log anomaly. The unease must come from institutional emptiness and exact timing, while every visible object remains ordinary and explainable.",
                    composition="Landscape 16:9 frame at 1280 by 720 pixels from a fixed high corner surveillance camera mounted near the ceiling at the near-left end of the corridor. Use a wide but believable security-camera lens looking diagonally down the hallway. The floor lines converge toward a dark fire door at the far end. About two-thirds down the corridor, show the scratched gray laboratory door on the right wall with the small N17 access reader beside it. Include a thin strip of ceiling in the upper frame and a broad empty floor area below.",
                    scene="Use aging blue-gray paint on the lower walls, dirty off-white paint above, speckled institutional tiles, exposed cable conduit, long fluorescent fixtures, a glass-front fire cabinet, two closed laboratory doors, a mop bucket parked far from the N17 door, and a wall clock whose face is too small to read. The N17 reader should be visible as the same yellowed rectangular device from art_gate_n17.png, but it is distant and not the visual center. Every door is closed. The corridor is completely still.",
                    readable_text="No human-readable text is required. The tiny N17 label may exist as a small visual mark but must be too distant to read cleanly. Do not invent department names, safety slogans, exit text, timestamps, camera IDs, subtitles, watermarks, or digital recording overlays.",
                    continuity="This wide image must match art_gate_n17.png: the N17 reader is mounted on the right side of the same scratched gray laboratory door, and the corridor extends left from the close-up viewpoint. Use the same blue-gray walls, off-white upper section, speckled floor, old fluorescent fixtures, and repaired cable conduit. There must be no human figure anywhere in the corridor, including reflections or distant silhouettes.",
                    lighting="Cold fluorescent illumination with one tube near the far end slightly dimmer than the others, mild green cast, lifted black levels, low dynamic range, corner vignetting, blocky H.264 compression, faint horizontal sensor noise, and a small overexposed strip under the nearest fixture. Keep the view readable; do not hide the corridor in darkness or add theatrical beams.",
                    exclusions="No human figure, no shadow person, no face, no ghost, no reflection shaped like a person, no open door, no blood, no fog, no smoke, no emergency red light, no flickering supernatural glow, no cyberpunk architecture, no futuristic display, no dramatic cinematic grading, no Dutch angle beyond the fixed mounting, no camera timestamp, and no random readable text.",
                    output="Produce one authentic 1280x720 low-bitrate surveillance still with no external caption, no border, no interface frame, and no decorative grain layer. It should feel like a frame exported from an inexpensive campus CCTV recorder."
                )
            },
        ],
        "complianceCheck": base_compliance(),
    }


def build_case02_chat() -> list[dict]:
    phases: list[list[tuple[str, str]]] = [
        [
            ("你是陈默吗？我叫苏晚。别人说你会查被删掉的东西。", "先告诉我发生了什么，别发身份证和真实住址。"),
            ("我哥苏野三个月前坠楼，警方说是失足。他直播名叫渡鸦。", "案件已经结案，但账号仍有异常，对吗？"),
            ("它每天准点发动态，还会给我照片点赞。昨晚甚至开播了 47 秒。", "你确认直播画面不是旧录像吗？"),
            ("是他的房间，连桌上的裂纹都一样。我看了十几遍。", "把直播地址和你保留的原始通知发来。"),
            ("raven.zhibo-lan.cn。你会不会觉得我疯了？", "不会。先把灵异解释放一边，查发布时间、文风和推流来源。"),
            ("死后动态有九十条。我越看越觉得不是他，但说不出哪里不对。", "把生前和死后的高频词、发帖时段分开记。"),
            ("他以前总说『稳喔』，死后写的是『稳哦』。", "这是可量化的差异，继续看分界日期。"),
            ("分界是死后第三天，而且之后全是整点。", "像脚本接管。先别推断操作者是谁。"),
            ("他的旧 NAS 还在家里，我只有地址，没有密码。", "密码线索通常来自他公开反复提到的人、宠物或纪念日。"),
            ("他养的猫叫馒头。你先查，我去翻他的置顶。", "好。不要直接把你猜到的密码发给任何第三方。"),
        ],
        [
            ("置顶写着开播三周年，0713。", "把宠物名和日期按他习惯组合，用户名先试直播名。"),
            ("进去了。我手一直抖。", "先 `ls`，不要急着打开所有东西，记住随时断开。"),
            ("有合同、记账和一段四月的直播回放。", "先看回放熟悉真实语气，再看合同。"),
            ("合同写他把死后账号运营权签给长明。是他自己签的。", "这推翻了盗号假设，但不代表后续运营合法。"),
            ("他为什么要卖掉自己？", "记账可能解释动机。"),
            ("他给我转了八千学费，还写签约能预支两万。", "把合同和记账都取证。真相可能很难听，但不是你的错。"),
            ("他到最后还在管我，我却在葬礼上怪他总不回家。", "先停一分钟也可以。证据不会因为你喘口气消失。"),
            ("长明到底是什么？", "合同乙方的完整名称值得搜索。"),
            ("我搜到一个数字纪念馆，页面说得特别体面。", "继续找工商缓存、旧论坛和离职员工发言。"),
            ("第二页有个帖子：『我们管那叫养号，不叫纪念』。", "打开全文，注意楼主工号、入职时间和默认密码规则。"),
        ],
        [
            ("楼主把工号 CM-041 都写出来了，胆子也太大。", "人会以为旧账号早已注销。找他的入职纪念日。"),
            ("签名档写 2023 年 3 月入职。默认密码是年月加公司全拼。", "你已经有组成凭证所需的全部信息。"),
            ("工单系统能登录。我看到 RAVEN-0339。", "先保存工单，再看同一日期的排班。"),
            ("工单说要把『喔』反向改成『哦』，还升级成活性维护。", "这解释了文风差异，也说明有人付费要求账号保持活跃。"),
            ("排班里写『7号扮演者，棚B，实景直播 47 秒』。", "第二层真相出现了：那不是录像，而是有人在演他。"),
            ("我有点想吐。", "先离开工单页，看一眼别的东西。你随时可以停。"),
            ("为什么正好 47 秒？", "可能是买方验证活性的最低时长，推流日志会说明来源。"),
            ("直播平台的边缘服务器出现在 scan 里了。", "probe 后再 crack。它会反向追踪，留意中继提示。"),
            ("追踪条开始走了。", "不要慌。看到中继地址就 trace；拿到核心文件后 disconnect。"),
            ("我在旁边等。你别为了我硬撑。", "收到。先取视频和两份日志。"),
        ],
        [
            ("你拿到了吗？", "拿到了。昨晚推流 IP 和软件版本都与生前不同。"),
            ("所以不是我哥家。", "对。来源指向长明棚区，但还要从排班交叉确认。"),
            ("视频里房间一模一样，我都分不出来。", "看镜子、插座、门轴这类布景容易犯错的位置。"),
            ("镜子的位置反了。哥哥房间里镜子在门左边。", "记下。进入逐格取证模式，不要只拖进度条。"),
            ("你看到第几格了？", "三十八。镜中人的姿势和房间里的人不同步。"),
            ("你还在吗？", "在。第 39 格里，他转头看向了镜头。"),
            ("……我不看。你也先别看了。", "好。文件已经取回，我们先整理证据。"),
            ("刚才渡鸦账号给我发了个空白点赞。", "截图留存，但不要把它当成哥哥。账号背后有人监控访问。"),
            ("那个扮演者会是谁？", "排班只写 7 号。终局节点可能有身份池。"),
            ("棚区地址是不是日志里的 172.19.240.66？", "是。那会是本案最敏感节点。"),
        ],
        [
            ("你真要进去？", "要拿到买方记录，但我会控制时间并保留自己的访问痕迹。"),
            ("为什么要保留？", "因为这些访问本身越界。最终交证据时，我也要交代。"),
            ("追踪到六成了，终端是不是多了一行？", "它写了 `trace 陈默`。对方正在确认我是谁。"),
            ("断开，求你。", "先取身份池，随后立即断开。"),
            ("拿到了吗？", "拿到了。三十多个死者账号被卖给系统里查无此人的活人。"),
            ("买死人名字的人也是受害者？", "有些是，但长明仍在贩卖身份并操纵家属。两件事可以同时成立。"),
            ("经办标记又是 REN-0？", "是。它把这个案子和之前的学籍清除连起来了。"),
            ("我哥知道账号会被这样用吗？", "合同只写纪念维护，没有真人扮演和身份转售。他没有同意这些。"),
            ("那 7 号扮演者呢？", "身份池只给出员工编号。警方接手后才能依法确认并保护证人。"),
            ("我现在只想让账号停下来。", "我们先完成结案，证据齐全后再通过警方和平台冻结。"),
        ],
        [
            ("第一题我选长明脚本，对吗？", "只按你已经取得的合同和工单判断，不要猜。"),
            ("账号是哥哥生前签出去的，这题我知道。", "记账说明了他为什么签，但不替长明的越界行为开脱。"),
            ("直播来自棚B，画面里是真人扮演者。", "推流日志和排班表互相支持。"),
            ("最后一题最难受：买家是需要活人证明的人。", "身份池里每个人都在零网上查无此人，这是直接证据。"),
            ("我想用哥哥的账号发最后一条动态。", "内容由你决定，发完后永久停更，并把操作交平台和警方备案。"),
            ("我写：『晚晚，学费够了。以后别等我上线。』", "这句话像他，也像你。确认后就让它停在这里。"),
            ("已经发了。账号冻结申请也交了。", "保存回执。长明的材料会并入警方调查。"),
            ("谢谢。刚开始我真的以为他回来了。", "你看到的是有人利用思念维持一门生意。"),
            ("你接下来还要查 REN-0 吗？", "会。但证据会交给警方，我也会交代自己的访问行为。"),
            ("那你也别消失。", "我会尽量不让系统替我写结局。"),
        ],
    ]
    pairs = [pair for phase in phases for pair in phase]
    assert len(pairs) == 60
    return flatten_chat("苏晚", "陈默", "2026-07-28T22:06:00", pairs)


def build_raven_posts() -> tuple[list[dict], list[dict], list[dict]]:
    before_texts = [
        "凌晨两点还在调麦，邻居再敲墙我就改成手语直播喔。",
        "馒头今天三岁了喔，抢走我半块鸡胸还装没事。",
        "新地图的电梯声比怪物还吓人，耳机党稳喔。",
        "房租又涨了，今晚多播一小时，别给我刷贵礼物喔。",
        "晚晚说她考试过了，我比自己上榜还高兴喔。",
        "键盘空格终于换好，之前每次跳跃都像临终遗言喔。",
        "有人问我为什么总熬夜，因为白天楼上装修，稳喔。",
        "馒头把摄像头撞歪了半小时，你们居然没人提醒我喔。",
        "今天不打排位，读粉丝寄来的烂笑话，谁先笑谁输喔。",
        "开播三周年是 0713，老观众来领一个没有用的纪念徽章喔。",
        "月底账单看得我心跳加速，比恐怖游戏有效喔。",
        "晚点开，先去给晚晚转学费，她又说不用，嘴硬喔。",
        "新耳机左边偏响，不知道是设备坏了还是我耳朵坏了喔。",
        "今晚十二点以后别点外卖，楼下师傅记得我房号了喔。",
        "直播间封面懒得换，反正你们是来看我翻车的喔。",
        "馒头睡在路由器上，网速只有它能决定喔。",
        "刚收到一份奇怪合同，字比游戏用户协议还多喔。",
        "今天早点下，明天去办点事，别在评论区给我守灵喔。",
        "有人说我笑点低，我只是尊重每一个冷笑话喔。",
        "旧录像修复好了，四月那场终于能看清房间喔。",
        "晚晚别偷偷看动态了，哥没欠钱，真的稳喔。",
        "平台分成又改，我决定以后用空气交房租喔。",
        "猫粮比我的饭贵，馒头已经实现阶层跃迁喔。",
        "新来的朋友别问本名，渡鸦比较好记喔。",
        "镜子挪到门左边以后，房间看着宽了一点喔。",
        "今天嗓子哑，字幕比我本人勤快喔。",
        "感谢老七寄的螺丝刀，桌腿终于不晃了喔。",
        "凌晨四点剪完片，太阳出来像系统报错喔。",
        "如果哪天不播了，希望你们先去睡觉，别等喔。",
        "稳喔。今天就这句，剩下的明天说。",
    ]
    before = []
    for index, text in enumerate(before_texts):
        time = datetime(2026, 3, 4, 23, 17) + timedelta(days=index, minutes=(index * 19) % 143)
        before.append({"time": time.strftime("%Y-%m-%d %H:%M"), "text": text})
    topics = [
        "记得按时吃饭", "今天适合整理桌面", "旧游戏也有新乐趣", "给自己留一点休息时间", "馒头看起来精神很好",
        "谢谢仍在这里的人", "夜深了请早点睡", "回忆值得被温柔保存", "今天也要保持稳定", "直播片段正在整理",
        "天气转凉注意添衣", "周末可以重看旧录像", "感谢每一次留言", "生活会继续向前", "纪念不是停在原地",
        "房间已经打扫干净", "愿你今天心情平稳", "下次更新仍在整点",
    ]
    tones = ["愿今天一切顺利哦。", "感谢大家一直陪伴哦。", "把普通日子认真过完哦。", "这里会继续保持更新哦。", "请照顾好自己哦。"]
    after = []
    for index in range(90):
        stamp = datetime(2026, 4, 8, 8, 0) + timedelta(hours=index * 8)
        after.append({"time": stamp.strftime("%Y-%m-%d %H:00"), "text": f"{topics[index % len(topics)]}，{tones[(index // len(topics)) % len(tones)]}", "scheduleIndex": index + 1})
    comments_text = [
        "这不是渡鸦，他从来不用『哦』。", "别消费死者了，平台出来解释。", "也许是家属在维护账号，先别骂。", "三个月了还准点发，谁看了不发毛。", "老粉都知道他不可能早上八点发动态。",
        "我只是想回来看看旧视频。", "昨晚直播有人录屏吗？", "47 秒里镜子的位置不对。", "房间能搭景，笑声搭不出来。", "别传灵异，先看推流信息。",
        "账号纪念功能不是这样写文案的。", "『活性维护』到底是什么服务？", "我举报了三次，平台都说内容正常。", "如果是家属，为什么不说明？", "渡鸦生前欠债，这会不会是合同？",
        "馒头现在跟谁住？", "苏晚别看评论，照顾好自己。", "有人在故意模仿他的口头禅。", "模仿得最差的就是那个喔字。", "每条整点，连一秒都不差。",
        "直播画面右下角的插座也反了。", "镜中人第 39 格是不是动了？", "我不敢逐格看第二次。", "别拿压缩伪影吓自己。", "压缩伪影不会只在镜子里转头。",
        "长明纪念馆买了推广吗？", "搜索长明能看到前员工爆料。", "那个帖子刚才还能开，现在 404。", "缓存站有备份，记得保存正文。", "CM-041 这工号是不是没注销？",
        "有人用死人账号做活体验证，太恶心了。", "买家可能也是被系统抹掉的人。", "受害者不等于可以买别人的人生。", "希望警方能查到棚区。", "REN-0 又出现了，前一案也有。",
        "最后那条动态是苏晚发的吗？", "『以后别等我上线』看哭了。", "账号终于停在了一个不整点的时间。", "愿渡鸦这次真的下播。", "稳喔。",
    ]
    comment_authors = [
        "熬夜看鸦", "旧频道存档员", "馒头投喂站", "七月十三号", "南窗没关",
        "不吃香菜的老粉", "码率观察员", "镜子在左边", "只看录播", "平台请回话",
        "山城网吧夜班", "灰帽衫还在", "晚风过机箱", "纸杯装咖啡", "暂停键失灵",
        "猫毛粘键盘", "苏晚要睡觉", "喔字校对员", "不是那个哦", "整点恐惧症",
        "右下角插座", "三十九格", "只看了一遍", "压缩块研究所", "镜中延迟半秒",
        "查了长明", "旧帖搬运工", "缓存还活着", "先保存再说", "工号没打码",
        "实名反对养号", "零网失踪人口", "边界不是借口", "等警方通报", "见过REN0",
        "最后一条不整点", "别再等上线", "频道已封存", "今晚早点睡", "稳喔老朋友",
    ]
    comments = [{"author": comment_authors[index], "time": f"2026-07-{14 + index // 8:02d} {18 + index % 6:02d}:{(index * 7) % 60:02d}", "text": text} for index, text in enumerate(comments_text)]
    return before, after, comments


def build_case02() -> dict:
    before, after, comments = build_raven_posts()
    chat_messages = stage_messages(build_case02_chat(), [
        (10, 20, {"type": "site", "id": "site_raven_live"}),
        (20, 26, {"type": "gate", "id": "kg_nas_password"}),
        (26, 30, {"type": "evidence", "id": "ev_contract"}),
        (30, 34, {"type": "evidence", "id": "ev_accounting"}),
        (34, 38, {"type": "evidence", "id": "ev_contract"}),
        (38, 44, {"type": "gate", "id": "kg_changming_login"}),
        (44, 48, {"type": "evidence", "id": "ev_ticket"}),
        (48, 54, {"type": "evidence", "id": "ev_schedule"}),
        (54, 60, {"type": "gate", "id": "kg_changming_login"}),
        (60, 64, {"type": "evidence", "id": "ev_ingest_log"}),
        (64, 68, {"type": "evidence", "id": "ev_raven_video"}),
        (68, 76, {"type": "horror", "id": "h3"}),
        (76, 84, {"type": "evidence", "id": "ev_schedule"}),
        (84, 88, {"type": "horror", "id": "h4"}),
        (88, 98, {"type": "evidence", "id": "ev_identity_pool"}),
        (98, 120, {"type": "report_complete"}),
    ])
    ingest_log = log_lines("INGEST", 45, {
        12: "2026-07-14 23:47:02 INGEST start channel=raven encoder=OBS28.1 ip=172.19.240.66 bitrate=2410kbps keyframe=2s",
        29: "2026-07-14 23:47:39 INGEST anomaly channel=raven mirror_motion=DESYNC frame_slot=39 source=studio-B",
        33: "2026-07-14 23:47:49 INGEST stop channel=raven duration=47s packets=2821 checksum=71c9",
        41: "2026-07-14 23:48:04 INGEST verification buyer=ANON-214 result=ACTIVE_IDENTITY_CONFIRMED operator=actor7",
    })
    history_lines = []
    for index in range(18):
        date = datetime(2026, 2, 1, 22, 10) + timedelta(days=index * 3, minutes=index * 11)
        history_lines.append(f"{date:%Y-%m-%d %H:%M:%S} channel=raven encoder=OBS26.4 ip=10.24.7.115 duration={6200 + index * 137}s result=ARCHIVED")
    transcript_observations = [
        "画面从黑场亮起，右下角出现渡鸦频道旧水印。", "自动曝光抬高，房间中央的椅子空着。", "桌面机械键盘灯未亮，只有显示器待机灯。", "窗帘没有摆动，环境里有持续空调声。", "镜子位于画面右侧，与四月回放中的左侧位置相反。", "画面压缩出现第一轮色块。", "门外传来一次金属碰撞。", "一个穿黑色连帽衫的人从左边进入。", "人物背对摄像头，身形接近苏野但肩线更窄。", "人物扶正椅背，没有说话。", "桌面上的猫抓痕是印刷贴纸。", "人物坐下，耳机仍挂在桌边。", "镜中反射比人物动作慢约半秒。", "人物抬手，镜中手臂没有同步抬起。", "推流码率下降，脸部被马赛克覆盖。", "背景墙上的裂纹比旧回放多出一条重复纹理。", "人物低头查看桌下提示板。", "提示板边缘短暂进入画面。", "画外有人轻敲两次。", "人物点头，仍未发声。", "镜中人物的头部保持正对窗户。", "现实人物转向显示器，镜中姿势未变。", "房间灯光从暖色切成冷白。", "时间码短暂跳回一秒。", "人物把手放到鼠标上。", "屏幕反光显示一行『验证剩余 22 秒』。", "镜中人物开始缓慢侧头。", "现实人物没有对应动作。", "空调声停止，出现很轻的呼吸。", "人物肩膀僵住。", "镜中脸部仍被压缩块遮挡。", "画面右上角出现 studio-B 内部时钟反光。", "人物看向画外，像在等指令。", "镜中人物已转过约四十五度。", "现实人物低头，双手离开桌面。", "码率恢复，镜中轮廓突然清晰。", "背景所有声音在同一时刻消失。", "人物仍然低头。", "镜中人物即将正对摄像头。", "镜中人物猛然转头直视镜头，现实人物没有动。", "画面发生一次水平撕裂。", "人物从椅子上起身，碰倒耳机。", "画外有人说『够了』。", "推流软件弹出结束倒计时。", "镜中已恢复为空房间反射。", "人物离开画面，椅子仍在轻晃。", "信号切黑，音频比画面晚半秒结束。",
    ]
    transcript = "\n".join(f"00:{index:02d} {text}" for index, text in enumerate(transcript_observations))
    contract = """《数字资产托管协议》\n甲方：苏野　乙方：长明网络科技工作室\n签署日期：2026 年 2 月 20 日\n第一条　甲方将渡鸦直播账号及其公开内容的身故后维护权交由乙方托管。\n第二条　托管仅限纪念动态、历史视频整理、评论区秩序维护及家属指定的停更公告。\n第三条　乙方预付甲方人民币二万元，甲方确认该款优先用于家庭教育与生活支出。\n第四条　乙方不得伪造甲方实时发言，不得使用真人或合成形象制造甲方仍在世的误解。\n第五条　乙方不得转售账号身份、验证能力、实名状态或与账号关联的任何信用证明。\n第六条　甲方家属可在提供死亡证明后申请永久停更与数据导出。\n第七条　乙方承诺账号仅用于纪念性维护，不得参与商业交易、借贷、身份租赁及活体验证。\n第八条　平台规则变化时，乙方应向家属发送书面通知，不得单方扩大托管范围。\n第九条　争议发生时，以本协议扫描件、付款记录和甲方原始签名为准。\n第十条　本协议未授权布景复刻、真人扮演、声纹模仿或直播推流。\n甲方签名：苏野　乙方经办：梁炽（长明）\n附记：甲方在签署前询问『我妹妹能不能随时让账号停下来』，乙方书面回复『可以』。"""
    accounting_rows = [
        "2025-07 平台分成 18420 房租 -4200 设备分期 -2100 给晚晚学费 -6000 结余 6120",
        "2025-08 平台分成 16110 房租 -4200 医疗 -980 给晚晚生活费 -3000 结余 7930",
        "2025-09 平台分成 14302 房租 -4200 猫粮医疗 -760 设备维修 -1600 结余 7742",
        "2025-10 平台分成 12980 房租 -4200 给晚晚学费 -8000 结余 780",
        "2025-11 平台分成 11040 房租 -4200 平台罚款 -2100 结余 4740",
        "2025-12 平台分成 15670 房租 -4200 年末设备税费 -3100 给晚晚 -4000 结余 4370",
        "2026-01 平台分成 9210 房租 -4200 馒头看病 -1680 结余 3330",
        "2026-02 平台分成 8660 房租 -4200 给晚晚学费 -8000 结余 -3540",
        "2026-02-20 长明预付款 +20000 先补学费和房租，合同说家属可以停更",
        "2026-03 平台分成 7020 房租 -4200 借款归还 -5000 结余 -2180",
        "2026-04 预计平台分成下降 62%，先不换电脑，馒头药不能停",
        "备注：别让晚晚知道缺口。签了能撑过这季度喔。",
    ]
    schedule_rows = ["date,start,end,actor,studio,task,channel,status"]
    actors = ["2号扮演者", "4号扮演者", "7号扮演者", "9号扮演者", "文案A", "灯光B"]
    for index in range(21):
        date = datetime(2026, 7, 10) + timedelta(days=index // 4)
        actor = "7号扮演者" if index == 18 else actors[index % len(actors)]
        task = "实景直播·47秒·验证用" if index == 18 else ["纪念动态校对", "头像活体录制", "房间布景维护", "买方验证", "声纹样本整理"][index % 5]
        studio = "棚B(渡鸦布景)" if index == 18 else f"棚{chr(65 + index % 4)}"
        schedule_rows.append(f"{date:%Y-%m-%d},{20 + index % 4}:00,{21 + index % 4}:30,{actor},{studio},{task},{'raven' if index == 18 else 'pool-%03d' % (120 + index)},完成")
    identity_rows = ["pool_id,dead_account,buyer_state,proof_use,broker,status"]
    surnames = ["周", "沈", "陈", "梁", "许", "顾", "蒋", "唐"]
    for index in range(31):
        account = f"mem-{index + 201:03d}"
        buyer = f"{surnames[index % len(surnames)]}某 / 零网状态=查无此人"
        broker = "REN-0" if index == 23 else f"CM-B{index % 6:02d}"
        identity_rows.append(f"IDP-{index + 1:04d},{account},{buyer},活人证明-{['租房','临时用工','医疗挂号','交通核验'][index % 4]},{broker},{'已交付' if index % 5 else '待复核'}")
    ticket_defs = [
        ("RAVEN-0339", "raven 频道粉丝质疑纪念动态文风不像本人。词频模型把『喔』改成了『哦』，需反向修正但买方要求继续保持整点活跃。账号已升级为活性维护套餐，棚 B 安排一次 47 秒实景验证。不得向家属展示套餐名称。"),
        ("POOL-1182", "买方无法通过租房平台活体核验，申请追加一次眨眼视频。账号原主家属仍在关注动态，建议降低频率并关闭评论。经办人要求不要使用旧房间布景，避免熟人识别。"),
        ("MEM-2044", "纪念页自动回复误把母亲称为姐姐，引发家属投诉。文案组已回滚称谓词典，客户经理承诺删除相关截图。该账号不允许直播，只保留节日动态。"),
        ("POOL-1190", "买方用于临时医疗挂号时触发死亡库冲突。技术组建议更换低关注度身份，不再继续维护现账号。旧账号将在七日后发布旅行动态以解释长期离线。"),
        ("STUDIO-77", "棚 C 墙纸纹理与原主公开视频不一致，验证被买方驳回。美术组需按旧视频重新打印墙纸并调整镜像方向，验收前禁止推流。"),
        ("MEM-2071", "家属提交永久停更申请，但账号已绑定三份活人证明订单。商务要求延迟处理十五日，客服统一回复『平台审核中』。法务未签字。"),
        ("POOL-1203", "新买方在零网中无工作、租赁和医疗记录，要求紧急启用身份。经办签名 REN-0，优先级高于普通纪念账号。需在今晚完成头像、声纹与一次短时直播。"),
    ]
    tickets = [{"id": ticket_id, "title": f"工单 {ticket_id}", "body": body, "status": "关闭" if index < 5 else "处理中", "owner": f"CM-{41 + index:03d}"} for index, (ticket_id, body) in enumerate(ticket_defs)]
    leak_replies = [
        {"author": "前台小梁", "body": "我也干过两周，培训第一句话就是『别把客户叫死者』。"},
        {"author": "不信", "body": "编故事吧，纪念账号哪来的买家？"},
        {"author": "CM-019", "body": "工单里真有活性维护，内部都知道，只是不敢说。"},
        {"author": "渡鸦老粉", "body": "那死后直播怎么解释？有人在棚里扮他？"},
        {"author": "楼主_CM041", "body": "棚区有按原房间搭的景，我只负责排班，没进去过。"},
        {"author": "网管", "body": "你工号都没打码，赶紧删。"},
        {"author": "楼主_CM041", "body": "账号早离职，默认密码还是 202303 加公司全拼，谁会留着。"},
        {"author": "存档员", "body": "已做网页快照。删除只会证明你说过。"},
        {"author": "家属甲", "body": "我父亲的账号也在半夜点赞，客服一直说是纪念功能。"},
        {"author": "法律援助", "body": "合同若只授权纪念维护，身份转售和真人扮演明显超出范围。"},
        {"author": "匿名买方", "body": "有些人不是想冒充，是自己的身份被系统删了，没名字就租不到房。"},
        {"author": "楼主_CM041", "body": "我知道买方也惨，但我们卖的是别人家属以为还安静躺着的人。"},
        {"author": "最后一楼", "body": "网页开始 502，保存工号、排班和公司全名。"},
    ]
    leak_posts = [{
        "floor": 1,
        "title": "我们管那叫养号，不叫纪念",
        "author": "楼主_CM041",
        "time": "2026-05-03 01:42",
        "body": "我在长明干了十四个月，入职是 2023 年 3 月。对外说做数字纪念，内部把账号分成静态、纪念和活性三档。活性不是多发几条动态，而是要让买方拿账号去做租房、挂号、临时用工时，看起来像一个仍在生活的人。我们会分析死者口头禅，复制房间，安排演员做短时直播。家属要求停更时，工单经理先查这个账号绑定了多少订单。我的工号 CM-041 离职后一直没注销，默认密码规则也从没改：入职年月加公司全拼。写出来不是炫耀，是想让有人把工单和排班拿走。",
        "replies": leak_replies,
    }]
    leak_noise = [
        ("夜班排班又临时提前", "今晚的头像采集从零点提前到二十三点，群里只发了一张模糊表格。我对照共享盘发现棚 B 的渡鸦频道和另一个买方验证任务只隔十分钟，演员却写的是同一个人。谁在棚区值班，麻烦确认灯光和房间布景不会撞车，也别再让临时工只靠口头通知换场。", "排班猫", "我在棚 A，表格最新版已经放到共享盘的 0502 目录。"),
        ("纪念页导出后中文全成方框", "客户要把旧留言刻成册，导出的 PDF 在第三页开始丢字体，名字和日期都变成空白方框。旧版客户端能正常显示，新版换过字体包后才出问题。我试过重新生成索引和清缓存，预览仍然正常、落盘就坏，明早家属来取件，谁处理过同一批模板请留一下完整步骤。", "字库工", "把嵌入字体选项关掉再导一次，思源黑体那包昨晚损坏了。"),
        ("求一份旧版声纹插件安装包", "新版本会把气声抹得太干净，做追思音频听起来像播音员，连原录音里吞字和换气都被拉平了。客户要求保留旧直播的沙哑感，我只需要 2.7 系列的离线安装包和校验值，不要带任何账号配置或声纹样本。今晚机器断网，在线安装器也用不了。", "音轨灰", "我有 2.7.4 的校验值，先私信核对文件名，别在公开帖传客户素材。"),
        ("棚 C 的隔音棉谁拆了", "下午录制时隔壁叉车声全进来了，墙上只剩一排发黄胶印，监听里还能听到仓库卷帘门。明早有两场家属口述和一场身份验证，前者要求安静，后者又不能换棚。今晚必须恢复基本吸音，拆走材料的人至少说清送去了哪里，别让场务拿被子临时堵墙。", "场务九", "仓库西门有两卷旧棉，颜色不一致但收音能顶一晚。"),
        ("离职账号到底多久注销", "我上个月交了设备和门卡，后台账号今天还能收到夜班工单。人事说系统批量处理，让我别登录。", "前员工17", "保留邮件截图再催一次，别替他们继续处理工单，不然审计算到你头上。"),
        ("清明自动回复称谓错了", "模板把外婆识别成姐姐，家属在评论区追问了三次。词典回滚后旧回复还挂着，客服说等缓存。", "文案乙", "先人工删掉那三条，缓存队列今晚两点才重建。"),
        ("审核接口周末一直超时", "静态纪念页也被要求重复提交活性字段，返回码一会儿 14 一会儿 31。有人知道是平台改规则还是我们映射错了？", "接口搬砖", "平台公告没写改动，先别批量重试，昨天有人把同一条任务送了四遍。"),
        ("补光灯少了一只柔光罩", "棚 B 的圆形罩昨天还在，今天只剩灯架。下周要复刻一间暖光卧室，直打肯定穿帮。", "灯光临时工", "我在棚 D 见到一个没贴编号的，收工后送回器材柜。"),
        ("账号库出现两个相同昵称", "两个纪念页都叫『北岸』，头像也相近，夜班同事差点把生日动态发错。请问合并前要不要先停自动任务？", "库管", "先停昵称检索，按内部编号处理；上次合并把家属留言串到别家了。"),
        ("家属投诉时统一话术又改了", "新版要求只说『平台审核中』，不许承诺停更日期。可对方已经等了二十天，再照读只会把人惹急。", "客服夜班", "把实际等待天数写进内部备注，公开回复先别自作主张给期限。"),
        ("招两天临时字幕校对", "周末有一批旧直播要补字幕，主要是方言和游戏术语。按小时结，不接触账号后台，只在办公室做。", "项目助理", "我能做周六白天，先发十分钟样例看看术语密度。"),
    ]
    expanded_noise_replies = {
        2: [
            {"author": "棚B记录员", "body": "渡鸦那场已经挪到二十三点四十，演员七号先做头像采集，再换黑色连帽衫。"},
            {"author": "旧排班员", "body": "别只看群图，CSV 最后一列有买方验证优先级，撞场时它会覆盖纪念任务。"},
        ],
        3: [
            {"author": "排版阿岑", "body": "坏的是昨晚更新的可变字体包，静态版没有问题，我把可用版本和许可证一起放回归档目录了。"},
            {"author": "客服夜班", "body": "家属那边我先解释成印刷校对，不要再用测试账号导出，测试库里缺了三个月留言。"},
        ],
        4: [
            {"author": "离线机房", "body": "2.7.4 在冷备盘 AUDIO-03，安装前先核对哈希，那个目录里混着一次失败升级留下的包。"},
            {"author": "做字幕的", "body": "气声别全留，原直播底噪很重；先按公开录像对齐停顿，再让家属确认是否像本人。"},
        ],
        5: [
            {"author": "叉车师傅", "body": "隔音棉不是我拆的，周一棚 C 漏水，物业让人搬到西门晾着，最外面那卷底部还潮。"},
            {"author": "收音小顾", "body": "潮的别直接上墙，会有霉味。先挂两层搬家毯，我二十二点带支架过去做一次底噪测试。"},
        ],
    }
    for index, (title, body, reply_author, reply_body) in enumerate(leak_noise, start=2):
        replies = [{"author": reply_author, "body": reply_body}]
        replies.extend(expanded_noise_replies.get(index, []))
        leak_posts.append({
            "floor": index,
            "title": title,
            "author": ["夜班纸杯", "旧客户端", "棚外等车", "匿名合同工"][index % 4],
            "time": f"2026-05-{3 + index:02d} {20 + index % 4:02d}:{11 + index:02d}",
            "body": body,
            "replies": replies,
        })
    return {
        "caseId": "case_02_dead_streamer",
        "title": "02：死者在线",
        "order": 2,
        "estimatedMinutes": 60,
        "coreQuestion": "渡鸦账号背后现在是谁，那 47 秒直播在哪里、由谁拍下？",
        "unlockRequirements": ["case_01_gate_2am"],
        "investigationLines": [
            {"id": "C2-L1", "title": "文风尸检", "beats": "通读生前与死后动态，识别喔到哦、深夜到整点的文风和时间漂移。"},
            {"id": "C2-L2", "title": "进他的家", "beats": "从猫名与周年日期拼出 NAS 凭证，取得合同、记账和生前回放。"},
            {"id": "C2-L3", "title": "四十七秒", "beats": "渗透边缘服务器，在反追踪压力下取得原始推流、日志与历史记录并逐格查看。"},
            {"id": "C2-L4", "title": "长明柜台底下", "beats": "搜索合同乙方，沿爆料帖拼出员工凭证，进入工单和排班系统。"},
            {"id": "C2-L5", "title": "谁在买死人", "beats": "从排班定位棚区内网，取得身份池与 REN-0 经办标记。"},
        ],
        "twists": [
            "账号没有被盗；苏野为妹妹预支学费，生前亲手签出了死后的账号运营权。",
            "47 秒直播不是录像或灵异；长明雇真人在一比一布景棚中进行活性验证。",
            "购买死者身份的人同样是零网上查无此人的活人，产业链把两类受害者绑在一起。",
        ],
        "hook": {"from": "苏晚", "trigger": "坠楼死亡三个月的主播渡鸦仍准点更新，昨晚又从他的房间开播 47 秒。", "playerGoal": "查清账号现在由谁操纵，以及那 47 秒直播从哪里拍摄。"},
        "defaultNoiseResults": common_noise(),
        "network": [
            {"addr": "raven.zhibo-lan.cn", "label": "渡鸦直播间公开页", "discoverWhen": {"type": "start"}, "defense": {"mode": "public", "layers": [], "trace": {"enabled": False}}, "files": [
                {"path": "/public/style_diff.txt", "type": "text", "content": "生前动态 30 条：深夜发布、常用『喔』、时间不规则。死后动态 90 条：整点发布、改用『哦』、句式重复。分界发生在死亡后第三天。", "isEvidence": True, "evidenceId": "ev_style_diff"}
            ]},
            {"addr": "10.24.7.115", "label": "苏野家里的旧 NAS", "discoverWhen": {"type": "start"}, "defense": {"mode": "credential", "credentialGateId": "kg_nas_password", "layers": [], "trace": {"enabled": False}}, "files": [
                {"path": "/video/直播回放_0402.mp4", "type": "video", "content": transcript, "frames": 47, "assetId": "art_raven_room_reference", "description": "苏野生前正常直播的房间与语气参考", "isEvidence": False},
                {"path": "/docs/合同扫描件.pdf", "type": "doc", "content": contract, "isEvidence": True, "evidenceId": "ev_contract"},
                {"path": "/notes/记账_全年.txt", "type": "text", "content": "\n".join(accounting_rows), "isEvidence": True, "evidenceId": "ev_accounting"},
            ]},
            {"addr": "edge-cdn.zhibo-lan.cn", "label": "直播平台边缘服务器", "discoverWhen": {"type": "gate", "id": "kg_nas_password"}, "defense": {"mode": "crack", "layers": [{"id": "STREAM", "durationSec": 6.0}, {"id": "EDGE", "durationSec": 6.0}], "trace": {"enabled": True, "totalSeconds": 120.0, "unfocusedRate": 0.25, "lockoutSec": 20.0, "signals": [{"at": 0.28, "target": "relay-edge-12", "reduction": 0.16}, {"at": 0.63, "target": "encoder-obs281", "reduction": 0.22}]}}, "files": [
                {"path": "/streams/raven_47s.flv", "type": "video", "content": transcript, "frames": 47, "assetId": "art_raven_stream_base", "description": "47 秒推流，每秒抽样为一格取证帧", "frameEvents": {"39": {"assetId": "art_frame39", "description": "镜中人物已经转头，正对摄像头。", "trigger": {"type": "viewer_frame", "target": "raven_47s:39"}}}, "isEvidence": True, "evidenceId": "ev_raven_video"},
                {"path": "/logs/ingest.log", "type": "log", "content": ingest_log, "isEvidence": True, "evidenceId": "ev_ingest_log"},
                {"path": "/logs/raven_history.log", "type": "log", "content": "\n".join(history_lines), "isEvidence": True, "evidenceId": "ev_stream_history"},
            ]},
            {"addr": "changming-mem.cn", "label": "长明数字纪念馆与工单系统", "discoverWhen": {"type": "gate", "id": "kg_search_changming"}, "defense": {"mode": "credential", "credentialGateId": "kg_changming_login", "layers": [], "trace": {"enabled": True, "totalSeconds": 150.0, "unfocusedRate": 0.25, "lockoutSec": 20.0, "signals": [{"at": 0.55, "target": "cm-auth-relay", "reduction": 0.2}]}}, "files": [
                {"path": "/tickets/RAVEN-0339.txt", "type": "doc", "content": tickets[0]["body"], "isEvidence": True, "evidenceId": "ev_ticket"},
                {"path": "/internal/排班表_0715.csv", "type": "sheet", "content": "\n".join(schedule_rows), "isEvidence": True, "evidenceId": "ev_schedule"},
                *[{"path": f"/tickets/{ticket['id']}.txt", "type": "doc", "content": ticket["body"], "isEvidence": False} for ticket in tickets[1:]],
            ]},
            {"addr": "172.19.240.66", "label": "农场棚区内网", "discoverWhen": {"type": "gate", "id": "kg_changming_login"}, "defense": {"mode": "crack", "layers": [{"id": "VEIL", "durationSec": 6.0}, {"id": "PULSE", "durationSec": 7.0}, {"id": "IDENTITY", "durationSec": 7.0}], "trace": {"enabled": True, "totalSeconds": 90.0, "unfocusedRate": 0.25, "lockoutSec": 20.0, "signals": [{"at": 0.25, "target": "farm-hop-7", "reduction": 0.14}, {"at": 0.5, "target": "actor-roster", "reduction": 0.16}, {"at": 0.72, "target": "REN-0", "reduction": 0.2}]}}, "files": [
                {"path": "/roster/身份池.db", "type": "db", "content": "\n".join(identity_rows), "isEvidence": True, "evidenceId": "ev_identity_pool"}
            ]},
        ],
        "knowledgeGates": [
            {"id": "kg_nas_password", "channel": "login", "where": "10.24.7.115 登录", "howPlayerFigures": "动态写猫叫馒头，置顶写开播三周年 0713。", "accept": [{"user": "suye", "pass": "mantou0713"}, {"user": "raven", "pass": "MANTOU0713"}, {"user": "苏野", "pass": "馒头0713"}], "aliases": [], "hints": ["我哥密码从来记不住，都用馒头……馒头是他的猫。", "他什么纪念日都设成密码，翻翻置顶动态。", "猫名拼音加那个日期，用户名试他的本名或直播名。"], "unlockEffects": []},
            {"id": "kg_search_changming", "channel": "search", "where": "零索自由搜索", "howPlayerFigures": "NAS 合同出现长明网络科技工作室。", "accept": ["长明", "长明网络科技", "changming", "数字纪念馆"], "aliases": ["长明工作室", "长明纪念馆"], "hints": ["合同乙方那个名字，你查过吗？", "搜索引擎不只能搜人名，公司也能搜。", "搜『长明』，再打开旧论坛缓存。"], "unlockEffects": []},
            {"id": "kg_changming_login", "channel": "login", "where": "changming-mem.cn 工单系统", "howPlayerFigures": "前员工帖子暴露工号 CM-041、2023 年 3 月入职和默认密码规则。", "accept": [{"user": "CM-041", "pass": "202303changming"}], "aliases": [], "hints": ["那个爆料的前员工，话说得比他以为的多。", "他连工号、入职年月和默认规则都写了。", "用户名用工号；密码是入职年月加公司全拼。"], "unlockEffects": []},
        ],
        "sites": [
            {"id": "site_raven_live", "gateId": "", "addresses": ["raven.zhibo-lan.cn", "渡鸦", "渡鸦直播"], "skin": "raven", "title": "渡鸦的直播间", "subtitle": "关注 184,203　最后直播：昨晚 23:47，持续 47 秒", "content": "频道状态：纪念维护中。置顶：开播三周年 0713。房间主人苏野已于三个月前去世。", "dynamicBefore": before, "dynamicAfter": after, "comments": comments},
            {"id": "site_changming_search", "gateId": "kg_search_changming", "addresses": ["零索 长明"], "skin": "search", "title": "零索：长明网络科技", "subtitle": "找到 5 条结果；旧论坛缓存仍可访问。", "results": [
                result("长明·数字纪念馆", "changming-mem.cn", "提供纪念主页、历史内容整理和账号托管，宣称『让告别不必突然』。"),
                result("匿名爆料：我们管那叫养号，不叫纪念", "oldbbs.zero/thread/CM041", "前员工描述排班、布景棚、活性维护与未注销工号。"),
                result("企业信息：长明网络科技工作室", "registry.zero/company/CM-2019", "成立于 2019 年，经营范围含数字内容托管，登记地址与棚区仓库相邻。"),
                result("家属投诉汇总缓存", "consumer.zero/archive/changming", "多名家属称亲人账号在申请停更后仍继续点赞与更新。"),
                result("招聘：身份维护夜班演员", "jobs-cache.zero/changming-actor", "已删除职位缓存，要求熟悉直播、可按脚本模仿账号主人生活习惯。"),
            ]},
            {"id": "site_changming_leak", "gateId": "", "addresses": ["oldbbs.zero/thread/CM041", "我们管那叫养号不叫纪念"], "skin": "forum", "title": "旧网从业者论坛 / 匿名爆料", "subtitle": "主题已删除，以下为缓存副本", "posts": leak_posts},
            {"id": "site_changming_official", "gateId": "", "addresses": ["changming-mem.cn"], "skin": "changming", "title": "长明·数字纪念馆", "subtitle": "让每一次告别，都有一盏不熄的灯", "content": "我们为逝者家属整理公开照片、视频和文字，提供纪念页维护与定时追思服务。页面使用米白底、仿纸纹边框和循环播放的廉价钢琴动画。服务条款只反复强调『陪伴』，没有解释活性维护、真人扮演或身份验证。"},
            {"id": "site_workorders", "gateId": "", "requiresGate": "kg_changming_login", "addresses": ["changming-mem.cn/tickets", "长明工单"], "skin": "workorder", "title": "长明内部工单", "subtitle": "登录账号 CM-041 / 夜班队列", "tickets": tickets},
        ],
        "mails": [
            story_mail("我哥死了三个月，昨晚却开播了", "苏晚 <suwan@ping.zero>", "2026-07-28 22:03", "陈默，我叫苏晚。哥哥苏野是游戏主播『渡鸦』，三个月前深夜坠楼，警方结论是失足。葬礼后，他的账号没有停：每天准点更新，会给我的照片点赞，回复粉丝时却越来越像客服。昨晚 23:47，账号突然开播 47 秒。画面是哥哥的房间，桌子、椅子、墙上的裂纹都在，但整段没有一句话。我保存了通知和直播地址。别人让我把账号拉黑，可如果有人正用他的脸活着，我想知道那个人是谁。", "苏晚 / 请只通过 PING 联系", [{"name": "47秒直播通知.txt", "path": "/mail/raven_notice.txt", "type": "doc", "content": "频道 raven 于 23:47 开始直播，23:47:49 结束，总时长 47 秒。"}]),
            story_mail("账号托管材料扫描件", "苏晚 <suwan@ping.zero>", "2026-07-28 23:12", "我在哥哥留下的纸箱里找到一张长明工作室的付款回执，金额是两万元。以前我以为那是平台预付分成。回执背后写着『账号托管，家属可停』，字是哥哥的。他那段时间总问我学费够不够，我还嫌他烦。NAS 地址是 10.24.7.115，用户名可能是他的本名或直播名。我不知道密码，也不希望你为了进它做会伤到自己的事。如果看到追踪条，先断开。哥哥已经不在了，我不想再因为这件事失去一个人。", "苏晚 / 回执编号 CM-0220", unlock_when={"type": "evidence", "id": "ev_contract"}),
            story_mail("永久停更回执", "渡鸦直播平台账号安全组", "2026-07-30 01:26", "平台已收到苏野家属、代理律师及警方联合提交的账号冻结材料。经核查，渡鸦账号在账号主人死亡后发生未经家属确认的商业运营、短时直播与身份验证调用。平台现已停止全部自动更新、第三方接口和登录令牌，并封存相关推流日志。账号最后一条由家属发布的动态将保留为纪念，之后永久停更。长明网络科技工作室关联账号已转交执法机关调查。本回执仅证明平台完成冻结，不影响后续责任认定。", "渡鸦直播平台账号安全组 / 回执 RAVEN-FREEZE-1", unlock_when={"type": "report_complete"}),
        ],
        "conversations": [{"id": "chat_suwan", "name": "苏晚", "messages": chat_messages}],
        "horrorEvents": [
            {"id": "h1", "level": "B", "trigger": {"type": "content_read_seconds", "target": "site_raven_live:postdeath", "threshold": 120}, "once": True, "variants": {"full": {"text": "渡鸦刚刚发布：今天也有人在看我喔。"}, "reduced": {"text": "动态列表顶部多出一条刚发布的空白记录。"}, "off": {"text": ""}}},
            {"id": "h2", "level": "B", "trigger": {"type": "evidence_collected", "target": "ev_raven_video"}, "once": True, "variants": {"full": {"text": "渡鸦私信：别帮她查了。她已经习惯我了。"}, "reduced": {"text": "渡鸦会话出现一秒后消失。"}, "off": {"text": ""}}},
            {"id": "h3", "level": "C", "trigger": {"type": "viewer_frame", "target": "raven_47s:39"}, "once": True, "variants": {"full": {"text": "第 39 格：镜中人猛然直视镜头。"}, "reduced": {"text": "画面定格。镜中人已经转头。"}, "off": {"text": ""}}, "afterBeat": {"sender": "苏晚", "text": "陈默？刚才整整五秒没有声音。", "delay": 5.0}},
            {"id": "h4", "level": "B", "trigger": {"type": "trace_threshold", "target": "172.19.240.66", "threshold": 0.6}, "once": True, "variants": {"full": {"text": "终端插入：trace 陈默。桌面左下角出现红点。"}, "reduced": {"text": "追踪目标字段短暂显示为陈默。"}, "off": {"text": ""}}, "desktopEffect": {"type": "terminal_injection", "text": "trace 陈默", "persistentMark": "counter_trace"}},
        ],
        "caseReport": [
            {"id": "c2_q1", "q": "渡鸦账号死后最初由谁操作？", "options": ["盗号者", "长明工作室的文案脚本", "苏野本人", "平台纪念机器人"], "answer": 1, "evidence": ["ev_contract", "ev_ticket"]},
            {"id": "c2_q2", "q": "账号运营权怎样落到长明手中？", "options": ["家属死后转让", "苏野生前签署托管协议", "长明伪造全部签名", "平台公开拍卖"], "answer": 1, "evidence": ["ev_contract", "ev_accounting"]},
            {"id": "c2_q3", "q": "47 秒直播从哪里推流？", "options": ["苏野家中", "苏晚家中", "长明棚 B", "海外镜像"], "answer": 2, "evidence": ["ev_ingest_log", "ev_stream_history", "ev_schedule"]},
            {"id": "c2_q4", "q": "画面里的『苏野』是什么？", "options": ["换脸合成", "生前录像", "真人扮演者", "双胞胎"], "answer": 2, "evidence": ["ev_schedule", "ev_raven_video"]},
            {"id": "c2_q5", "q": "长明把活着的死人账号卖给谁？", "options": ["广告刷量商", "需要活人证明的查无此人者", "游戏工作室", "粉丝收藏者"], "answer": 1, "evidence": ["ev_identity_pool"]},
        ],
        "resolution": {"surfaceTruth": "没有鬼。苏野为妹妹预支学费签下纪念托管，长明却把账号扩张成真人扮演和身份交易。", "clientOutcome": "苏晚发布最后一条不在整点的动态，账号永久停更；材料移交警方。", "darklineFragment": {"id": "frag_identity_pool", "content": "身份池买方全是在零网上『查无此人』的活人，经办标记 REN-0。被系统抹掉的人，需要死人的名字才能继续生活。"}},
        "contentManifest": ["渡鸦死前动态 30 条", "渡鸦死后动态 90 条", "粉丝评论 40 条", "苏晚聊天 60 组双向往返", "NAS 合同、全年记账与 47 秒文字稿", "推流日志 45 行与生前记录 18 行", "长明搜索结果 5 条", "爆料论坛 12 帖，其中 5 帖为完整讨论，核心帖 13 条回复", "完整工单 7 份", "排班表 22 行", "身份池 32 行"],
        "artAssets": [
            {
                "id": "art_raven_avatar",
                "usage": "渡鸦头像",
                "size": "256x256",
                "prompt": compose_art_prompt(
                    purpose="Create the archived square profile avatar of Su Ye, a young Chinese male game streamer known online as Raven. It should look like a compressed self-selected channel avatar captured with an inexpensive webcam around the mid-2010s, personal and recognizable but not professionally retouched or designed as promotional key art.",
                    composition="Square 1:1 image at 256 by 256 pixels. Head-and-shoulders framing from a webcam at monitor height, camera slightly below eye level and less than one meter away. Su Ye sits a little left of center and looks directly toward the lens with a small tired smile rather than a dramatic pose. Crop the lower chest, leave a narrow amount of dark room around his head, and keep the background softly recognizable instead of replacing it with a studio backdrop.",
                    scene="Depict a Chinese man in his mid-twenties with ordinary facial proportions, short slightly messy black hair, faint under-eye shadows, light stubble, and natural skin texture. He wears a plain washed black hoodie with no logo; large over-ear headphones rest around his neck, with one worn ear pad visible. Behind him are a dark monitor edge, a warm desk lamp, an indistinct curtain, and the blurred edge of a cramped bedroom. His expression is friendly but exhausted, like someone ending a late stream.",
                    readable_text="No readable text. Do not add the name Raven, Chinese characters, platform badges, follower counts, gamer tags, logos, subtitles, watermarks, clothing text, or interface elements. Keep all background screens dark or too blurred to read.",
                    continuity="This portrait establishes the real Su Ye. The studio actor in the 47-second stream may share a similar build and black hoodie but must not be treated as an exact facial duplicate. Preserve Su Ye's ordinary, slightly tired appearance for any future family or archive images. Do not make him resemble a celebrity or an idealized fictional hacker.",
                    lighting="Warm practical desk lamp from camera-left, cool low-intensity monitor fill from below, compressed webcam dynamic range, mild chroma noise in the shadows, slightly soft focus, subtle JPEG blocks around hair, and imperfect white balance. Keep both eyes and the headphone shape readable without beauty lighting or dramatic rim light.",
                    exclusions="No cyberpunk neon, no RGB gaming-room spectacle, no mask, no sunglasses, no weapon, no blood, no ghost effect, no skull logo, no luxury streamer setup, no professional studio portrait, no fashion-model skin, no extreme grin, no sinister expression, no anime style, no painterly concept art, no readable interface, and no elaborate branded clothing.",
                    output="Produce one finished 256x256 square raster avatar, edge-to-edge with no circular crop, no frame, no caption, no watermark, and no transparent background. It must remain believable when displayed small inside an early-internet livestream profile."
                )
            },
            {
                "id": "art_cat_mantou",
                "usage": "动态配图：猫馒头",
                "size": "800x600",
                "prompt": compose_art_prompt(
                    purpose="Create a casual low-quality phone snapshot posted by Su Ye to his followers: his cat Mantou occupying a cluttered computer desk late at night. The image should feel affectionate, accidental, and slightly messy, like a real social-media attachment rather than a staged pet photograph.",
                    composition="Landscape 4:3 image at 800 by 600 pixels, shot one-handed from a seated person's chest height with the phone tilted about three degrees. Mantou occupies the left-center foreground, partly lying across the front edge of a black mechanical keyboard. The keyboard runs diagonally across the lower frame, a monitor base sits in the upper-right, and the warm desk lamp itself remains out of frame. Allow a small amount of motion blur on one paw and imperfect cropping of the tail.",
                    scene="Mantou is a chubby white cat, a domestic short-haired animal with a single pale-gray patch above the left ear, a pink nose, amber eyes, and slightly dusty paws. The desk contains a worn black mechanical keyboard with several polished keycaps, a cheap mouse, tangled charging cables, two opened cat-treat packets with their writing turned away, a chipped enamel mug, a roll of black tape, and a small medicine dropper bottle with no readable label. Include loose white cat hair on the dark desk mat and a shallow cardboard box in the background.",
                    readable_text="No readable text anywhere. Key legends may be tiny and indistinct, and all packaging or bottle labels must face away or be blurred. Do not add the cat's name, a date, a social-media caption, a platform watermark, brand names, screen text, subtitles, or decorative typography.",
                    continuity="Mantou's identifying features are the round white body, pale-gray patch above the left ear, pink nose, and amber eyes. Future images of the cat should preserve those traits. The desk belongs to the same financially strained streamer implied by Su Ye's records: used equipment, repaired cables, practical clutter, and no luxury gaming furniture.",
                    lighting="Warm tungsten desk-lamp light from the upper-left, dim blue monitor spill from the upper-right, phone-camera auto exposure favoring the cat's white fur, slightly clipped highlights on the back, visible shadow noise, weak sharpening halos, and mild motion blur. Keep the result cozy but not polished, with realistic mixed color temperature.",
                    exclusions="No studio pet lighting, no perfectly clean desk, no flower arrangement, no costume, no bow tie, no fantasy cat eyes, no extra cat, no human face or hand, no RGB rainbow keyboard, no expensive gaming setup, no cyberpunk neon, no horror element, no blood, no supernatural shadow, no readable product label, no meme text, and no stock-photo composition.",
                    output="Produce one unedited-looking 800x600 phone photograph with no border, no caption, no watermark, no collage, and no added UI. It should remain believable as an ordinary attachment embedded between short livestream updates."
                )
            },
            {
                "id": "art_raven_room_reference",
                "usage": "苏野生前直播房间参考",
                "size": "1280x720",
                "prompt": compose_art_prompt(
                    purpose="Create an archived pre-death livestream still showing Su Ye's real cramped bedroom, used by the player as the master spatial reference for comparing the later 47-second stream. It must look like a paused 720p webcam recording from an ordinary mid-2010s Chinese game stream, not a photograph taken by a film crew.",
                    composition="Landscape 16:9 frame at 1280 by 720 pixels from a fixed webcam position mounted at the top center of Su Ye's monitor, facing away from the monitor into the room. The lower six percent of the image contains the blurred edge of the dark desk. A worn black office chair sits centered. On the back wall, a narrow off-white door is slightly right of center. A rectangular wall mirror is mounted on the left side of the door, with a visible gap of about twenty centimeters between mirror and doorframe. A curtained window occupies the far-left wall.",
                    scene="Use a small rented bedroom with uneven off-white walls, a warm desk lamp on the left, a black mechanical keyboard partly visible at the bottom, a cheap headset hanging from the chair, a narrow shelf with game cases too blurred to read, a small diagonal hairline crack above and left of the door, a longer branching crack behind the chair, a scuffed baseboard, an exposed power socket low on the right wall, three real cat scratches on the front-right edge of the desk, and a folded blanket on a simple bed just outside the right edge. Keep furniture proportions cramped and practical.",
                    readable_text="No readable text. Screens, game cases, labels, posters, packaging, and any wall notes must be dark, turned away, or too soft to decipher. Do not add a channel watermark, timestamp, subtitles, room label, gamer tag, platform interface, or decorative lettering.",
                    continuity="This is the canonical room layout. Preserve the fixed webcam position, centered black chair, door slightly right of center, mirror on the left side of the door, two specific wall cracks, exposed low right socket, desk cat scratches, headset placement, curtain, lamp position, and shelf silhouette. art_raven_stream_base.png must copy these anchors while deliberately moving the mirror to the right side of the door and making several details look replicated rather than naturally worn.",
                    lighting="Warm practical lamp from frame-left with weak cool monitor spill from behind the camera, low-cost webcam auto exposure, mild barrel distortion, slightly crushed blacks, soft corner focus, low chroma resolution, sparse compression blocks, and a natural 720p paused-video softness. The room should be clearly inspectable without cinematic grading or deep horror darkness.",
                    exclusions="No person, no reflected person, no ghost, no blood, no moving curtain, no modern luxury furniture, no RGB lighting, no cyberpunk neon, no futuristic hardware, no professional film lights, no visible warehouse, no mirror on the right side of the door, no duplicated mirror, no changed camera height, no readable text, no dramatic wide-angle distortion, and no stylized horror poster treatment.",
                    output="Produce one edge-to-edge 1280x720 webcam frame with no border, no player controls, no caption, no watermark, and no external UI. Prioritize exact object placement and documentary continuity over beauty."
                )
            },
            {
                "id": "art_raven_stream_base",
                "usage": "47 秒直播普通取证格",
                "size": "1280x720",
                "prompt": compose_art_prompt(
                    purpose="Create frame 38 of the suspicious 47-second Raven livestream: a low-bitrate broadcast from a replica studio room built to imitate Su Ye's bedroom. When generating this image, upload art_raven_room_reference.png as the visual reference. The result must initially seem convincing but contain physical continuity errors the player can discover by comparing frames.",
                    composition="Landscape 16:9 frame at 1280 by 720 pixels. Match the reference image's fixed webcam position, lens distortion, camera height, crop, centered chair, back-wall perspective, desk edge, and door location as closely as possible. This is the same apparent viewpoint, not a new angle. A slim male studio actor in a washed black hoodie sits in the centered chair with shoulders slightly narrower than Su Ye's. He faces the desk and keeps his head lowered. Show his upper back and partial side profile without a clear face.",
                    scene="Rebuild the cramped bedroom as a replica studio room. Copy the narrow door slightly right of center, curtain, shelf silhouette, black chair, headset, desk, exposed low socket, and both wall-crack patterns. Deliberately mount the rectangular mirror on the right side of the door instead of the left, with the same twenty-centimeter gap. Make the branching wall crack a printed repeated texture, the three desk cat scratches a flat sticker, the curtain slightly too stiff, and the baseboard too clean. In this frame the mirror reflection should behave normally: the reflected actor also has his head lowered in the matching pose.",
                    readable_text="No readable text. Do not create timestamps, REC labels, channel names, subtitles, verification messages, cue cards, platform controls, clothing logos, room labels, or watermarks. Any screen reflection or distant paper must remain too compressed to read.",
                    continuity="Use art_raven_room_reference.png as the master visual reference. Preserve every camera and furniture anchor except the intentional replica errors. The most important evidence is that the mirror is now on the right side of the door. This frame is the direct visual source for art_frame39.png; preserve the actor's lowered head, shoulder angle, chair position, mirror position, cold light, compression pattern, and all objects so frame 39 can differ in exactly one disturbing action.",
                    lighting="Cold-white studio light disguised as room light, weak monitor glow from behind the camera, slightly underexposed actor, uniform low-bitrate H.264 macroblocks, chroma smearing around the hoodie, subtle horizontal tearing near the lower third, soft focus, limited dynamic range, and a faint bluish cast. Keep the mirror reflection visible enough to compare but not unnaturally bright.",
                    exclusions="No empty chair, no actor looking at the camera, no raised head, no smiling face, no second physical person, no extra reflection, no supernatural distortion, no blood, no monster, no ghost, no face replacement effect, no obvious green screen, no visible film equipment, no mirror on the left side of the door, no altered camera angle, no cinematic close-up, no readable text, and no neon.",
                    output="Produce one edge-to-edge 1280x720 frame representing the moment immediately before frame 39, with no border, no player UI, no caption, and no watermark. Maintain a replica studio room that is plausible at first glance and unsettling only through precise inconsistencies.",
                    horror=True
                )
            },
            {
                "id": "art_frame39",
                "usage": "第 39 格 jumpscare",
                "size": "1280x720",
                "prompt": compose_art_prompt(
                    purpose="Create the single frame-39 psychological-horror image for the 47-second Raven livestream. Use GPT Image 2 image-reference or image-edit mode and upload art_raven_stream_base.png as the source image. This is not a new scene: it must be a near pixel-aligned continuation in which the room and foreground actor remain unchanged while the mirror reflection performs one impossible action.",
                    composition="Landscape 16:9 frame at exactly 1280 by 720 pixels. Preserve the source image's fixed webcam position, focal length, crop, perspective lines, centered chair, actor scale, door slightly right of center, rectangular mirror on the right side of the door, desk edge, curtain, wall cracks, socket, shelf, headset, and every background object's location. Do not zoom, crop, rotate, move the camera, or recenter the actor. The foreground actor keeps his head lowered, shoulders frozen, hands out of view near the desk, and body facing away from the camera exactly as in art_raven_stream_base.png.",
                    scene="Change only the mirror reflection. In the physical room the actor remains seated and looking down. Inside the right-side mirror, the reflected version of that same actor independently rotates only its head and upper neck until its face points directly toward the webcam. The reflected shoulders and torso still match the lowered foreground pose, creating an anatomically subtle contradiction. Keep the reflected face partly obscured by authentic compression blocks; show a neutral closed mouth and direct dark eye line, not a grin or monster face. All room props, lighting, cracks, and replica errors remain identical to the source.",
                    readable_text="No readable text. Preserve any indistinct source-image marks exactly, but do not add timestamps, REC labels, subtitles, warning messages, platform UI, channel names, watermarks, captions, symbols, or writing inside the mirror.",
                    continuity="art_raven_stream_base.png is mandatory as the image reference. Preserve it as closely as possible. The mirror must remain on the right side of the door. The foreground actor keeps his head lowered and must not react. The mirror reflection turns its head to face the webcam. This head-direction mismatch is the only narrative change; object motion, new people, lighting changes, altered posture, and room-layout differences would break the puzzle and must be prevented.",
                    lighting="Keep the exact cold-white light level, bluish cast, actor exposure, mirror brightness, H.264 macroblock pattern, chroma smearing, horizontal tear, soft focus, and low dynamic range of the source frame. Add only a small concentration of compression breakup around the reflected face so the impossible orientation is visible for less than half a second without becoming a detailed creature portrait.",
                    exclusions="No foreground actor looking up, no foreground eye contact, no actor turning around, no lunging figure, no face close-up, no extra person in the room, no second mirror, no mirror on the left side of the door, no hand against glass, no open mouth, no smile, no exaggerated white eyes, no demon, no ghost, no blood, no wounds, no body distortion, no jump toward the camera, no changed furniture, no changed cracks, no brighter light, no cinematic vignette, no text, and no neon.",
                    output="Return one edited 1280x720 frame with the same pixel dimensions and edge-to-edge framing as art_raven_stream_base.png. No border, no comparison layout, no arrows, no annotation, no player controls, no caption, and no watermark. The effect must remain restrained, realistic, and discoverable through frame-by-frame inspection.",
                    horror=True
                )
            },
            {
                "id": "art_studio_b",
                "usage": "棚 B 布景照片",
                "size": "1024x768",
                "prompt": compose_art_prompt(
                    purpose="Create a documentary evidence photograph taken from outside Studio B, revealing that the suspicious Raven bedroom was a constructed set inside a modest warehouse. The image should expose practical production methods and exact continuity mistakes, not present a glamorous professional film studio or supernatural location.",
                    composition="Landscape 4:3 image at 1024 by 768 pixels, photographed from just beyond the missing fourth wall with a phone held around chest height and angled slightly downward. Show the fake bedroom occupying the center and right two-thirds of the frame while the open warehouse floor, equipment, and unfinished wall backs remain visible along the left and upper edges. The view must include the centered black chair, back-wall door slightly right of center, and rectangular mirror mounted on the right side of the door.",
                    scene="Build the same replica studio room seen in art_raven_stream_base.png: narrow door, right-side mirror, printed repeated wall cracks, black chair, headset, desk, stiff curtain, exposed low socket prop, and sticker-like cat scratches. Reveal the construction outside the frame: unfinished fake walls with raw plywood backs and timber braces, two lighting stands with rectangular LED panels, a C-stand, black power cables crossing concrete, yellow-and-black floor tape, sandbags, a folding ladder, spare printed wall texture, a rolling wardrobe rack with a black hoodie, a small monitor showing an unreadable feed, and warehouse fluorescent fixtures overhead.",
                    readable_text="A simple white gaffer-tape sign on the outer wooden brace must display the exact Chinese text 棚 B clearly and only once. 棚 B is the only fully readable text. Keep equipment labels, monitor content, case markings, floor notes, and packaging turned away, covered, or too blurred to read.",
                    continuity="This photograph explains the source of art_raven_stream_base.png and art_frame39.png. The fake room must preserve their door, mirror on the right side of the door, chair, desk, curtain, cracks, and socket arrangement. The missing fourth wall and visible lighting stands should make clear that the webcam normally faces inward from the open side. Do not use the canonical real-room layout with the mirror on the left.",
                    lighting="Neutral warehouse fluorescent work light mixed with the set's cold-white LED panels, realistic phone-camera auto exposure, slight green cast in the concrete area, mild shadow noise behind the fake walls, ordinary depth of field, small highlight clipping on metal stands, and subtle JPEG compression. Keep construction details readable without dramatic spotlighting.",
                    exclusions="No actors or crew, no person hiding behind the set, no luxury soundstage, no cinema camera crane, no giant green screen, no supernatural figure, no blood, no abandoned-hospital decay, no cyberpunk neon, no futuristic equipment, no mirror on the left side of the door, no complete enclosed real bedroom, no polished promotional lighting, no random readable labels, no film title, and no watermark.",
                    output="Produce one realistic 1024x768 behind-the-scenes evidence photograph with no border, no caption, no arrows, no callouts, no collage, and no interface overlay. The image should reward close inspection by clearly connecting the studio construction to the streamed replica room."
                )
            },
        ],
        "complianceCheck": base_compliance(),
    }


def write_art_manifest(cases: list[dict]) -> None:
    rows = [
        "# 《零网寻踪》美术资产清单",
        "",
        "程序阶段仅显示深灰占位框、资产 ID 与尺寸。将正式 PNG 放入 `assets/art/<资产ID>.png`，Godot 导入后查看器会按同名资产自动替换。",
        f"普通资产统一风格后缀：`{ART_STYLE_SUFFIX}`",
        f"恐怖帧统一风格后缀：`{HORROR_STYLE_SUFFIX}`",
        "",
        "## GPT Image 2 使用顺序",
        "",
        "1. 普通独立资产可以直接复制对应代码块生成。",
        "2. 先生成 `art_raven_room_reference.png`。",
        "3. 生成 `art_raven_stream_base.png` 时，将 `art_raven_room_reference.png` 作为图像参考一并上传。",
        "4. 生成 `art_frame39.png` 时，使用图像编辑/参考模式上传 `art_raven_stream_base.png`，只改变镜中人的头部方向。",
        "5. 保存为对应资产 ID 的 PNG 文件名，不要添加版本号、中文后缀或额外扩展名。",
        "",
    ]
    seen: set[str] = set()
    for case in cases:
        for asset in case.get("artAssets", []):
            if asset["id"] in seen:
                continue
            seen.add(asset["id"])
            rows.extend([
                f"## `{asset['id']}`",
                "",
                f"- 文件：`assets/art/{asset['id']}.png`",
                f"- 用途：{asset['usage']}",
                f"- 尺寸：{asset['size']} px",
                "",
                "### GPT Image 2 Prompt",
                "",
                "```text",
                str(asset["prompt"]),
                "```",
                "",
            ])
    path = ROOT / "assets" / "art_manifest.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(rows) + "\n", encoding="utf-8")


def main() -> None:
    cases = [build_prologue(), build_case01(), build_case02()]
    filenames = ["prologue.json", "case_01_gate.json", "case_02_dead_streamer.json"]
    for filename, case in zip(filenames, cases):
        write_json(CASE_DIR / filename, case)
    write_json(CASE_DIR / "index.json", {"cases": [
        {"id": case["caseId"], "title": case["title"], "order": case["order"], "path": f"res://data/cases/{filename}"}
        for filename, case in zip(filenames, cases)
    ]})
    write_json(ROOT / "data" / "global" / "settings.json", {
        "schemaVersion": 1,
        "themes": ["mono", "green", "amber"],
        "horrorIntensities": ["full", "reduced", "off"],
        "hintThresholdSeconds": [360, 720, 1080],
        "designResolution": [1600, 900],
    })
    write_art_manifest(cases)


if __name__ == "__main__":
    main()
