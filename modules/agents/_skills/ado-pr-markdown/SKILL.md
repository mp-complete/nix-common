---
name: ado-pr-markdown
description: Use when authoring or editing an Azure DevOps pull request description (or PR comment) and you need to know which Markdown features ADO actually supports, how to link work items / other PRs / users, or how to structure a clean PR write-up. Triggers on "ADO PR description", "Azure DevOps pull request markdown", "link work item from PR", "AB# / !PR# syntax", "collapsible section in ADO PR", "PR template".
metadata:
  author: miles
  version: "1.0"
  source: https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance
---

# Azure DevOps PR Description Markdown

Azure DevOps PR descriptions and PR comments accept a **subset of GitHub-flavored Markdown plus a few ADO-specific extensions**. Some features that work in ADO wikis (mermaid, math, attachments of arbitrary file types, `<br/>` in tables) do **not** work in PR descriptions. This skill describes only what works in PRs.

## When to use this skill

Load this skill when you are:

- Writing a PR description in Azure DevOps from scratch.
- Translating a GitHub-style PR body to ADO syntax.
- Adding work-item / cross-PR / user-mention links and unsure of the syntax.
- Adding a collapsible section, table, checklist, or suggestion block.
- Picking a PR template for a feature / fix / chore / revert.

Do **not** use this skill for ADO wiki pages, README files, or boards — those support a wider feature set; defer to the official docs.

## Procedure

When asked to draft an ADO PR description:

1. **Confirm the change set.** Read the diff (or ask for it) so the description summarizes the actual change, not guessed intent.
2. **Pick a template** from [`references/templates.md`](references/templates.md) that matches the change kind (feature, fix, refactor, revert, chore).
3. **Fill in the summary first**, then any context/why, then the change list.
4. **Add links** using the syntax in [`references/linking.md`](references/linking.md). At minimum, link any work items the change implements or fixes.
5. **Apply formatting** using only features in the support matrix below; if you need details, consult [`references/syntax.md`](references/syntax.md).
6. **Sanity-check**:
   - Soft line breaks need **two trailing spaces** before `\n`. Without them ADO joins lines into one paragraph.
   - Tables must not contain `<br/>` (works in wiki, not in PR).
   - Mermaid code blocks render as plain code; export to image instead.
   - Don't drop raw `#1234` into prose where you don't want a work-item link — escape with `\#` or use a code span.

## Quick support matrix (PR description / PR comment only)

| Feature                                            | Works in PR? | Notes                                                    |
| -------------------------------------------------- | :----------: | -------------------------------------------------------- |
| Headers `#`..`######`                              | ✅           |                                                          |
| Bold `**`, italics `*`/`_`, strikethrough `~~`     | ✅           |                                                          |
| Block quotes `>`, nested `>>`                      | ✅           |                                                          |
| Horizontal rule `---`                              | ✅           | Needs a blank line above.                                |
| Ordered / unordered / nested lists                 | ✅           |                                                          |
| Task list `- [ ]` / `- [x]`                        | ✅           | Reviewers can tick boxes in the rendered view.           |
| Tables `\| col \| col \|`                          | ✅           | No `<br/>` for in-cell newlines. Escape `\|`.            |
| Fenced code blocks ` ``` `                         | ✅           | Language tag enables syntax highlighting.                |
| Inline code `` ` ``                                | ✅           |                                                          |
| `suggestion` code block (in comments)              | ✅ (comment) | Renders as one-click apply diff.                         |
| Links `[text](url)` and bare URLs                  | ✅           | `http(s)://` auto-links.                                 |
| Images `![alt](url)`                               | ✅           | Paste / drag also works; external host must send CORS.   |
| Image sizing ` =WxH`                               | ✅           |                                                          |
| Emoji `:smile:`                                    | ✅           | GitHub set; no custom emoji like `:bowtie:`.             |
| Soft line break (2 spaces + `\n`)                  | ✅           | **Required**; bare newlines do not break lines.          |
| Work-item link `#123` / `AB#123`                   | ✅           | Triggers picker on `#` in the web editor.                |
| Cross-PR link `!456`                               | ✅           | Project-wide.                                            |
| `@user` mention                                    | ✅           | Use the picker; raw `@name` won't notify.                |
| Collapsible `<details><summary>…`                  | ✅           | HTML allowed; keep a blank line before nested markdown.  |
| Mermaid                                            | ❌           | Code block only — no rendering. Use an image.            |
| KaTeX math `$…$`                                   | ❌           | Wiki only.                                               |
| Attachments (arbitrary files)                      | ⚠️           | Limited set; e.g. `.msg` not supported. Images always OK.|
| Underline                                          | ❌           | No syntax; `<u>` only in wiki.                           |

## Minimal example

```markdown
## Summary

Replace the legacy capacity API with the v2 endpoint so workspaces stop hitting
the deprecated `/cap/v1` route.

## Why

`/cap/v1` is scheduled for removal in the next service ring (#48213). The new
endpoint returns the same payload shape plus a `region` field we now surface in
the workspace switcher.

## Changes

- Swap `CapacityClient` to call `/cap/v2`.
- Map the new `region` field through to `WorkspaceSummary`.
- Update fixtures and contract tests.

## Linked work

- Implements AB#48199
- Fixes #48213

## Reviewer notes

<details>
<summary>Local repro steps</summary>

1. `pnpm i && pnpm dev`
2. Open <http://localhost:3000/workspaces>
3. Confirm the region badge renders for shared-capacity items.

</details>

cc !1742  <!-- prior PR that introduced CapacityClient -->
```

## References

- [`references/syntax.md`](references/syntax.md) — full per-feature syntax with copy-pasteable examples.
- [`references/linking.md`](references/linking.md) — work items, cross-PR refs, user mentions, commits.
- [`references/templates.md`](references/templates.md) — ready-to-fill PR templates by change kind.
- Upstream docs: <https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance>
