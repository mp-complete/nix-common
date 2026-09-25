# Appendix metadata

Every report ends with a "Run metadata" appendix that records the
context of the agent run that produced it. The reader uses this to
decide whether the report is reproducible and trustworthy.

## What goes in `meta`

```jsonc
{
  "model":       "claude-sonnet-4.7",   // model identifier
  "agent":       "crush",                // crush | opencode | copilot-cli | aider | pi
  "host":        "euler",                // omit; defaults to os.hostname()
  "cwd":         "/home/miles/src/foo",  // omit; defaults to process.cwd()
  "prompt":      "verbatim user prompt text",
  "generatedAt": "2026-06-15T14:30:00Z", // omit; defaults to now
  "tools": [
    { "name": "grep",  "calls": 14, "summary": "ripgrep across services/order" },
    { "name": "bash",  "calls":  6, "summary": "ran perf scripts" },
    { "name": "fetch", "calls":  2, "summary": "GitHub API for PR #4421" },
    { "name": "browser-control.capture_page", "calls": 1 }
  ],
  "sources": [ /* see provenance.md */ ]
}
```

All of these fields are technically optional, but the appendix says
"unknown" for anything missing, which looks sloppy. Treat them as
required.

## Filling in `model`, `agent`, `prompt`

The skill itself doesn't introspect the calling agent — agents differ
in how (or whether) they expose this info. Follow the per-agent
convention:

### Crush

The verbatim user prompt is the most-recent user message in the
conversation. The model name is whatever you (the agent) know about
yourself. Set:

```jsonc
"model":  "<your model id, e.g. claude-sonnet-4.7>",
"agent":  "crush",
"prompt": "<the user's verbatim prompt that asked for this report>"
```

### OpenCode

```jsonc
"model":  "<provider>:<model-id>",
"agent":  "opencode",
"prompt": "<verbatim user prompt>"
```

### Copilot CLI

```jsonc
"model":  "github-copilot:<id>",
"agent":  "copilot-cli",
"prompt": "<verbatim user prompt>"
```

### Aider, Pi, others

Use whatever identifying info is available. Worst case, set
`agent: "ai"` and put the runtime details in `model`.

## Recording `tools`

`tools` is a tally of every tool call the agent made while answering.
The agent maintains this count internally — typically:

- Start the report task with `tools = {}` (empty map).
- After each tool call, increment `tools[name].calls` and optionally
  set a `summary` on the first call.
- When assembling the spec, convert to the array form
  `[{ name, calls, summary }]`, sorted by call count descending.

Tools that count:

- Anything that touched the filesystem (`view`, `ls`, `grep`,
  `glob`).
- Anything that ran a command (`bash`).
- Anything that reached out to the network (`fetch`,
  `agentic_fetch`).
- Anything that drove another skill (e.g. `browser-control.capture_page`).
- MCP server tool calls (use the full MCP tool name).
- Web search calls (label them `web-search`).

Don't count internal-only operations (todo updates, formatting
tweaks).

## Why this matters

The appendix is the "show your work" section. A senior reader
will scan it to gauge:

- **Reproducibility** — same prompt + same tools + same cwd + same
  date → same report?
- **Coverage** — did the agent look broadly enough? Two tool calls
  to back a 15-finding report is suspicious.
- **Trust** — were the sources from inside the codebase, from the
  agent's training data, or from live web fetches?

Be honest. If you only ran one grep and made educated guesses, that
should be visible.
