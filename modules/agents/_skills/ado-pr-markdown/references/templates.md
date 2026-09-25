# ADO PR Description Templates

Pick the template that matches the change kind, then fill in or delete sections. All templates use only PR-supported syntax (see `syntax.md`).

Conventions used below:

- `AB#123` for work items, `!456` for prior PRs — see `linking.md`.
- H2 (`##`) is the top heading level; the PR title is H1.
- The "Linked work" block is the place reviewers look for work-item references.

---

## 1. Feature

```markdown
## Summary

<one paragraph: what user-visible capability this adds and to whom>

## Why

<problem statement; link to the discovery doc / spec if it exists>

## Changes

- <bullet per logical change, not per file>
- <call out new public API surface here>
- <call out new dependencies>

## Validation

- [ ] Unit tests
- [ ] Integration / contract tests
- [ ] Manual repro steps below
- [ ] Telemetry / dashboards updated

<details>
<summary>Manual repro</summary>

1. <step>
2. <step>

</details>

## Risks & rollout

- **Blast radius:** <which surfaces / tenants>
- **Rollback:** <revert PR? feature flag? config toggle?>
- **Flag:** `<flag name>` — default `<off|on>`.

## Linked work

- Implements AB#<id>
```

---

## 2. Bug fix

```markdown
## Summary

Fixes <one-line description of the broken behavior>.

## Root cause

<2–4 sentences. What was wrong and why>

## Fix

<what this PR changes to address the root cause; keep it tight>

## Validation

- [ ] Reproduced the bug on `main` before the fix
- [ ] Regression test added (`<test name>`)
- [ ] Verified the fix locally
- [ ] No new warnings / lint failures

## Linked work

- Fixes AB#<id>
- Related: #<id>
```

---

## 3. Refactor / no behavior change

```markdown
## Summary

Refactor <area> with no intended behavior change.

## Motivation

<why now: pain point, blocking work, tech-debt commitment>

## Changes

- <bullet per refactor move>
- **No behavior change** — all existing tests pass without modification.

## How to review

- Start with `<entry file>` → `<next file>`.
- The diff in `<file>` is mechanical (rename / move); skim it.
- The interesting logic is in `<file>` lines `<n>–<m>`.

## Linked work

- Related: AB#<id>
```

---

## 4. Revert

```markdown
## Summary

Reverts !<prior PR id> (<short title>).

## Reason for revert

<what broke / why we're rolling back>

## Plan to re-land

- <what needs to change before re-landing>
- Tracking: AB#<id>

## Linked work

- Reverts !<prior PR id>
- Related: #<incident id>
```

---

## 5. Chore / dependency bump / config

```markdown
## Summary

<one line>

## Changes

- <bullet per change>

## Verification

- [ ] Builds green
- [ ] No runtime impact expected

## Linked work

- AB#<id>  <!-- optional -->
```

---

## 6. Draft / WIP

```markdown
> **Draft** — opening for early feedback. Not ready to merge.

## What this is

<one-paragraph intent>

## What's done

- <bullet>

## What's left

- [ ] <task>
- [ ] <task>

## Specific feedback I want

1. <question>
2. <question>

## Linked work

- Implements AB#<id>
```

---

## Snippets you can drop into any template

### Screenshot row

```markdown
| Before | After |
| ------ | ----- |
| ![before](./before.png =400x) | ![after](./after.png =400x) |
```

### Collapsible logs

```markdown
<details>
<summary>Failure log</summary>

```text
<paste log here>
```

</details>
```

### Reviewer checklist (for the author to self-tick before requesting review)

```markdown
- [ ] PR title follows `<area>: <imperative summary>`
- [ ] Linked the implementing work item
- [ ] Tests added / updated
- [ ] No accidental commits (binaries, secrets, generated files)
- [ ] Self-reviewed the diff
```
