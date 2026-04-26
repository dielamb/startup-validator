# Startup Validator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Lint](https://github.com/dielamb/startup-validator/actions/workflows/lint.yml/badge.svg)](https://github.com/dielamb/startup-validator/actions/workflows/lint.yml)
[![Built with Claude Code](https://img.shields.io/badge/built_with-Claude_Code-7C3AED)](https://docs.claude.com/en/docs/claude-code)

Multi-agent system that pressure-tests startup ideas via a Paul Graham-style 5-step pipeline. Built as Claude Code subagents — install once, invoke globally with `/validate-idea`.

## What it does

You describe an idea → an interactive intake agent gathers context until confidence ≥ 95% → 5 specialist agents run sequentially (with parallel A2/A3) → comprehensive Markdown report.

| # | Agent | Output |
|---|-------|--------|
| 0 | Intake | Interactive Q&A (loops until ≥ 95% confidence) |
| 1 | Pressure Test | Core assumption, 3 fatal flaws, brutal verdict |
| 2 | Problem Validator | Pain, early adopter, 5 discovery Qs, painkiller verdict |
| 3 | Competitor Mapper | Real enemy, direct/indirect competitors, differentiation |
| 4 | Traction Planner | First 10 customers, outreach, weekly plan |
| 5 | MVP Architect | Min features, cut list, 14-day launch plan |

A `critic` agent runs after each stage for schema + cross-stage consistency. Failures trigger up to 2 retries before escalating.

## Install

```bash
git clone https://github.com/dielamb/startup-validator.git
cd startup-validator
./install.sh
```

Symlinks agents and the slash command into `~/.claude/`. Edits in the repo apply immediately. The command is then available in **any** Claude Code session, anywhere on disk.

## Use

```
/validate-idea
```

Then describe your idea. Intake asks follow-ups. Once context locks in, pipeline runs end-to-end. Final report:

```
~/Desktop/startup-validator-runs/<timestamp>-<slug>/report.md
```

All intermediate JSON outputs sit beside the report.

## Halt logic

- A1 verdict = `pivot` → pipeline halts, asks user `continue with remaining agents anyway? (y/N)`
- A2 verdict = `vitamin` AND A1 verdict = `strong` → re-runs A1 with A2 evidence (max 1 loop)
- A3 differentiation rejected → re-runs A3 (max 2 retries)
- Any stage retry > 2 → escalates to user, ask whether to skip

## Resume

State lives entirely in `<RUN_DIR>/` JSON files. Re-running `/validate-idea` with an existing RUN_DIR skips completed stages.

## Customizing

- Agents: `.claude/agents/*.md` (frontmatter + system prompt)
- Orchestrator: `.claude/commands/validate-idea.md`
- Report layout: `templates/report-template.md`
- Design rules: `templates/REPORT-DESIGN.md`

Symlinks pick up changes without reinstall.

## Uninstall

```bash
./install.sh --uninstall
```

## License

MIT.
