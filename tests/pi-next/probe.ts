import { writeFileSync } from "node:fs";
import assert from "node:assert/strict";
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
      let chromeLifecycle;
      if (process.env.PI_NEXT_CHROME_PACKAGE) {
        const root = process.env.PI_NEXT_CHROME_PACKAGE;
        const { default: register } = await import(pathToFileURL(`${root}/extensions/browser-execute.ts`).href);
        const { SessionStore } = await import(pathToFileURL(`${root}/src/session-store.ts`).href);
        const handlers = new Map();
        let tool;
        register({ registerTool: (value) => { tool = value; }, on: (name, handler) => handlers.set(name, handler) });
        assert.equal(tool.name, "browser_execute");
        assert.equal(typeof handlers.get("session_shutdown"), "function");
        // Exercise the actual tool with Pi's documented context, not legacy
        // sessionId fields. Never connect a socket or read a browser profile.
        const a = { cwd: ctx.cwd, sessionManager: { getSessionId: () => "chrome-test-a" } };
        const b = { cwd: ctx.cwd, sessionManager: { getSessionId: () => "chrome-test-b" } };
        const run = async (context) => {
          const result = await tool.execute("test", {
            code: "session.testCount = (session.testCount ?? 0) + 1; return session.testCount;",
            description: "Test isolated session state",
          }, undefined, undefined, context);
          return result.details.result;
        };
        // Instrument only the tool call's watchdog. This catches both retained
        // success timers and error paths without waiting a minute to exit.
        const originalSetTimeout = globalThis.setTimeout;
        const originalClearTimeout = globalThis.clearTimeout;
        const timers = new Set();
        globalThis.setTimeout = ((...args) => {
          const timer = originalSetTimeout(...args);
          timers.add(timer);
          return timer;
        }) as typeof setTimeout;
        globalThis.clearTimeout = ((timer) => {
          timers.delete(timer);
          return originalClearTimeout(timer);
        }) as typeof clearTimeout;
        try {
          assert.equal(await run(a), "1");
          assert.equal(timers.size, 0, "success must clear watchdog");
          for (const code of ["throw new Error('fixture failure')", "await new Promise(() => {})"]) {
            await assert.rejects(tool.execute("test", { code, description: "Test watchdog cleanup", timeout: 1 },
              undefined, undefined, a), /fixture failure|timed out/);
            assert.equal(timers.size, 0, "failure must clear watchdog");
          }
        } finally {
          globalThis.setTimeout = originalSetTimeout;
          globalThis.clearTimeout = originalClearTimeout;
          for (const timer of timers) originalClearTimeout(timer);
        }
        assert.equal(await run(a), "2");
        assert.equal(await run(b), "1", "same cwd must not share browser state");
        let closed = 0;
        SessionStore.get("chrome-test-a").close = () => { closed++; };
        await handlers.get("session_shutdown")({}, a);
        await handlers.get("session_shutdown")({}, a);
        assert.equal(closed, 1, "shutdown closes exactly once");
        assert.equal(await run(a), "1", "shutdown evicts the session");
        assert.equal(await run(b), "2", "other sessions survive shutdown");
        await handlers.get("session_shutdown")({}, a);
        await handlers.get("session_shutdown")({}, b);
        chromeLifecycle = true;
      }
      // Print mode redirects extension stdout to stderr; keep diagnostics
      // separate so the smoke test can reject even non-fatal loader errors.
      writeFileSync(process.env.PI_NEXT_PROBE_RESULT!, JSON.stringify({
        agentDir: getAgentDir(),
        ptyNative,
        questionnaire,
        plannotatorNative,
        todoUiLoaded,
        chromeLifecycle,
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
