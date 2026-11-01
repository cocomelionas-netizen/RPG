// Builds the public site into dist/: the game's code is minified and its names mangled,
// so the shipped page is small and hard to copy and rework. Run: npm run build
const fs = require('fs'), path = require('path');
const { minify } = require('terser');
const out = 'dist';
fs.rmSync(out, { recursive: true, force: true });
fs.mkdirSync(out);
(async () => {
  let html = fs.readFileSync('index.html', 'utf8');
  const open = html.lastIndexOf('<script>'), close = html.indexOf('</script>', open);
  const src = html.slice(open + 8, close);
  const res = await minify(src, { compress: { passes: 2 }, mangle: { toplevel: true }, toplevel: true, format: { comments: false, preamble: '/* Endless Road (c) 2026 cocomelionas. All rights reserved. */' } });
  if (!res.code) throw new Error('minify failed');
  html = html.slice(0, open + 8) + res.code + html.slice(close);
  html = html.replace(/<style>([\s\S]*?)<\/style>/, (m, css) => '<style>' + css.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\s*\n\s*/g, '\n').trim() + '</style>');
  fs.writeFileSync(path.join(out, 'index.html'), html);
  for (const f of ['manifest.json', 'sw.js', 'icon-180.png', 'icon-192.png', 'icon-512.png', 'sql.html', 'LICENSE']) fs.copyFileSync(f, path.join(out, f));
  fs.copyFileSync('supabase/schema.sql', path.join(out, 'schema.txt'));
  fs.writeFileSync(path.join(out, '_headers'), '/schema.txt\n  Content-Type: text/plain; charset=utf-8\n  Content-Disposition: inline\n');
  for (const d of ['models', 'lib']) fs.cpSync(d, path.join(out, d), { recursive: true });
  console.log(`built ${out}/: index.html ${Math.round(Buffer.byteLength(html) / 1024)} KB (code ${Math.round(src.length / 1024)} KB -> ${Math.round(res.code.length / 1024)} KB)`);
})().catch(e => { console.error(e); process.exit(1); });
