#!/usr/bin/env bash
set -euo pipefail
# Invoked by Nix with a disposable HOME; never uses real auth or model calls.
script="$1/bin/pi-next"
probe="$2"
export PI_NEXT_ZIGPTY_MODULE="$3/node_modules/zigpty/dist/index.mjs"
notify="$4"
export PI_NEXT_QUESTION_PACKAGE="$5"
export PI_NEXT_PLANNOTATOR_PACKAGE="$6"
export PI_NEXT_TODO_PACKAGE="$7"
export HOME="$TMPDIR/home with spaces"
mkdir -p "$HOME" "$TMPDIR/project"
cd "$TMPDIR/project"
unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR XDG_CONFIG_HOME PI_OFFLINE
export PI_TELEMETRY=0

# File entries override registered servers. Disable Exa in each disposable
# agent directory so the real wrapper can be tested without network access.
disable_exa() {
  mkdir -p "$1"
  printf '%s\n' '{"mcpServers":{"exa":{"url":"https://mcp.exa.ai/mcp","enabled":false}}}' > "$1/mcp.json"
}
disable_exa "$HOME/.config/pi-next"

# No bin/pi collision, and subcommands bypass session flags.
test -x "$script"
# The official notifier is a handler-only extension, not a command/tool. Check
# its explicit wrapper selection as well as the real loader diagnostics below.
grep -F -- "$notify" "$script" > notify-selection.log
test -s "$PI_NEXT_PLANNOTATOR_PACKAGE/plannotator.html"
test -s "$PI_NEXT_PLANNOTATOR_PACKAGE/review-editor.html"
test ! -e "$1/bin/pi"
# Runtime libraries stay in their own store path, not the shared HM profile.
test ! -e "$1/lib/node_modules"
"$script" --version
"$script" list > list.log 2>&1
grep -F 'No packages installed.' list.log
"$script" mcp list --json > mcp.log 2>&1
if "$script" update > update.log 2>&1; then
  echo 'Nix-managed self-update was not blocked' >&2
  exit 1
fi
grep -F 'Pi is managed by Nix; self-update is disabled.' update.log

# Probe native and declared resources without inference. No legacy extension,
# unrelated skill or wrapper instructions should appear in a fresh HOME/project.
if ! PI_NEXT_PROBE_RESULT=probe.json timeout 60 "$script" --no-session --extension "$probe" --print /pi-next-smoke > output.log 2> errors.log; then
  cat output.log errors.log >&2
  exit 1
fi
cat errors.log
# Pi may exit successfully after loader errors; reject diagnostics separately.
test ! -s errors.log
jq -e --arg dir "$HOME/.config/pi-next" '
  .agentDir == $dir
  and .offline == "1"
  and .skills == ["btw", "council-mode", "mk-pi-extension", "pi-interactive-shell", "pi-subagents", "plannotator"]
  and .ptyNative == true
  and .questionnaire == {lazyLoaded: true, headlessHidden: true, interactiveRestored: true}
  and .plannotatorNative == true
  and .todoUiLoaded == true
  and (.appendedPrompt // "") == ""
  and (.mcpServers | length) == 1
  and .mcpServers[0].name == "exa"
  and .mcpServers[0].config.url == "https://mcp.exa.ai/mcp"
  and .mcpServers[0].config.exposure == "codemode"
  and .mcpServers[0].config.enabled != false
  and (.mcpServers[0].config.description | contains("Exa"))
  and (.commands | index("mcp") != null)
  and (.commands | index("llama") != null)
  and (.tools | index("codemode") != null)
  and (.tools | index("tool_search") != null)
  and (["powerline", "btw", "look-pack", "spawn", "attach", "dismiss"] - .commands == [])
  and (.commands | index("todos") != null)
  and (.tools | index("todo") != null)
  and (.activeTools | index("todo") != null)
  and (.tools | index("ask_user_question") != null)
  and (.commands | index("languages") == null)
  and (["plannotator-plan-mode", "plannotator-review", "plannotator-annotate", "plannotator-last", "skill:plannotator"] - .commands == [])
  and (["plannotator_submit_plan", "plannotator_mark_done"] - .tools == [])
  and (.activeTools | index("plannotator_submit_plan") == null and index("plannotator_mark_done") == null)
  and (.tools | index("plannotator") == null)
  and (.tools | index("interactive_shell") != null)
  and (.activeTools | index("interactive_shell") != null)
  and (.commands | index("bg") == null and index("tasks") == null)
  and ([.tools[] | select(startswith("bg_") or startswith("fusion_"))] == ["bg_wait"])
  and (["subagents", "subagents-doctor", "subagents-guide", "subagents-fleet"] - .commands == [])
  and (["council", "parallel-review", "review-loop", "gather-context-and-clarify", "parallel-cleanup", "parallel-research"] - .commands == [])
  and (["subagent", "subagents_enable", "subagent_supervisor", "bg_wait"] - .tools == [])
  # Subagents selects the loader or delegation tool according to model support.
  and (.activeTools | index("subagent") != null or index("subagents_enable") != null)
  and (.activeTools - ["subagent", "subagents_enable", "subagent_supervisor", "bg_wait", "interactive_shell", "ask_user_question", "todo"]) == [
    "bash", "edit", "read", "write"
  ]
  and (.commands | index("mcp-adapter") == null)
  and (.tools | index("windows_shell_exec") == null)
' probe.json || { cat probe.json >&2; exit 1; }

# XDG paths containing spaces and an explicit caller override both work.
export XDG_CONFIG_HOME="$TMPDIR/xdg config"
disable_exa "$XDG_CONFIG_HOME/pi-next"
PI_NEXT_PROBE_RESULT=xdg.json timeout 60 "$script" --no-session --extension "$probe" --print /pi-next-smoke > output.log 2> errors.log
test ! -s errors.log
jq -e --arg dir "$XDG_CONFIG_HOME/pi-next" '.agentDir == $dir' xdg.json
export PI_CODING_AGENT_DIR="$TMPDIR/explicit agent"
disable_exa "$PI_CODING_AGENT_DIR"
PI_NEXT_PROBE_RESULT=override.json timeout 60 "$script" --no-session --extension "$probe" --print /pi-next-smoke > output.log 2> errors.log
test ! -s errors.log
jq -e --arg dir "$PI_CODING_AGENT_DIR" '.agentDir == $dir' override.json
test ! -e "$HOME/.pi/agent"
