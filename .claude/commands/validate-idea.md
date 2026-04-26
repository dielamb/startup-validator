---
description: Run the 5-step Startup Validator pipeline. Interactive intake → 5 specialist agents → final Markdown report at ~/Desktop/startup-validator-runs/.
allowed-tools: Read, Write, Bash, Agent
---

# /validate-idea

Orchestrate the multi-agent startup validator. End-to-end run produces a Markdown report at `~/Desktop/startup-validator-runs/<timestamp>-<slug>/report.md`. State lives in JSON files alongside the report; pipeline is resumable.

The user's prompt below this command should be the initial idea description (or empty — intake will ask for it).

---

## Step 0 — Initialize run directory

Resolve the repo root (the install symlink target's parent of parent):

```bash
SV_REPO="$(dirname "$(dirname "$(readlink -f "$HOME/.claude/commands/validate-idea.md")")")"
TS=$(date +%Y%m%d-%H%M%S)
SLUG=$(echo "${USER_PROMPT:-untitled}" | head -c 60 | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-' | sed 's/--*/-/g; s/^-//; s/-$//' | head -c 30)
RUN_DIR="$HOME/Desktop/startup-validator-runs/${TS}-${SLUG:-untitled}"
mkdir -p "$RUN_DIR"
echo "Run dir: $RUN_DIR"
echo "Repo:    $SV_REPO"
```

Save `$RUN_DIR` and `$SV_REPO` for all later steps. Tell the user the run dir.

---

## Step 1 — Intake (interactive)

Spawn `sv-intake` (subagent_type: `intake`, prefixed by install). Pass the user's initial prompt and `<RUN_DIR>` in the agent prompt.

Intake will conduct multi-turn Q&A in the conversation. Continue passing user replies into intake until it returns:

- `INTAKE_COMPLETE` → proceed to Step 2
- `INTAKE_STALLED` → ask user verbatim: `intake unable to reach 95% confidence — proceed anyway? (y/N)`. If `y`, proceed. If `N`, stop.

---

## Step 2 — A1 Pressure Test

Spawn `sv-pressure-test`. Pass `<RUN_DIR>`. Wait for `A1_COMPLETE`.

Then critic check:

Spawn `sv-critic` with stage=`a1`, `<RUN_DIR>`, `retry_count=0`.

- `pass` → Step 3
- `retry` → re-spawn A1 with critic's `<RUN_DIR>/critic-a1.json` issues; increment retry_count
- After 2 retries → ask user: `A1 unable to satisfy quality gate. Skip and continue? (y/N)`

### Halt-on-pivot

If `a1.verdict == "pivot"`:

1. HALT pipeline.
2. Print the three fatal flaws + verdict_reasoning to the user.
3. Ask verbatim: `verdict=PIVOT. Continue with remaining agents anyway? (y/N)`
4. `y` → continue to Step 3.
5. `N` → skip to Step 7 (aggregate report with only intake + a1).

---

## Step 3 — A2 + A3 in parallel

Spawn `sv-problem-validator` AND `sv-competitor-mapper` in ONE message (two parallel Agent calls). Both depend only on intake + a1.

Wait for both `A2_COMPLETE` and `A3_COMPLETE`.

Critic check on each (parallel calls). Same retry logic as Step 2.

### Cross-stage feedback loop

If `a2.verdict == "vitamin"` AND `a1.verdict == "strong"`:

1. Print: `A2 says vitamin, A1 said strong — re-running A1 with A2 evidence (1-time loop).`
2. Re-spawn A1 with the A2 contradiction note. Update a1.json.
3. Re-run critic on the new a1. Cap: 1 cross-stage loop, no recursion.

If `a3` rejected by critic (e.g. differentiation contains only "better/cheaper") → re-spawn A3 (same retry counter as Step 2).

---

## Step 4 — A4 Traction Planner

Spawn `sv-traction-planner`. Pass `<RUN_DIR>`. Critic check. Retry max 2.

---

## Step 5 — A5 MVP Architect

Spawn `sv-mvp-architect`. Pass `<RUN_DIR>`. Critic check. Retry max 2.

---

## Step 6 — Aggregate report

Read all stage JSONs from `<RUN_DIR>/`. Read template from `$SV_REPO/templates/report-template.md`.

Substitute every `{{VARIABLE}}` token with the corresponding JSON field. For arrays (flaws, weekly_plan, day_by_day_plan), render as Markdown table rows.

Variables to fill (full list in `$SV_REPO/templates/report-template.md`):

- Idea title, date, run id
- Verdict badge (`GO` if a1.verdict=strong, `WEAK` if weak, `PIVOT` if pivot), one-liner
- Core assumption
- Three fatal flaws (table)
- Painkiller/vitamin verdict, specific pain, early adopter
- 5 discovery questions
- Validation criteria
- Real enemy, current behavior, direct/indirect competitor tables
- Differentiation, switch trigger
- Where first 10, manual outreach, first message, success criteria
- 4-week milestone plan (table)
- MVP min features, cut list, behavioral tests
- 14-day plan (table)
- Top 3 next actions (synthesize from a4 + a5)

If a stage was skipped → fill its sections with `[NOT VALIDATED — stage skipped]` callout.

Write final report to `<RUN_DIR>/report.md`.

---

## Step 7 — Output

Show the user:

```
report:  <RUN_DIR>/report.md
verdict: <verdict from a1, or SKIPPED>
open:    open <RUN_DIR>/report.md
```

Print a 2-3 sentence summary of the most important takeaways from a1 and a5.

---

## Failure handling summary

| Failure | Action |
|---------|--------|
| Agent JSON malformed | Critic returns retry with parse error in issues |
| Same stage 2 retries | Escalate: ask user to skip stage |
| Skipped stage | Mark `[NOT VALIDATED]` in report |
| A1 verdict=pivot | Halt + ask user to continue |
| A2 vitamin contradicts A1 strong | 1 re-run of A1 with note |
| A3 weak differentiation | Retry A3 (same counter) |
| Bash command fails | Surface error, do not silently continue |

---

## Resume

If the user re-runs `/validate-idea` with an existing `RUN_DIR` (provided as arg or detected via slug match in `~/Desktop/startup-validator-runs/`), each stage checks for an existing JSON. If present and critic-`<stage>`.json shows `pass`, skip the stage. Saves cost on re-runs.
