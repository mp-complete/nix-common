#!/usr/bin/env node
/**
 * build.mjs — assemble a report directory from a JSON spec.
 *
 *   node build.mjs <spec.json> [--out <dir>] [--open] [--langs nix,typescript,bash,...] [--wide] [--no-inline-libs]
 *
 * Reads a spec.json (see references/spec-schema.md), interpolates into
 * template.html, writes index.html into the output directory. Copies
 * assets/ if there are sibling files referenced. Optionally opens the
 * result in the user's preferred browser.
 *
 * Defaults:
 *   --out         derived from spec.slug under $AGENT_REPORTS_DIR or ~/reports
 *   --langs       nix,typescript,javascript,bash,python,json,yaml,sql,rust,go,clojure,diff
 *   --open        false
 *   --inline-libs true (highlight.js is always inlined; vega is CDN unless --inline-libs)
 *
 * Outputs absolute path to index.html on stdout (last line).
 */

import { readFile, writeFile, mkdir, copyFile, readdir, stat } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join, resolve, basename, relative } from 'node:path';
import { spawn } from 'node:child_process';
import { homedir, hostname } from 'node:os';

const __filename = fileURLToPath(import.meta.url);
const __dirname  = dirname(__filename);
const SKILL_DIR  = resolve(__dirname, '..');
const ASSETS_DIR = join(SKILL_DIR, 'assets');
const VENDOR_DIR = join(ASSETS_DIR, 'vendor');

const SKILL_VERSION = '0.1';

// ---------- arg parsing ----------
const args = process.argv.slice(2);
if (args.length === 0 || args[0] === '-h' || args[0] === '--help') {
  usage(); process.exit(args.length === 0 ? 1 : 0);
}

const specPath = args[0];
const opts = { out: null, open: false, langs: null, wide: false, inlineLibs: true };
for (let i = 1; i < args.length; i++) {
  const a = args[i];
  if (a === '--out')              opts.out = args[++i];
  else if (a === '--open')        opts.open = true;
  else if (a === '--no-open')     opts.open = false;
  else if (a === '--langs')       opts.langs = args[++i].split(',').map(s => s.trim()).filter(Boolean);
  else if (a === '--wide')        opts.wide = true;
  else if (a === '--inline-libs') opts.inlineLibs = true;
  else if (a === '--no-inline-libs') opts.inlineLibs = false;
  else { console.error(`unknown arg: ${a}`); process.exit(2); }
}

// ---------- spec ----------
const specRaw = await readFile(specPath, 'utf8');
let spec;
try { spec = JSON.parse(specRaw); }
catch (e) { console.error(`spec is not valid JSON: ${e.message}`); process.exit(2); }

requireField(spec, 'title');
requireField(spec, 'slug');
requireField(spec, 'summary');
requireField(spec.summary, 'question',   'summary.question');
requireField(spec.summary, 'context',    'summary.context');
requireField(spec.summary, 'findings',   'summary.findings');
requireField(spec.summary, 'confidence', 'summary.confidence');
requireField(spec.summary.confidence, 'level',  'summary.confidence.level');
requireField(spec.summary.confidence, 'reason', 'summary.confidence.reason');

const level = String(spec.summary.confidence.level).toLowerCase();
if (!['high','medium','low'].includes(level)) {
  console.error(`summary.confidence.level must be high|medium|low, got: ${level}`);
  process.exit(2);
}

// ---------- output dir ----------
const reportsRoot = process.env.AGENT_REPORTS_DIR || join(homedir(), 'reports');
const ts = new Date().toISOString().replace(/[:.]/g, '-').replace(/Z$/, 'Z');
const outDir = opts.out
  ? resolve(opts.out)
  : join(reportsRoot, `${spec.slug}-${ts.slice(0, 16)}`); // minute precision
await mkdir(outDir, { recursive: true });

// ---------- vendor copy ----------
const vendorOut = join(outDir, 'vendor');
await mkdir(vendorOut, { recursive: true });
// We inline highlight.js into the html, but we also drop the vendor
// dir alongside in case the report wants to lazy-load extra assets.

// ---------- load template + css ----------
const template = await readFile(join(ASSETS_DIR, 'template.html'), 'utf8');
const css      = await readFile(join(ASSETS_DIR, 'styles.css'), 'utf8');

// highlight.js: core + chosen languages + light/dark themes (inlined).
const langs = opts.langs && opts.langs.length
  ? opts.langs
  : ['nix','typescript','javascript','bash','python','json','yaml','rust','go','clojure','diff','markdown'];

const hljsCore  = await readFile(join(VENDOR_DIR, 'highlight.min.js'), 'utf8');
const hljsLight = await readFile(join(VENDOR_DIR, 'hljs-light.min.css'), 'utf8');
const hljsDark  = await readFile(join(VENDOR_DIR, 'hljs-dark.min.css'), 'utf8');

const langScripts = [];
for (const lang of langs) {
  const p = join(VENDOR_DIR, 'langs', `${lang}.min.js`);
  if (existsSync(p)) langScripts.push(await readFile(p, 'utf8'));
  // skip silently for langs not vendored (e.g. typescript/python/bash ship in core)
}

// ---------- assemble sections ----------
const findings = (spec.summary.findings || []).map(f => {
  if (typeof f === 'string') return `<li>${f}</li>`;
  const refs = renderRefs(f.refs);
  return `<li>${escapeIfNotHtml(f.text)}${refs}</li>`;
}).join('\n');

const sections = (spec.sections || []).map((s, i) => renderSection(s, i + 1)).join('\n');

const toc = renderToc(spec.sections || [], spec);

const optRecs   = renderCallout('recommendations', 'Recommendations',  spec.recommendations);
const optOpen   = renderCallout('open-questions',  'Open questions',   spec.openQuestions);
const optScope  = renderCallout('out-of-scope',    'Out of scope',     spec.outOfScope);

const toolsTable = renderToolsTable(spec.meta?.tools || []);
const sources    = renderSources(spec.meta?.sources || []);

const headExtras = [];
const bodyExtras = [];

// Vega-Lite hook: if any section asks for a chart, include vega-embed.
const wantsVega = JSON.stringify(spec.sections || []).includes('"chart"');
if (wantsVega) {
  if (opts.inlineLibs) {
    headExtras.push(`<!-- vega-lite via CDN; pass --no-inline-libs only if you really want offline portability; vendoring vega is ~1.5MB -->`);
  }
  headExtras.push(`<script src="https://cdn.jsdelivr.net/npm/vega@5"></script>`);
  headExtras.push(`<script src="https://cdn.jsdelivr.net/npm/vega-lite@5"></script>`);
  headExtras.push(`<script src="https://cdn.jsdelivr.net/npm/vega-embed@6"></script>`);
}

// table-sort: cheap, ~3KB; only inline if any sortable table exists.
const wantsSort = /<table[^>]*class="[^"]*sortable[^"]*"/.test(sections);
if (wantsSort) {
  bodyExtras.push(`<script>${tableSortJs()}</script>`);
}

// ---------- substitute ----------
const meta = spec.meta || {};
const generatedAt = meta.generatedAt || new Date().toISOString();
const generatedAtHuman = new Date(generatedAt).toLocaleString('en-US', {
  year: 'numeric', month: 'short', day: '2-digit',
  hour: '2-digit', minute: '2-digit', timeZoneName: 'short',
});

const tokens = {
  __TITLE__:                  spec.title,
  __LEDE__:                   spec.lede || '',
  __BADGE__:                  spec.badge || 'report',
  __SLUG__:                   spec.slug,
  __GENERATED_AT__:           generatedAt,
  __GENERATED_AT_HUMAN__:     generatedAtHuman,
  __CSS__:                    css,
  __HLJS_JS__:                hljsCore,
  __HLJS_LANGS_JS__:          langScripts.join('\n'),
  __HLJS_LIGHT_CSS__:         hljsLight,
  __HLJS_DARK_CSS__:          hljsDark,
  __TOC__:                    toc,
  __EXEC_QUESTION__:          escapeIfNotHtml(spec.summary.question),
  __EXEC_CONTEXT__:           escapeIfNotHtml(spec.summary.context),
  __EXEC_FINDINGS__:          findings,
  __EXEC_CONFIDENCE_LEVEL__:  level,
  __EXEC_CONFIDENCE_REASON__: escapeIfNotHtml(spec.summary.confidence.reason),
  __OPTIONAL_RECOMMENDATIONS__: optRecs,
  __OPTIONAL_OPEN_QUESTIONS__:  optOpen,
  __OPTIONAL_OUT_OF_SCOPE__:    optScope,
  __BODY__:                   sections,
  __HEAD_EXTRAS__:            headExtras.join('\n'),
  __BODY_EXTRAS__:            bodyExtras.join('\n'),
  __META_MODEL__:             escapeIfNotHtml(meta.model || 'unknown'),
  __META_AGENT__:             escapeIfNotHtml(meta.agent || 'unknown'),
  __META_HOST__:              escapeIfNotHtml(meta.host || hostname()),
  __META_CWD__:               escapeIfNotHtml(meta.cwd || process.cwd()),
  __META_PROMPT__:            escapeHtml(meta.prompt || '(prompt not recorded)'),
  __META_TOOLS_TABLE__:       toolsTable,
  __META_SOURCES__:           sources,
  __META_SKILL_VERSION__:     SKILL_VERSION,
};
// Single-pass token substitution using a function replacement so
// values containing `$&`, `$1`, `$$` (yes, hljs language grammars
// have these) aren't interpreted as backreferences.
const tokenRe = /__(?:TITLE|LEDE|BADGE|SLUG|GENERATED_AT|GENERATED_AT_HUMAN|CSS|HLJS_JS|HLJS_LANGS_JS|HLJS_LIGHT_CSS|HLJS_DARK_CSS|TOC|EXEC_QUESTION|EXEC_CONTEXT|EXEC_FINDINGS|EXEC_CONFIDENCE_LEVEL|EXEC_CONFIDENCE_REASON|OPTIONAL_RECOMMENDATIONS|OPTIONAL_OPEN_QUESTIONS|OPTIONAL_OUT_OF_SCOPE|BODY|HEAD_EXTRAS|BODY_EXTRAS|META_MODEL|META_AGENT|META_HOST|META_CWD|META_PROMPT|META_TOOLS_TABLE|META_SOURCES|META_SKILL_VERSION)__/g;
const html = template.replace(tokenRe, (m) => String(tokens[m] ?? ''));

// Apply wide layout if requested.
const htmlFinal = opts.wide ? html.replace('<body>', '<body class="wide">') : html;

const indexPath = join(outDir, 'index.html');
await writeFile(indexPath, htmlFinal, 'utf8');

// Copy any data files declared in spec.dataFiles ({name, contentOrPath}).
if (Array.isArray(spec.dataFiles)) {
  const dataDir = join(outDir, 'data');
  await mkdir(dataDir, { recursive: true });
  for (const f of spec.dataFiles) {
    if (!f?.name) continue;
    const dst = join(dataDir, f.name);
    if (f.path) await copyFile(resolve(f.path), dst);
    else if (typeof f.content === 'string') await writeFile(dst, f.content, 'utf8');
    else if (f.content != null) await writeFile(dst, JSON.stringify(f.content, null, 2), 'utf8');
  }
}

// Update "latest" symlink (best-effort).
try {
  const latestLink = join(reportsRoot, 'latest');
  await mkdir(reportsRoot, { recursive: true });
  if (existsSync(latestLink)) {
    const { unlink } = await import('node:fs/promises');
    await unlink(latestLink).catch(() => {});
  }
  const { symlink } = await import('node:fs/promises');
  await symlink(outDir, latestLink, 'dir').catch(() => {});
} catch { /* non-fatal */ }

// ---------- open ----------
if (opts.open) {
  await openInBrowser(indexPath);
}

console.error(`report:    ${outDir}`);
console.error(`url:       file://${indexPath}`);
console.log(indexPath); // last line: machine-consumable path

// =========================================================================

function usage() {
  console.error(`html-report build.mjs

usage:
  node build.mjs <spec.json> [options]

options:
  --out <dir>         output directory (default: \$AGENT_REPORTS_DIR/<slug>-<ts>)
  --open              open the result in the user's browser after build
  --no-open           explicitly do not open
  --langs a,b,c       comma list of hljs languages to bundle
                      default: nix,typescript,javascript,bash,python,json,yaml,
                               rust,go,clojure,diff,markdown
  --wide              use the wide layout (max-width 1280 instead of 980)
  --inline-libs       (default) inline highlight.js; vega still loads from CDN
  --no-inline-libs    (rare) skip vendor copy; rely on cdn for everything

stdout: path to the generated index.html (last line).
stderr: human-readable progress.
`);
}

function requireField(obj, key, path) {
  if (obj == null || obj[key] == null || (Array.isArray(obj[key]) && obj[key].length === 0 && key === 'findings')) {
    console.error(`spec missing required field: ${path || key}`);
    process.exit(2);
  }
}

function escapeHtml(s) {
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

// Pass through strings that look like authored HTML (start with '<'),
// escape everything else. Lets the agent author rich snippets while
// preventing accidental injection of plain text containing '<'.
function escapeIfNotHtml(s) {
  if (s == null) return '';
  const str = String(s);
  if (/^\s*</.test(str)) return str;
  return escapeHtml(str);
}

function slugify(s) {
  return String(s).toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function renderRefs(refs) {
  if (!Array.isArray(refs) || refs.length === 0) return '';
  return refs.map(r => {
    const id = typeof r === 'string' ? r : r.id;
    if (!id) return '';
    return ` <a class="ref" href="#${escapeHtml(id)}">${escapeHtml(id)}</a>`;
  }).join('');
}

function renderToc(sections, spec) {
  const items = [];
  items.push(`<li><span class="toc-num">00</span><a href="#executive-summary">Executive summary</a></li>`);
  if (Array.isArray(spec.recommendations) && spec.recommendations.length)
    items.push(`<li><span class="toc-num">--</span><a href="#recommendations">Recommendations</a></li>`);
  if (Array.isArray(spec.openQuestions) && spec.openQuestions.length)
    items.push(`<li><span class="toc-num">--</span><a href="#open-questions">Open questions</a></li>`);
  if (Array.isArray(spec.outOfScope) && spec.outOfScope.length)
    items.push(`<li><span class="toc-num">--</span><a href="#out-of-scope">Out of scope</a></li>`);
  sections.forEach((s, i) => {
    const id = s.id || slugify(s.heading || `section-${i+1}`);
    const n = String(i + 1).padStart(2, '0');
    items.push(`<li><span class="toc-num">${n}</span><a href="#${escapeHtml(id)}">${escapeIfNotHtml(s.heading || `Section ${i+1}`)}</a></li>`);
  });
  items.push(`<li><span class="toc-num">--</span><a href="#appendix-metadata">Appendix · metadata</a></li>`);
  return `<ol>${items.join('')}</ol>`;
}

function renderCallout(cls, title, items) {
  if (!Array.isArray(items) || items.length === 0) return '';
  const id = cls;
  const lis = items.map(it => {
    if (typeof it === 'string') return `<li>${escapeIfNotHtml(it)}</li>`;
    const refs = renderRefs(it.refs);
    return `<li>${escapeIfNotHtml(it.text)}${refs}</li>`;
  }).join('\n');
  return `<section id="${id}" class="callout ${cls}"><h2>${title}</h2><ol>${lis}</ol></section>`;
}

function renderSection(s, n) {
  const id = s.id || slugify(s.heading || `section-${n}`);
  const heading = `<h2 id="${id}-h">${escapeIfNotHtml(s.heading || `Section ${n}`)}</h2>`;
  let body = '';
  if (s.html) body += s.html;
  if (Array.isArray(s.blocks)) {
    for (const b of s.blocks) body += renderBlock(b);
  }
  return `<section id="${id}">${heading}${body}</section>`;
}

function renderBlock(b) {
  switch (b.type) {
    case 'html':       return b.html || '';
    case 'p':          return `<p>${escapeIfNotHtml(b.text)}</p>`;
    case 'note':       return `<p><em>${escapeIfNotHtml(b.text)}</em></p>`;
    case 'list': {
      const tag = b.ordered ? 'ol' : 'ul';
      const items = (b.items || []).map(it => {
        if (typeof it === 'string') return `<li>${escapeIfNotHtml(it)}</li>`;
        const refs = renderRefs(it.refs);
        return `<li>${escapeIfNotHtml(it.text)}${refs}</li>`;
      }).join('');
      return `<${tag}>${items}</${tag}>`;
    }
    case 'code': {
      const lang = b.lang ? ` class="language-${escapeHtml(b.lang)}"` : '';
      const cap = b.caption || b.path ? `<div class="code-caption">${b.caption ? `<span>${escapeIfNotHtml(b.caption)}</span>` : '<span></span>'}${b.path ? `<span class="path">${escapeIfNotHtml(b.path)}</span>` : ''}</div>` : '';
      return `${cap}<pre><code${lang}>${escapeHtml(b.code || '')}</code></pre>`;
    }
    case 'table': {
      const tableClasses = ['', b.sortable ? 'sortable' : '', b.tight ? 'tight' : ''].filter(Boolean).join(' ');
      const cls = tableClasses ? ` class="${tableClasses.trim()}"` : '';
      const headers = (b.headers || []).map(h => {
        if (typeof h === 'string') return `<th>${escapeIfNotHtml(h)}</th>`;
        const c = h.align === 'right' ? ' class="num"' : (h.align === 'mono' ? ' class="mono"' : '');
        const sort = b.sortable ? ' aria-sort="none"' : '';
        return `<th${c}${sort}>${escapeIfNotHtml(h.text || '')}</th>`;
      }).join('');
      const rows = (b.rows || []).map(r => {
        const cells = r.map((cell, i) => {
          const hdr = (b.headers || [])[i];
          const align = hdr && typeof hdr === 'object' ? hdr.align : null;
          const c = align === 'right' ? ' class="num"' : (align === 'mono' ? ' class="mono"' : '');
          if (cell && typeof cell === 'object' && cell.html) return `<td${c}>${cell.html}</td>`;
          return `<td${c}>${escapeIfNotHtml(cell)}</td>`;
        }).join('');
        return `<tr>${cells}</tr>`;
      }).join('');
      const caption = b.caption ? `<caption style="caption-side:bottom;text-align:left;font:11px/1.4 var(--mono);color:var(--muted);padding-top:6px">${escapeIfNotHtml(b.caption)}</caption>` : '';
      return `<div class="table-wrap"><table${cls}><thead><tr>${headers}</tr></thead><tbody>${rows}</tbody>${caption}</table></div>`;
    }
    case 'kv': {
      const items = (b.items || []).map(it => `<dt>${escapeIfNotHtml(it.k)}</dt><dd${it.mono ? ' class="mono"' : ''}>${escapeIfNotHtml(it.v)}</dd>`).join('');
      return `<dl class="kv">${items}</dl>`;
    }
    case 'details': {
      const summary = b.summary || 'details';
      const where = b.where ? `<span class="where">${escapeIfNotHtml(b.where)}</span>` : '';
      const id = b.id ? ` id="${escapeHtml(b.id)}"` : '';
      let inner = '';
      if (b.html) inner = b.html;
      else if (b.code != null) {
        const lang = b.lang ? ` class="language-${escapeHtml(b.lang)}"` : '';
        inner = `<pre><code${lang}>${escapeHtml(b.code)}</code></pre>`;
      } else if (Array.isArray(b.blocks)) {
        inner = `<div>${b.blocks.map(renderBlock).join('')}</div>`;
      }
      const open = b.open ? ' open' : '';
      return `<details${id}${open}><summary>${escapeIfNotHtml(summary)}${where}</summary>${inner}</details>`;
    }
    case 'figure': {
      const id = b.id ? ` id="${escapeHtml(b.id)}"` : '';
      const cap = b.caption ? `<figcaption>${b.num ? `<span class="num">Fig. ${escapeIfNotHtml(b.num)}.</span>` : ''}${escapeIfNotHtml(b.caption)}</figcaption>` : '';
      let inner = '';
      if (b.svg)      inner = b.svg;
      else if (b.src) inner = `<img src="${escapeHtml(b.src)}" alt="${escapeHtml(b.alt || '')}">`;
      else if (b.html) inner = b.html;
      return `<figure${id}>${inner}${cap}</figure>`;
    }
    case 'chart': {
      const cid = b.id || `chart-${Math.random().toString(36).slice(2, 8)}`;
      const cap = b.caption ? `<figcaption>${b.num ? `<span class="num">Fig. ${escapeIfNotHtml(b.num)}.</span>` : ''}${escapeIfNotHtml(b.caption)}</figcaption>` : '';
      const spec = JSON.stringify(b.spec || {});
      return `<figure id="${escapeHtml(cid)}"><div class="vega-host" id="${escapeHtml(cid)}-host"></div>${cap}</figure>
<script>(function(){var s=${spec};vegaEmbed('#${cid}-host', s, {actions:false, theme: matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : undefined});})();</script>`;
    }
    case 'diff': {
      const lines = (b.lines || []).map(l => {
        let cls = 'ctx';
        if (l.startsWith('+'))      cls = 'add';
        else if (l.startsWith('-')) cls = 'del';
        else if (l.startsWith('@')) cls = 'hunk';
        return `<div class="${cls}">${escapeHtml(l)}</div>`;
      }).join('');
      return `<pre class="diff">${lines}</pre>`;
    }
    case 'callout': {
      const cls = b.tone || 'recommendations';
      return `<aside class="callout ${escapeHtml(cls)}">${b.html || `<p>${escapeIfNotHtml(b.text)}</p>`}</aside>`;
    }
    default:
      console.error(`warn: unknown block type "${b.type}"`);
      return `<!-- unknown block: ${escapeHtml(b.type)} -->`;
  }
}

function renderToolsTable(tools) {
  if (!Array.isArray(tools) || tools.length === 0) {
    return `<p class="meta-mono">(no tools recorded)</p>`;
  }
  const rows = tools.map(t => {
    const args = t.summary || t.args || '';
    return `<tr><td class="mono">${escapeIfNotHtml(t.name)}</td><td class="num">${escapeIfNotHtml(t.calls ?? '')}</td><td>${escapeIfNotHtml(args)}</td></tr>`;
  }).join('');
  return `<table class="tight"><thead><tr><th>tool</th><th class="num">calls</th><th>notes</th></tr></thead><tbody>${rows}</tbody></table>`;
}

function renderSources(sources) {
  if (!Array.isArray(sources) || sources.length === 0) {
    return `<li class="meta-mono">(no sources recorded)</li>`;
  }
  return sources.map(s => {
    const id = s.id ? ` id="${escapeHtml(s.id)}"` : '';
    if (s.kind === 'url' || s.url) {
      const meta = s.accessed ? `<span class="src-meta">accessed ${escapeIfNotHtml(s.accessed)}</span>` : '';
      const note = s.note ? ` &mdash; ${escapeIfNotHtml(s.note)}` : '';
      return `<li${id}><a href="${escapeHtml(s.url)}">${escapeIfNotHtml(s.title || s.url)}</a>${note} ${meta}</li>`;
    }
    if (s.kind === 'file' || s.path) {
      const line = s.line ? `:${s.line}` : '';
      const note = s.note ? ` &mdash; ${escapeIfNotHtml(s.note)}` : '';
      return `<li${id}><code>${escapeIfNotHtml(s.path + line)}</code>${note}</li>`;
    }
    if (s.kind === 'pr' || s.kind === 'commit' || s.kind === 'issue') {
      const note = s.note ? ` &mdash; ${escapeIfNotHtml(s.note)}` : '';
      return `<li${id}><span class="pill info">${escapeHtml(s.kind)}</span> <a href="${escapeHtml(s.url || '#')}">${escapeIfNotHtml(s.title || s.id || s.url)}</a>${note}</li>`;
    }
    if (s.kind === 'screenshot') {
      const note = s.note ? ` &mdash; ${escapeIfNotHtml(s.note)}` : '';
      return `<li${id}><span class="pill">screenshot</span> <a href="${escapeHtml(s.path || s.url || '#')}">${escapeIfNotHtml(s.title || s.path || 'screenshot')}</a>${note}</li>`;
    }
    return `<li${id}>${escapeIfNotHtml(s.text || JSON.stringify(s))}</li>`;
  }).join('');
}

async function openInBrowser(indexPath) {
  const isWsl = process.env.WSL_DISTRO_NAME || process.env.WSL_INTEROP;
  const cmd = isWsl ? 'wsl-open' : 'xdg-open';
  await new Promise((res) => {
    const child = spawn(cmd, [indexPath], { detached: true, stdio: 'ignore' });
    child.on('error', () => res());
    child.unref();
    res();
  });
}

// ---------- table-sort (vanilla, MIT, ~1KB minified-ish) ----------
function tableSortJs() {
  return `
(function(){
  function sortRows(tbody, col, dir){
    var rows = Array.from(tbody.querySelectorAll('tr'));
    rows.sort(function(a,b){
      var x = a.children[col]?.innerText.trim() || '';
      var y = b.children[col]?.innerText.trim() || '';
      var xn = parseFloat(x.replace(/[^0-9.\\-]/g,''));
      var yn = parseFloat(y.replace(/[^0-9.\\-]/g,''));
      var num = !isNaN(xn) && !isNaN(yn);
      if (num) return dir==='asc' ? xn-yn : yn-xn;
      return dir==='asc' ? x.localeCompare(y) : y.localeCompare(x);
    });
    rows.forEach(function(r){ tbody.appendChild(r); });
  }
  document.querySelectorAll('table.sortable').forEach(function(t){
    var ths = t.querySelectorAll('thead th');
    ths.forEach(function(th, i){
      th.addEventListener('click', function(){
        var cur = th.getAttribute('aria-sort') || 'none';
        ths.forEach(function(o){ o.setAttribute('aria-sort', 'none'); });
        var next = cur === 'ascending' ? 'descending' : 'ascending';
        th.setAttribute('aria-sort', next);
        sortRows(t.tBodies[0], i, next === 'ascending' ? 'asc' : 'desc');
      });
    });
  });
})();
`;
}
