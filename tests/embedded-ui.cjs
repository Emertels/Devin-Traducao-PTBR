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
  `const resources = JSON.parse('{"nav":{"spaces":"Spaces","automations":"Automations","cloudSettings":"Cloud settings"}}');`,
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
const values = vm.runInNewContext(patched + ';({resources, object, pattern:pattern.source, tip, label})');
assert.equal(values.resources.nav.spaces, 'Espaços');
assert.equal(values.resources.nav.automations, 'Automações');
assert.equal(values.resources.nav.cloudSettings, 'Configurações da nuvem');
assert.equal(values.object.Sessions, 'Sessões');
assert.equal(values.pattern, '"Sessions"');
assert.equal(values.tip, 'Dica: Novo espaço');
assert.equal(values.label, 'Ir para a lista de sessões');
const second = JSON.parse(execFileSync(process.execPath, [helper, dictionary, output, path.join(temp, 'second.js')], { encoding: 'utf8' }));
assert.equal(second.changed, false);
console.log('OK: recursos JSON, chaves de objeto, regex, comentários, templates e reaplicação.');
