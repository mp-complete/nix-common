import { writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("pi-next-smoke", {
    description: "Inspect wrapper resources without calling a model",
    handler: async (_args, ctx) => {
      const options = ctx.getSystemPromptOptions();
      // zigpty silently falls back when its native module cannot load. Check
      // this in the actual Pi runtime, without opening a PTY or spawning a job.
      const ptyNative = process.env.PI_NEXT_ZIGPTY_MODULE
        ? (await import(pathToFileURL(process.env.PI_NEXT_ZIGPTY_MODULE).href)).hasNative
        : undefined;
      let questionnaire;
      if (process.env.PI_NEXT_QUESTION_PACKAGE) {
        const root = process.env.PI_NEXT_QUESTION_PACKAGE;
        const { loadQuestionnaireSession } = await import(pathToFileURL(`${root}/ask-user-question.ts`).href);
        const { reconcileAskUserQuestionTool } = await import(pathToFileURL(`${root}/reconcile.ts`).href);
        // Load the lazy UI graph, but never instantiate a questionnaire. Exercise
        // tool visibility with a fake API instead of asking a model to run it.
        const loaded = await loadQuestionnaireSession();
        let active = ["bash", "ask_user_question"];
        const fakePi = { getActiveTools: () => active, setActiveTools: (names: string[]) => { active = names; } };
        reconcileAskUserQuestionTool(fakePi, { hasUI: false });
        const headlessHidden = active.length === 1 && active[0] === "bash";
        reconcileAskUserQuestionTool(fakePi, { hasUI: true });
        questionnaire = {
          lazyLoaded: loaded.ok && typeof loaded.module.QuestionnaireSession === "function",
          headlessHidden,
          interactiveRestored: active.length === 2 && active.includes("bash") && active.includes("ask_user_question"),
        };
      }
      let todoUiLoaded;
      if (process.env.PI_NEXT_TODO_PACKAGE) {
        const root = process.env.PI_NEXT_TODO_PACKAGE;
        // Validate the lazy view module without creating tasks or a widget.
        const { TodoOverlay } = await import(pathToFileURL(`${root}/todo-overlay.ts`).href);
        todoUiLoaded = typeof TodoOverlay === "function";
      }
      let plannotatorNative;
      if (process.env.PI_NEXT_PLANNOTATOR_PACKAGE) {
        const root = process.env.PI_NEXT_PLANNOTATOR_PACKAGE;
        const require = createRequire(`${root}/node_modules/@plannotator/webtui/package.json`);
        // Loading node-pty resolves its compiled addon, without spawning a PTY.
        const pty = require("node-pty");
        plannotatorNative = typeof pty.spawn === "function" && typeof pty.open === "function";
      }
      // Print mode redirects extension stdout to stderr; keep diagnostics
      // separate so the smoke test can reject even non-fatal loader errors.
      writeFileSync(process.env.PI_NEXT_PROBE_RESULT!, JSON.stringify({
        agentDir: getAgentDir(),
        ptyNative,
        questionnaire,
        plannotatorNative,
        todoUiLoaded,
        offline: process.env.PI_OFFLINE,
        mcpServers: pi.getMcpServers(),
        skills: (options.skills ?? []).map((skill) => skill.name).sort(),
        tools: pi.getAllTools().map((tool) => tool.name).sort(),
        activeTools: pi.getActiveTools().sort(),
        commands: pi.getCommands().map((command) => command.name).sort(),
        appendedPrompt: options.appendSystemPrompt,
      }) + "\n");
      ctx.shutdown();
    },
  });
}
