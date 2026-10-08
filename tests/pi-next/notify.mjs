import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { stripTypeScriptTypes } from "node:module";
import { runInNewContext } from "node:vm";

// Exercise the actual pinned example with fake transports. Never write terminal
// escapes to stdout, call PowerShell, or start a Pi/model session.
const source = stripTypeScriptTypes(readFileSync(process.argv[2], "utf8"));
assert.equal((source.match(/export default function/g) ?? []).length, 1);
const script = source.replace("export default function", "globalThis.register = function");

async function notify(env) {
  const writes = [];
  const calls = [];
  const handlers = new Map();
  const sandbox = {
    process: { env, stdout: { write: (text) => writes.push(text) } },
    require(name) {
      assert.equal(name, "child_process");
      return { execFile: (file, args) => calls.push({ file, args: Array.from(args) }) };
    },
  };
  runInNewContext(script, sandbox, { timeout: 1000 });
  sandbox.register({ on: (event, handler) => handlers.set(event, handler) });
  assert.deepEqual([...handlers.keys()], ["agent_settled"]);
  assert.equal(writes.length + calls.length, 0, "registration must not notify");
  await handlers.get("agent_settled")();
  return { writes, calls };
}

const generic = await notify({});
assert.deepEqual(generic.writes, ["\x1b]777;notify;Pi;Ready for input\x07"]);
assert.deepEqual(generic.calls, []);

const kitty = await notify({ KITTY_WINDOW_ID: "1" });
assert.deepEqual(kitty.writes, [
  "\x1b]99;i=1:d=0;Pi\x1b\\",
  "\x1b]99;i=1:p=body;Ready for input\x1b\\",
]);
assert.deepEqual(kitty.calls, []);

// Windows Terminal takes precedence if both markers are present.
const windows = await notify({ WT_SESSION: "test", KITTY_WINDOW_ID: "1" });
assert.deepEqual(windows.writes, []);
assert.equal(windows.calls.length, 1);
assert.equal(windows.calls[0].file, "powershell.exe");
assert.deepEqual(windows.calls[0].args.slice(0, 2), ["-NoProfile", "-Command"]);
assert.match(windows.calls[0].args[2], /Ready for input/);
assert.match(windows.calls[0].args[2], /CreateToastNotifier\('Pi'\)/);
assert.match(windows.calls[0].args[2], /\.Show\(/);
console.log("Official notify: settled-only registration and all three mocked transports passed");
