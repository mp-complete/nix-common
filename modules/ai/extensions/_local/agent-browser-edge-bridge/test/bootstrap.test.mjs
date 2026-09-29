import assert from "node:assert/strict";
import { execFile as execFileCallback, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import {
  chmod, copyFile, lstat, mkdir, mkdtemp, readFile, readdir, rm, symlink, writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFile = promisify(execFileCallback);
const source = process.env.EDGE_BRIDGE_SOURCE ?? fileURLToPath(new URL("..", import.meta.url));
const realBash = spawnSync("bash", ["-c", "command -v bash"], { encoding: "utf8" }).stdout.trim();
const realCp = spawnSync("bash", ["-c", "command -v cp"], { encoding: "utf8" }).stdout.trim();
const realGrep = spawnSync("bash", ["-c", "command -v grep"], { encoding: "utf8" }).stdout.trim();

async function fixture(t) {
  const root = await mkdtemp(join(tmpdir(), "pi-edge-bootstrap-test-"));
  t.after(async () => {
    await chmod(join(root, "Windows Temp"), 0o700).catch(() => {});
    await rm(root, { recursive: true, force: true });
  });
  const scripts = join(root, "scripts");
  const temp = join(root, "Windows Temp");
  const bin = join(root, "bin");
  await Promise.all([scripts, temp, bin].map(path => mkdir(path)));
  for (const name of ["bootstrap.sh", "edge_bridge.ps1", "cdp_forwarder.ps1"]) {
    await copyFile(join(resolve(source), "scripts", name), join(scripts, name));
    await chmod(join(scripts, name), 0o444);
  }
  const stub = async (name, body) => {
    const path = join(bin, name);
    // Nix sandboxes intentionally lack /usr/bin/env.
    await writeFile(path, `#!${realBash}\nset -euo pipefail\n${body}\n`);
    await chmod(path, 0o755);
  };
  await stub("grep", `if [[ "$*" == "-qi microsoft /proc/version" ]]; then exit 0; fi\nexec "$REAL_GREP" "$@"`);
  await stub("cmd.exe", `printf '%s\\r\\n' 'C:\\Windows Temp'`);
  await stub("wslpath", `case "$1" in -u) printf '%s\\n' "$FAKE_WINDOWS_TEMP";; -w) printf '%s\\n' "$2";; *) exit 1;; esac`);
  await stub("powershell.exe", `printf 'called\\n' >> "$POWERSHELL_CALLS"\nprintf '%s\\n' '{"browser":"Edg/123.0","webSocketPath":"/devtools/browser/test-id"}'`);
  await stub("curl", `printf '%s\\n' '{"Browser":"Edg/123.0","webSocketDebuggerUrl":"ws://127.0.0.1:9222/devtools/browser/test-id"}'`);
  // Any unexpected fallback must fail quickly, never access the host network.
  await stub("ip", "exit 91");
  await stub("sleep", "exit 92");
  const env = {
    PATH: `${bin}:${process.env.PATH}`,
    HOME: root,
    TMPDIR: root,
    FAKE_WINDOWS_TEMP: temp,
    POWERSHELL_CALLS: join(root, "powershell-calls"),
    REAL_GREP: realGrep,
    REAL_CP: realCp,
  };
  const run = () => execFile("bash", [join(scripts, "bootstrap.sh")], {
    env, timeout: 10_000, maxBuffer: 1024 * 1024,
  });
  const target = async (name) => {
    const bytes = await readFile(join(scripts, name));
    const hash = createHash("sha256").update(bytes).digest("hex").slice(0, 16);
    const prefix = name === "edge_bridge.ps1" ? "bridge" : "forwarder";
    return join(temp, `pi_agent_browser_edge_${prefix}-${hash}.ps1`);
  };
  return { root, scripts, temp, env, stub, run, target };
}

async function assertNoPowerShell(f) {
  await assert.rejects(readFile(f.env.POWERSHELL_CALLS), { code: "ENOENT" });
}

async function assertNoStagingFiles(f) {
  assert.deepEqual((await readdir(f.temp)).filter(name => name.startsWith(".pi-edge-stage.")), []);
}

function assertEndpoint(result) {
  assert.equal(result.stdout, "http://127.0.0.1:9222\n", result.stderr);
}

test("bootstrap succeeds twice from read-only Nix sources without rewriting verified files", async t => {
  const f = await fixture(t);
  assertEndpoint(await f.run());
  const paths = await Promise.all(["edge_bridge.ps1", "cdp_forwarder.ps1"].map(f.target));
  // Recreate the mode inherited by the old cp implementation, also testing migration.
  for (const path of paths) await chmod(path, 0o444);
  const before = await Promise.all(paths.map(path => lstat(path)));
  assertEndpoint(await f.run());
  const after = await Promise.all(paths.map(path => lstat(path)));
  for (let i = 0; i < paths.length; i++) {
    assert.equal(after[i].ino, before[i].ino);
    assert.equal(after[i].mtimeMs, before[i].mtimeMs);
    assert.equal(after[i].mode & 0o777, 0o444);
  }
  await assertNoStagingFiles(f);
});

test("new scripts are complete and owner-only readable/writable", async t => {
  const f = await fixture(t);
  assertEndpoint(await f.run());
  for (const name of ["edge_bridge.ps1", "cdp_forwarder.ps1"]) {
    const path = await f.target(name);
    assert.deepEqual(await readFile(path), await readFile(join(f.scripts, name)));
    const stat = await lstat(path);
    assert.equal(stat.mode & 0o777, 0o600);
    assert.equal(stat.nlink, 1, "Only the published name remains after staging cleanup");
  }
  await assertNoStagingFiles(f);
});

test("simultaneous cold bootstraps publish complete scripts and converge", async t => {
  const f = await fixture(t);
  const results = await Promise.allSettled(Array.from({ length: 32 }, () => f.run()));
  for (const result of results) {
    assert.equal(result.status, "fulfilled", result.reason?.stderr);
    assertEndpoint(result.value);
  }
  for (const name of ["edge_bridge.ps1", "cdp_forwarder.ps1"]) {
    assert.deepEqual(await readFile(await f.target(name)), await readFile(join(f.scripts, name)));
  }
  await assertNoStagingFiles(f);
});

for (const kind of ["mismatch", "symlink", "dangling-symlink", "directory"]) {
  test(`unexpected ${kind} fails closed before PowerShell without changing it`, async t => {
    const f = await fixture(t);
    const path = await f.target("edge_bridge.ps1");
    const outside = join(f.root, "outside.ps1");
    const contents = await readFile(join(f.scripts, "edge_bridge.ps1"));
    await writeFile(outside, contents);
    if (kind === "mismatch") await writeFile(path, "unexpected contents");
    else if (kind === "directory") await mkdir(path);
    else await symlink(kind === "symlink" ? outside : join(f.root, "missing"), path);
    await assert.rejects(f.run(), error => {
      assert.match(error.stderr, /Windows TEMP staging/);
      return true;
    });
    await assertNoPowerShell(f);
    assert.deepEqual(await readFile(outside), contents);
    if (kind === "mismatch") assert.equal(await readFile(path, "utf8"), "unexpected contents");
    else if (kind === "directory") assert.ok((await lstat(path)).isDirectory());
    else assert.ok((await lstat(path)).isSymbolicLink());
    await assertNoStagingFiles(f);
  });
}

test("interrupted copy never publishes a partial script and cleans its temporary file", async t => {
  const f = await fixture(t);
  await f.stub("cp", `printf 'partial' > "\${@: -1}"\nexit 1`);
  await assert.rejects(f.run(), error => {
    assert.match(error.stderr, /Windows TEMP staging/);
    return true;
  });
  await assert.rejects(lstat(await f.target("edge_bridge.ps1")), { code: "ENOENT" });
  await assertNoPowerShell(f);
  await assertNoStagingFiles(f);
});

test("a competing unexpected destination is never overwritten or executed", async t => {
  const f = await fixture(t);
  f.env.RACE_TARGET = await f.target("edge_bridge.ps1");
  await f.stub("cp", `"$REAL_CP" "$@"\nprintf 'competing contents' > "$RACE_TARGET"`);
  await assert.rejects(f.run(), error => {
    assert.match(error.stderr, /Windows TEMP staging/);
    return true;
  });
  assert.equal(await readFile(f.env.RACE_TARGET, "utf8"), "competing contents");
  await assertNoPowerShell(f);
  await assertNoStagingFiles(f);
});

test("hard-link failure reports the required capability and leaves no published file", async t => {
  const f = await fixture(t);
  await f.stub("ln", "exit 1");
  await assert.rejects(f.run(), error => {
    assert.match(error.stderr, /Windows TEMP staging:.*requires hard-link support and write access/);
    return true;
  });
  await assert.rejects(lstat(await f.target("edge_bridge.ps1")), { code: "ENOENT" });
  await assertNoPowerShell(f);
  await assertNoStagingFiles(f);
});

test("unwritable Windows TEMP reports staging failure before PowerShell", {
  skip: process.getuid?.() === 0 && "Root bypasses ordinary Unix write permissions",
}, async t => {
  const f = await fixture(t);
  await chmod(f.temp, 0o500);
  await assert.rejects(f.run(), error => {
    assert.match(error.stderr, /Windows TEMP staging/);
    return true;
  });
  await assertNoPowerShell(f);
});
