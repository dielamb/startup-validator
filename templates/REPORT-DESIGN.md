# Report Design Language

Inspired by Mirofish-style document UI: narrow column, generous whitespace, content-first, no decorative chrome. The report is the deliverable — it must read well in any Markdown renderer (GitHub, Obsidian, Cursor, plain `cat`).

## Principles

1. **Content > chrome.** No decoration that does not carry information.
2. **One idea per section.** Numbered, scannable, never mixed.
3. **Verdict prominence.** Hero verdict at the top. Color-blind friendly (text label, not just color).
4. **Quote-style callouts.** Use `>` blockquotes for the core insights worth lingering on (core assumption, differentiation, MVP assumption).
5. **Tables where structured.** Three flaws, weekly plan, day-by-day MVP, competitor scoring.
6. **Code-style boxes** for the literal first message — communicates "this is something you copy-paste".

## Hierarchy

| Element | Use |
|---------|-----|
| `H1` | Report title only (one per document) |
| `H2` | `Section N · Topic` (top-level pipeline stages) |
| `H3` | Sub-blocks within a section |
| **Bold** | Field labels (Specific pain:, Real enemy:) |
| `> quote` | Insights worth a second read |
| Table | Structured data with ≥ 3 rows |
| `code` | Inline values (verdict, frequency labels) |
| Code block | The first message, anything copy-pasteable |

## Visual rhythm

- `---` between sections — visual breath, replaces decorative dividers
- `<div align="center">` for hero header + footer (works on GitHub, Obsidian, most renderers)
- Body left-aligned. No center-alignment for paragraphs.
- Source lines wrap at ~80 chars for readability of the raw markdown

## Verdict display

Hero verdict uses an H1-size label, no emoji, no color reliance:

| a1.verdict | Badge |
|------------|-------|
| `strong` | `GO` |
| `weak` | `WEAK` |
| `pivot` | `PIVOT` |

Followed by a single italic one-liner from `verdict_reasoning`.

## Anti-patterns

- No emoji in headers — readers scan for content, not vibes
- No placeholder text in skipped sections — use `[NOT VALIDATED — stage skipped]` callout
- No color-only signaling — always include text label
- No wide tables that break the column — split into multiple smaller tables
- No mermaid diagrams, no advanced HTML, no custom CSS — they only render in some targets

## Render targets

The template MUST render correctly in:

- GitHub (web)
- Obsidian
- Cursor / VS Code preview
- `cat report.md` (plain terminal — graceful degradation)

If a feature only renders in one target, it does not belong in the template.

## Skipped stages

If the orchestrator skips a stage (user halt-on-pivot, escalation), the corresponding section renders as:

```markdown
## Section N · Topic

> [NOT VALIDATED — stage skipped]
>
> Reason: <why>. Re-run `/validate-idea` to fill in.
```

This way the report is honest about its own gaps.

## Variable naming convention

Template tokens use `{{UPPER_SNAKE}}`. Single source: orchestrator at `.claude/commands/validate-idea.md` maintains the substitution map. When adding a new variable to the template, also add it to the orchestrator's variable list.
