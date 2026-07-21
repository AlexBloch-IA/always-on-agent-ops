# Always On Agent Ops

> Keep an OpenClaw agent running 24/7 — loopback gateway blocks inbound webhooks, OAuth expires silently, strict config. Use when crons stop firing. Trigger on "agent went quiet".

[![License: MIT-0](https://img.shields.io/badge/License-MIT--0-blue.svg)](https://opensource.org/licenses/MIT-0)
[![ClawHub](https://img.shields.io/badge/ClawHub-Published-orange)](https://clawhub.ai/alexbloch-ia/skills/always-on-agent-ops)
[![Version](https://img.shields.io/badge/version-1.1.0-green)](https://clawhub.ai/alexbloch-ia/skills/always-on-agent-ops)

A Claude Code / [OpenClaw](https://openclaw.ai) skill, published on [ClawHub](https://clawhub.ai/alexbloch-ia/skills/always-on-agent-ops). Portable operating doctrine — drop it into an agent's skills directory and follow it.

---

## What the doctrine covers

- The loopback cascade
- Config as contract
- Auth and runtime are two orthogonal axes
- Failure #1: OAuth dies silently
- Cron layer
- Preflight layer
- Gotchas
- Ops checklist

The full, load-bearing detail lives in [`SKILL.md`](./SKILL.md).

---

## Install

### Via ClawHub (recommended)

👉 **<https://clawhub.ai/alexbloch-ia/skills/always-on-agent-ops>**

```bash
clawhub install always-on-agent-ops
# or, from an OpenClaw agent:
openclaw skills install @alexbloch-ia/always-on-agent-ops
```

### Via this repository (manual)

```bash
git clone https://github.com/AlexBloch-IA/always-on-agent-ops.git
cd always-on-agent-ops
./install.sh
```

The script copies the full skill payload into every supported stack it finds:

- `~/.claude/skills/always-on-agent-ops/` (Claude Code)
- `~/.openclaw/skills/always-on-agent-ops/` (OpenClaw)

### Manual copy

```bash
mkdir -p ~/.claude/skills/always-on-agent-ops
cp -R SKILL.md ~/.claude/skills/always-on-agent-ops/   # plus scripts/, references/, templates/… if present
```

---

## Repository structure

```
always-on-agent-ops/
├── SKILL.md
├── scripts/
├── README.md
├── LICENSE
└── install.sh
```

---

## License

Released under **MIT-0** (MIT No Attribution). Use, fork, adapt, redistribute — no attribution required.

---

## Author

[Alexandre Bloch](https://github.com/AlexBloch-IA) — founder of [OpenClaw](https://openclaw.ai).
Published on [ClawHub](https://clawhub.ai/alexbloch-ia).
