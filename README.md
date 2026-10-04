# Lark Coding Agent Bridge

把飞书变成你本地 AI 编程 Agent 的远程遥控器。

在飞书里发一条消息，就能指挥你**自己电脑上**的 Codex CLI 或 Claude Code 读代码、改文件、跑命令。人在外面、手上只有手机时，依然能让本地 Agent 干活。

[完整中文文档](./README.zh.md) · [English](#english) · MIT License

---

## 这是什么

常见的 AI 编程工具都要求你坐在电脑前。这个项目在**飞书**和**你本机的 CLI Agent** 之间架了一座桥：

```
飞书 App（手机 / 电脑）
      ↕  WebSocket 长连接
  Bridge（跑在你自己的机器上）
      ↕  子进程 + 流式 stdout
Codex CLI  /  Claude Code
      ↕
   你的本地代码仓库
```

Bridge 是一个跑在你机器上的常驻进程。它收飞书消息、转给本地 Agent、再把 Agent 的输出实时写回飞书卡片。**代码和凭据始终在你自己的电脑上**，不经过任何第三方服务器。

## 能干嘛

| 能力 | 说明 |
|---|---|
| **飞书里直接对话** | 私聊发消息，或在群里 `@机器人`，任务转给本机 Agent |
| **流式卡片** | Agent 的文本回复和工具调用实时更新在同一张卡片上，不用等它跑完 |
| **思考过程可见** | 可选的 COT 过程消息，展示 Agent 每一步在做什么、调了哪些工具 |
| **会话隔离** | 每个聊天 / 话题 / 文档评论有独立会话，多个项目同时推进也不串 |
| **多工作区** | `/cd` 切项目目录，`/ws` 保存和复用常用项目 |
| **图片和文件** | 直接把截图、日志、文档发给机器人，Bridge 下载到本地交给 Agent |
| **队列与中断** | 连发的消息会合并；任务跑一半可以用 `/stop` 打断 |
| **权限控制** | 默认只有你本人能用，可按需邀请同事或开放指定群 |
| **后台常驻** | 注册成 launchd / systemd / 计划任务，开机自启 |
| **多 Profile** | 可以同时跑一个 Claude bot 和一个 Codex bot，互不干扰 |

## 适合谁

- 出门在外，想远程让家里 / 公司的电脑改代码
- 想把本地 Agent 的能力分享给团队同事，但不想把代码传到云端
- 不想开网页版，习惯在飞书里处理所有事情

## 快速开始

### 前置要求

1. **Node.js >= 20.12.0**
2. 至少一个已登录的本地 Agent：
   - Codex CLI — `npm install -g @openai/codex && codex login`
   - Claude Code — `npm install -g @anthropic-ai/claude-code`
3. 一个飞书 / Lark 账号（首次启动的扫码向导会帮你创建 PersonalAgent 应用）

### 一键启动

```bash
git clone https://github.com/a15242408085-bot/lark-coding-agent-bridge.git
cd lark-coding-agent-bridge
chmod +x run.sh
./run.sh
```

`run.sh` 会检测 Node 和 Agent、装依赖、构建，然后前台启动。

### 或者用 npm 全局安装

```bash
npm i -g lark-channel-bridge
lark-channel-bridge run
```

首次运行会在终端渲染一个二维码：用飞书 App 扫一下 → 选择或创建 PersonalAgent 应用 → 按提示绑定。配置写入 `~/.lark-channel/config.json`，之后不用再扫。

### 转到后台常驻

确认机器人能正常收发消息后，`Ctrl-C` 停掉前台，再注册成系统服务：

```bash
lark-channel-bridge start     # 安装并启动后台服务
lark-channel-bridge status    # 看运行状态
lark-channel-bridge stop      # 停止
```

> 服务层命令需要先全局安装，不能用 `npx`——daemon 会记录 CLI 的绝对路径，npx 的临时缓存被清掉后服务就起不来了。

## 在飞书里怎么用

私聊直接发消息，群里需要 `@机器人`。常用斜杠命令：

| 命令 | 作用 |
|---|---|
| `/new` | 开一个新会话 |
| `/cd <path>` | 切换工作目录并重置会话 |
| `/ws save <name>` | 把当前目录存成命名工作区 |
| `/ws use <name>` | 切换到已保存的工作区 |
| `/status` | 查看当前 profile、Agent、工作目录、会话状态 |
| `/config` | 调整展示偏好、访问控制 |
| `/stop` | 中断当前正在跑的任务 |
| `/invite user @某人` | 允许某人私聊使用 |
| `/invite group` | 允许当前群使用 |
| `/help` | 查看全部命令 |

完整命令表见 [README.zh.md](./README.zh.md#飞书内斜杠命令)。

## 权限与安全

**默认是私有的**：开箱即用时只有你（创建应用的人）能用，其他人的消息会被静默忽略，机器人连"你没权限"都不会回——免得暴露自己的存在。

要开放给别人，用 `/invite user @某人` 或在群里发 `/invite group`。详见[访问控制](./README.zh.md#访问控制)。

几点值得注意：

- Bridge 给 Agent 设置的工作目录**不是沙箱**。Agent 实际能碰哪些文件，取决于本机 Agent 进程自身的权限模式（`full` / `workspace` / `read-only`，见[权限模式](./README.zh.md#权限模式)）。
- 默认**不上报任何遥测数据**，没有指标或日志离开你的机器。
- 应用凭据加密存放在 `~/.lark-channel/profiles/<profile>/secrets.enc`。

## 本地开发

```bash
pnpm install
pnpm test        # unit + integration + process-level 测试
pnpm typecheck
pnpm build       # 构建 web 控制台 + CLI bundle
```

技术栈：TypeScript、tsup、Vitest；本地 Web 控制台用 React + Tailwind，经 `vite-plugin-singlefile` 打成单个 HTML 内联进 CLI，所以离线也能用。

## 文档

- [完整中文文档](./README.zh.md) — 全部命令、配置项、数据目录、FAQ
- [飞书使用说明](https://larkcommunity.feishu.cn/docx/OaRIdFIRFoLM3xxTmKwcetHqn5e)

## 致谢

本项目基于 [zarazhangrui/lark-coding-agent-bridge](https://github.com/zarazhangrui/lark-coding-agent-bridge)（npm 包名 `lark-channel-bridge`），遵循 MIT 协议。感谢原作者和所有贡献者。

## English

**Lark Coding Agent Bridge** turns Feishu/Lark into a remote control for the AI coding agent running on your own machine.

Send a message in Feishu and your local **Codex CLI** or **Claude Code** reads your code, edits files, and runs commands — with the agent's reasoning and tool calls streaming back into a live Feishu card. Your code and credentials never leave your computer.

Highlights: streaming cards, chain-of-thought process messages, per-chat session isolation, multi-workspace switching, image/file passthrough, built-in access control (private by default), and background daemon support on macOS, Linux, and Windows.

```bash
npm i -g lark-channel-bridge
lark-channel-bridge run    # scan the QR code with Feishu, then you're set
```

See [README.zh.md](./README.zh.md) for full documentation.

## License

[MIT](./LICENSE)
