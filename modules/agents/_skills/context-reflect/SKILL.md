---
name: context-reflect
description: Use immediately after completing a task when the user asks for a process retrospective, context reflection, postmortem, or wants to know what skills were used, steps taken, dead ends, extra research, longest or token-heavy work, missing information, misleading information, a better prompt, or the process to follow next time.
metadata:
  author: miles
  version: "0.1"
---

# context-reflect

Produce an evidence-based retrospective of the just-completed task from the
conversation and tool-call context that is visible to the agent.

## When to use this skill

Use this skill when the user invokes `context-reflect` or asks after a task:

- "What did we do?"
- "What skills did you use?"
- "What could have gone better?"
- "What information were we missing?"
- "How should I have prompted you?"
- "What were the dead ends / time sinks / token sinks?"
- "What process should I use next time?"

Do **not** use this skill for normal task planning before work begins. If the
previous task is not in the visible context, ask the user for a transcript,
summary, branch, PR, or artifact before reflecting. Do not invent history.

## Retrospective principles

- **Use evidence.** Base claims on visible messages, loaded skills, tool calls,
  files read/edited, commands run, browser/search activity, and final artifacts.
- **Separate fact from inference.** Mark uncertain items as "inferred" or
  "unknown" rather than overstating them.
- **Do not fabricate token counts.** If exact usage is not exposed, rank token
  consumption qualitatively (`high`, `medium`, `low`) and explain why.
- **Do not blame the user.** Frame missing or misleading information as prompt
  and process improvements.
- **Distinguish discovery from waste.** Necessary investigation is not a dead
  end just because it took time; a dead end is work that did not materially
  improve the result or could have been skipped with better context.
- **Keep it actionable.** End with a repeatable next-time process and a better
  prompt the user can copy.

## Procedure

1. **Establish scope.** Identify the most recent completed task, the user's
   original goal, and the final deliverable. If there were multiple tasks and
   the target is ambiguous, ask which one to reflect on.
2. **Reconstruct the trace.** Review the visible conversation/tool history and
   note:
   - skills loaded or followed;
   - major phases of work;
   - files, URLs, docs, commands, searches, or browser sessions used;
   - validation performed and unresolved issues.
3. **Classify the work.** Build concise inventories for:
   - **Skills used** — skill name, why it was loaded, and whether it helped.
   - **Steps taken** — ordered phases, not every tiny command.
   - **Extra research** — what had to be read or looked up before progress was
     possible, and whether the user could have supplied it up front.
   - **Dead ends** — actions that were unnecessary, duplicative, or caused by
     missing/misleading context; include the avoidable cause.
   - **Longest tasks** — rank by observed elapsed time when available; otherwise
     use qualitative evidence such as repeated loops, large reads, build/test
     duration, or long-running tools.
   - **Token-heavy tasks** — rank by exact token accounting if visible;
     otherwise use qualitative proxies: large file reads, lengthy command
     output, broad web/code searches, repeated diffs, browser snapshots, or
     long reasoning loops.
4. **Answer the focus questions directly.** Include explicit answers to:
   - Was any critical information missing before we started?
   - How should the user have prompted the agent to achieve this result?
   - Was any misleading information present that caused stumbling?
   - What process should be followed if doing this again?
5. **Summarize improvements.** Give concrete changes to the prompt, workflow,
   skill selection, validation, or repository docs that would reduce time and
   token use next time.

## Output format

Use this structure unless the user asks for something different:

```markdown
## Context reflection: <task name>

### Executive summary
- <3-5 bullets with the most important retrospective findings>

### Evidence basis
- **Task:** <original goal>
- **Final deliverable:** <what was produced/changed>
- **Primary evidence:** <conversation/tool/file/search evidence used>
- **Confidence:** <high|medium|low> — <one sentence>

### Skills used
| Skill | Why it was used | Helpfulness | Notes |
| --- | --- | --- | --- |
| <name or "None"> | <reason> | <high/medium/low> | <notes> |

### Steps taken
1. <phase> — <outcome>
2. <phase> — <outcome>

### Extra research needed
| Research | Why it was needed | Could prompt have supplied it? |
| --- | --- | --- |
| <item> | <reason> | <yes/no/partly> |

### Dead ends / avoidable work
| Dead end | Why it happened | How to avoid next time |
| --- | --- | --- |
| <item or "None obvious"> | <cause> | <fix> |

### Longest tasks
| Rank | Task | Evidence | Optimization |
| --- | --- | --- | --- |
| 1 | <task> | <observed/inferred basis> | <next-time improvement> |

### Token consumption hotspots
| Rank | Hotspot | Token impact | Why | Reduction strategy |
| --- | --- | --- | --- | --- |
| 1 | <hotspot> | <exact tokens or high/medium/low> | <reason> | <strategy> |

### Focus questions
**Was critical information missing before we started?**
<answer>

**How should I have been prompted to achieve this result?**
```text
<copyable improved prompt>
```

**Was there misleading information that caused stumbling?**
<answer>

**What process would I take if I did this again?**
1. <step>
2. <step>

### Next-time checklist
- [ ] <actionable item>
- [ ] <actionable item>
```

## Notes on estimates

If exact timing or token telemetry is absent, say so once in the evidence basis
and use relative rankings. Prefer "most token-heavy" / "likely high token use"
over fake numbers.
