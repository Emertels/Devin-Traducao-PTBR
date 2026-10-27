const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const vm = require('node:vm');
const { execFileSync } = require('node:child_process');
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'devin-ui-check-'));
const input = path.join(temp, 'input.js');
const output = path.join(temp, 'output.js');
const helper = path.resolve(__dirname, '../tools/patch-embedded-ui.cjs');
const dictionary = path.resolve(__dirname, '../translations/embedded-ui.json');
fs.writeFileSync(input, [
  `const resources = JSON.parse('{"nav":{"spaces":"Spaces","automations":"Automations","cloudSettings":"Cloud settings"},"shortAgo":"{{count}}d ago"}');`,
  'const welcome = "Congrats on starting your first session!";',
  'const recovery = "Session is too old to be revived. Please start a new session.";',
  'const action = "Open customizations";',
  `const object = {"Sessions": "Sessions"};`,
  'const pattern = /"Sessions"/;',
  'const tip = `Tip: ${"New space"}`;',
  '// "Sessions" must remain in this comment.',
  'const label = "Go to sessions list";'
].join('\n'));
const result = JSON.parse(execFileSync(process.execPath, [helper, dictionary, input, output], { encoding: 'utf8' }));
assert.ok(result.changed);
const patched = fs.readFileSync(output, 'utf8');
assert.ok(patched.includes('// "Sessions" must remain'));
const values = vm.runInNewContext(patched + ';({resources, welcome, recovery, action, object, pattern:pattern.source, tip, label})');
assert.equal(values.resources.nav.spaces, 'Espaços');
assert.equal(values.resources.nav.automations, 'Automações');
assert.equal(values.resources.nav.cloudSettings, 'Configurações da nuvem');
assert.equal(values.resources.shortAgo, 'há {{count}} dias');
assert.equal(values.welcome, 'Parabéns por iniciar sua primeira sessão!');
assert.equal(values.recovery, 'Esta sessão é antiga demais para ser retomada. Inicie uma nova sessão.');
assert.equal(values.action, 'Abrir personalizações');
assert.equal(values.object.Sessions, 'Sessões');
assert.equal(values.pattern, '"Sessions"');
assert.equal(values.tip, 'Dica: Novo espaço');
assert.equal(values.label, 'Ir para a lista de sessões');
const portugueseBundle = path.join(temp, 'pt-C9gxajH_.js');
fs.writeFileSync(portugueseBundle, 'const localeText = "Sessions";');
const otherLocaleBundle = path.join(temp, 'es-DoaNSjW8.js');
fs.writeFileSync(otherLocaleBundle, 'const localeText = "Sessions";');
const scan = JSON.parse(execFileSync(process.execPath, [helper, dictionary, '--scan', temp], { encoding: 'utf8' }));
assert.ok(scan.candidates.includes(input), 'A varredura dinâmica deve localizar bundles com strings do catálogo.');
assert.ok(scan.candidates.includes(portugueseBundle), 'Bundles do idioma português também precisam ser traduzidos.');
assert.ok(!scan.candidates.includes(otherLocaleBundle), 'Bundles de outros idiomas devem permanecer intactos.');
const localeOutput = path.join(temp, 'pt-output.js');
const localeResult = JSON.parse(execFileSync(process.execPath, [helper, dictionary, portugueseBundle, localeOutput], { encoding: 'utf8' }));
assert.ok(localeResult.changed, 'O bundle português que contém um rótulo inglês deve ser corrigido.');
assert.equal(fs.readFileSync(localeOutput, 'utf8'), 'const localeText = "Sessões";');
const second = JSON.parse(execFileSync(process.execPath, [helper, dictionary, output, path.join(temp, 'second.js')], { encoding: 'utf8' }));
assert.equal(second.changed, false);
console.log('OK: recursos JSON, chaves de objeto, regex, comentários, templates e reaplicação.');
