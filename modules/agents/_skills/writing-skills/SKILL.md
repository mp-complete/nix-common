---
name: writing-skills
description: Use when the user wants to author, scaffold, edit, validate, or restructure an agent skill — including creating SKILL.md files, designing skill folder layouts, writing frontmatter, splitting content into references/scripts/assets, or improving an existing skill's triggers and progressive disclosure.
metadata:
  author: miles
  version: "1.0"
  spec: https://agentskills.io/specification
---

# Writing Agent Skills

This skill explains how to author a high-quality Agent Skill that conforms
to the [agentskills.io specification](https://agentskills.io/specification).

A **skill** is a folder containing a `SKILL.md` file and optional
`scripts/`, `references/`, and `assets/` subdirectories. Agents load skills
progressively: the `description` is always visible, the `SKILL.md` body is
loaded when the description matches, and supporting files are loaded only
when the agent actually needs them.

## When to use this skill

Load this skill whenever you need to:

- Create a new skill from scratch.
- Add metadata or frontmatter to an existing `SKILL.md`.
- Decide what belongs in `SKILL.md` vs. `references/` vs. `scripts/`.
- Audit or fix a skill that isn't being triggered correctly.
- Validate a skill against the spec.

## Authoring procedure

Follow these steps in order:

### 1. Pick a name

- Lowercase `a-z`, digits, and single hyphens only.
- Max 64 characters.
- No leading/trailing hyphens, no `--`.
- The folder name **must match** the `name` frontmatter field exactly.
- Examples: `pdf-processing`, `code-review`, `writing-skills`.
- Counter-examples: `PDF-Processing`, `-pdf`, `pdf--processing`.

### 2. Create the folder layout

```
my-skill/
├── SKILL.md          # required
├── scripts/          # optional: executable helpers
├── references/       # optional: docs loaded on demand
└── assets/           # optional: templates, schemas, images
```

Only `SKILL.md` is required. Add subdirectories only when you need them.

### 3. Write the frontmatter

`SKILL.md` must start with a YAML frontmatter block. Required fields:

| Field         | Required | Limits                          |
| ------------- | -------- | ------------------------------- |
| `name`        | yes      | ≤ 64 chars, matches folder name |
| `description` | yes      | ≤ 1024 chars                    |

Optional fields:

| Field           | Notes                                                  |
| --------------- | ------------------------------------------------------ |
| `license`       | Name or path to bundled license file.                  |
| `compatibility` | ≤ 500 chars; runtime/OS/package requirements.          |
| `metadata`      | Arbitrary key/value map (author, version, links, …).   |
| `allowed-tools` | Space-separated pre-approved tools (experimental).     |

The `description` is the single most important field — it is the *only*
thing the agent sees at discovery time. Write it so it answers two
questions in one sentence:

1. **What** does the skill do?
2. **When** should the agent load it?

Good:

> Use when the user wants to extract text or tables from PDFs, fill PDF
> forms, or merge multiple PDFs.

Bad (no trigger):

> PDF utilities.

### 4. Write the body

The body is plain Markdown. Aim for:

- **Under 500 lines / ~5000 tokens.** If you need more, move content into
  `references/` and link to it.
- **Imperative, step-by-step instructions.** Tell the agent what to do, in
  order, not what the skill "is".
- **Concrete examples.** Show inputs, outputs, and edge cases.
- **Explicit references.** Use relative links (`references/FORMS.md`,
  `scripts/extract.py`) so the agent knows what to load next.

Recommended sections:

1. One-line summary.
2. "When to use this skill" — restate triggers in detail.
3. Procedure — numbered steps the agent should follow.
4. Examples — at least one full input → output trace.
5. References — list of supporting files and what each contains.

### 5. Use progressive disclosure

Skills load in three stages. Optimize each stage:

| Stage      | Tokens   | What loads                | Optimize by…                                  |
| ---------- | -------- | ------------------------- | --------------------------------------------- |
| Discovery  | ~100     | `name` + `description`    | Crisp trigger sentence.                       |
| Activation | < 5000   | full `SKILL.md` body      | Keep body short; link to references.          |
| Execution  | as-needed | scripts/refs/assets       | Split references by topic, one file per area. |

A reference file should be small and focused — agents load them one at a
time. Prefer `references/forms.md` + `references/tables.md` over a single
`references/everything.md`.

### 6. Validate

If you have the `skills-ref` CLI installed, run:

```bash
skills-ref validate ./my-skill
```

Otherwise, manually check:

- [ ] Folder name matches `name` frontmatter exactly.
- [ ] `name` only uses `[a-z0-9-]` and ≤ 64 chars.
- [ ] `description` is ≤ 1024 chars and answers *what* + *when*.
- [ ] `SKILL.md` body is ≤ ~500 lines.
- [ ] All relative paths in the body point to files that exist.
- [ ] Scripts declare their dependencies (shebang, `compatibility`).

## Minimal skeleton

Use this as a starting point when scaffolding a new skill:

```markdown
---
name: my-skill
description: Use when the user wants to <task>. Triggers on <keywords/intents>.
---

# <Skill title>

## When to use this skill

- <Trigger 1>
- <Trigger 2>

## Procedure

1. <First step>
2. <Second step>

## References

- [`references/details.md`](references/details.md) — <what's in it>
```

## Full example frontmatter

```yaml
---
name: pdf-processing
description: Extracts text and tables from PDFs, fills PDF forms, and merges multiple PDFs. Use when the user mentions PDFs, forms, document extraction, or asks to combine documents.
license: Apache-2.0
compatibility: Requires Python 3.14+ and uv
metadata:
  author: example-org
  version: "1.0"
allowed-tools: Bash(git:*) Bash(jq:*) Read
---
```

## Common mistakes

- **Description without a trigger.** The agent can't tell when to load it.
- **Folder/name mismatch.** Loaders reject the skill.
- **Monolithic SKILL.md.** Blows out the activation budget; split into
  `references/`.
- **Hidden dependencies in scripts.** Always document required tools and
  versions in `compatibility` or in a comment header.
- **Vague instructions.** Write imperatives ("Run `scripts/extract.py`"),
  not descriptions ("This skill can extract text").

## References

- Specification: https://agentskills.io/specification
- Overview: https://agentskills.io/
- Machine-readable summary: https://agentskills.io/llms.txt
