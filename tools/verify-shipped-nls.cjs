#!/usr/bin/env node
// Controlled replay of the NLS generator copied from the installed Devin main.js.
// Does not start Electron or modify the user's installation, profile or caches.
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const [outDir, catalogPath] = process.argv.slice(2);
if (!outDir || !catalogPath) throw new Error('Uso: node verify-shipped-nls.cjs <out-do-Devin> <main.i18n.json>');
const main = fs.readFileSync(path.join(outDir, 'main.js'), 'utf8');
const match = /async function ([\w$]+)\(\{userLocale:/.exec(main);
if (!match) throw new Error('Carregador NLS não encontrado nesta compilação.');
const start = match.index;
const end = main.indexOf('Lc();it("code/didStartMain")', start);
if (end < 0) throw new Error('Limite do carregador NLS não encontrado nesta compilação.');
const source = main.slice(start, end);
const load = vm.runInNewContext(source + `;${match[1]}`, {
  process: { env: {} },
  console,
  it: () => {},
  B: path.join,
  zo: fs.promises,
  oe: { exists: async p => { try { await fs.promises.access(p); return true; } catch { return false; } } }
});
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'devin-nls-replay-'));
fs.writeFileSync(path.join(root, 'languagepacks.json'), JSON.stringify({
  'pt-br': { hash: 'controlled-replay', translations: { vscode: path.resolve(catalogPath) } }
}));
(async () => {
  const config = await load({ userLocale: 'pt-br', osLocale: 'pt-br', userDataPath: root, commit: 'shipped-loader', nlsMetadataPath: path.resolve(outDir) });
  assert.equal(config.resolvedLanguage, 'pt-br');
  const actual = JSON.parse(fs.readFileSync(config.languagePack.messagesFile, 'utf8'));
  const original = JSON.parse(fs.readFileSync(path.join(outDir, 'nls.messages.json'), 'utf8'));
  assert.equal(actual.length, original.length);
  const required = [
    ['More Actions...', 'Mais Ações...'],
    ['Devin Account', 'Conta Devin'],
    ['Devin Usage', 'Uso do Devin'],
    ['Open Keyboard Shortcuts', 'Abrir Atalhos de Teclado'],
    ['Join the Community', 'Participar da comunidade'],
    ['Profiles', 'Perfis']
  ];
  for (const [english, portuguese] of required) {
    const index = original.indexOf(english);
    assert.ok(index >= 0, `Mensagem ausente na compilação: ${english}`);
    assert.equal(actual[index], portuguese, `Mensagem não traduzida pelo carregador: ${english}`);
  }
  const aboutIndex = original.findIndex(text => text.startsWith('Devin Desktop Version: {0}'));
  assert.ok(aboutIndex >= 0);
  const about = actual[aboutIndex];
  assert.ok(about.startsWith('Versão do Devin Desktop: {0}'));
  assert.ok(about.includes('Versão do VS Code OSS: {2}'));
  assert.ok(about.includes('Data: {3}'));
  assert.equal(about.split('Tradução PT-BR: Emerson Teles').length - 1, 1);
  const count = actual.filter((text, index) => text !== original[index]).length;
  assert.ok(count > 19000, `Cobertura insuficiente no carregador: ${count}`);
  console.log(JSON.stringify({ resolvedLanguage: config.resolvedLanguage, translated: count, total: actual.length, about, loaderSHA256: crypto.createHash('sha256').update(source).digest('hex'), messagesFile: config.languagePack.messagesFile }, null, 2));
})().catch(error => { console.error(error.message); process.exitCode = 1; });
