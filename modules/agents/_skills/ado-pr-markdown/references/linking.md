# ADO PR Markdown — Linking & Cross-References

ADO recognizes several shorthand patterns inside PR descriptions and comments and rewrites them into rich links. Get these right and the PR's "Linked work", "Linked pull requests", and notification lists populate themselves.

## Work items

| Syntax     | Effect                                                                 |
| ---------- | ---------------------------------------------------------------------- |
| `#123`     | Links to work item 123 in the **current project**. Typing `#` in the web editor opens a picker. |
| `AB#123`   | Same target, but uses the `Azure Boards#` shorthand. Required when the PR description is being mirrored from GitHub (Azure Boards GitHub integration); also more robust because it never collides with hex colors or other `#` uses. |

Both forms add the item to the PR's **Linked work items** section after save.

**Transition keywords.** ADO recognises GitHub-style keywords (`fixes`, `closes`, `resolves`) when combined with `#`/`AB#`, e.g. `Fixes AB#1234`. They link the work item and, when the PR completes, can auto-transition the item if the project's PR completion options have "Transition work items" enabled.

**Avoid accidental links.** Hex colors (`#ff00aa`), C# preprocessor (`#region`), CSS IDs, etc. trigger the picker too. Escape with a backslash (`\#ff00aa`) or wrap in backticks (`` `#region` ``) when you want the literal text.

## Other pull requests

```markdown
!1742
```

Renders as a clickable link to PR 1742 in the **current project** (not necessarily the current repo — `!` is project-scoped). Use it for "supersedes !1700", "follow-up to !1742", etc.

There is no shorthand for PRs in a different ADO project — paste the full URL instead:

```markdown
[fabrikam!998](https://dev.azure.com/contoso/Fabrikam/_git/web/pullrequest/998)
```

## User mentions

In the **web editor**, type `@` and pick the user from the suggestion popover. ADO replaces the text with a mention token that:

- Renders as a styled chip.
- Sends the user a notification.

Pasting raw `@firstname.lastname` from another tool does **not** notify anyone; it renders as plain text. If you're generating a PR description programmatically (CLI, automation, AI), prefer:

```markdown
cc: <firstname.lastname@contoso.com>
```

…and let the human author re-type the `@` mentions in the web UI so the picker fires.

Group / team mentions follow the same rule — they must be inserted through the picker.

## Commits

Plain commit SHAs (full 40-char or abbreviated 7+) auto-link to the commit in the same repo when they appear in PR descriptions and comments:

```markdown
Reverts a1b2c3d due to the regression noted in #48213.
```

If you want an explicit hyperlink with custom display text:

```markdown
[partial revert of a1b2c3d](https://dev.azure.com/contoso/Fabrikam/_git/web/commit/a1b2c3d4e5f6...)
```

## Branches and files

ADO does **not** rewrite branch names or file paths into links automatically. Use a normal markdown link with the full URL:

```markdown
[release/24.10](https://dev.azure.com/contoso/Fabrikam/_git/web?version=GBrelease%2F24.10)
[`src/capacity/client.ts`](https://dev.azure.com/contoso/Fabrikam/_git/web?path=/src/capacity/client.ts)
```

URL-encode `/` as `%2F` inside the `version=GB…` query parameter (branch name segments).

## Builds

No shorthand. Link by URL:

```markdown
Repro on [build 20240612.3](https://dev.azure.com/contoso/Fabrikam/_build/results?buildId=987654).
```

## Wiki pages

```markdown
[Capacity API guide](/Fabrikam/_wiki/wikis/Fabrikam.wiki/123/Capacity-API)
```

Wiki page anchor IDs work the same way as for any other ADO markdown header (lowercased, whitespace → `-`).

## Quick recipe: link block at the bottom of a PR

```markdown
## Linked work

- Implements AB#48199
- Fixes #48213
- Supersedes !1742
- Follows up on a1b2c3d
```
