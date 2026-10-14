#!/usr/bin/env node
// Builds a Devin-compatible PT-BR language pack from Microsoft's official VS Code pack.
// The upstream pack is retained with its license and notices; only localization metadata
// and Devin-specific strings are added.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');

const [sourceDir, targetDir] = process.argv.slice(2);
const appVersion = process.env.DEVIN_APP_VERSION || '1.0.0';
if (!sourceDir || !targetDir) {
  console.error('Uso: node build-language-pack.cjs <pasta-extraida-do-vsix> <pasta-de-saida>');
  process.exit(2);
}
const srcExt = path.join(sourceDir, 'extension');
const outExt = path.join(targetDir, 'extension');
fs.rmSync(targetDir, { recursive: true, force: true });
fs.mkdirSync(targetDir, { recursive: true });
fs.cpSync(srcExt, outExt, { recursive: true });
for (const entry of fs.readdirSync(sourceDir)) {
  if (entry !== 'extension' && entry !== '.signature.p7s') {
    fs.cpSync(path.join(sourceDir, entry), path.join(targetDir, entry), { recursive: true });
  }
}

const metadataPath = process.env.DEVIN_NLS_METADATA || path.resolve(process.env.LOCALAPPDATA || '', 'Programs', 'Devin', 'resources', 'app', 'out', 'nls.metadata.json');
if (!fs.existsSync(metadataPath)) throw new Error(`Metadados NLS do Devin não encontrados: ${metadataPath}`);
const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
const keysPath = process.env.DEVIN_NLS_KEYS || path.resolve(process.env.LOCALAPPDATA || '', 'Programs', 'Devin', 'resources', 'app', 'out', 'nls.keys.json');
if (!fs.existsSync(keysPath)) throw new Error(`Índices NLS do Devin não encontrados: ${keysPath}`);
const nlsKeys = new Map();
let globalNlsIndex = 0;
for (const [moduleId, keys] of JSON.parse(fs.readFileSync(keysPath, 'utf8'))) {
  nlsKeys.set(moduleId, new Map(keys.map((key, index) => [key, globalNlsIndex + index])));
  globalNlsIndex += keys.length;
}
const runtimeMessagesPath = process.env.DEVIN_NLS_MESSAGES || path.resolve(process.env.LOCALAPPDATA || '', 'Programs', 'Devin', 'resources', 'app', 'out', 'nls.messages.json');
if (!fs.existsSync(runtimeMessagesPath)) throw new Error(`Mensagens NLS do Devin não encontradas: ${runtimeMessagesPath}`);
const runtimeMessages = JSON.parse(fs.readFileSync(runtimeMessagesPath, 'utf8'));
const extraPath = path.resolve(__dirname, '..', 'translations', 'devin.json');
const extra = JSON.parse(fs.readFileSync(extraPath, 'utf8'));
const supplementalPath = path.resolve(__dirname, '..', 'translations', 'devin-complemento.json');
const supplemental = JSON.parse(fs.readFileSync(supplementalPath, 'utf8'));
for (const [moduleId, entries] of Object.entries(supplemental)) {
  extra[moduleId] = { ...(extra[moduleId] || {}), ...entries };
}
const mainPath = path.join(outExt, 'translations', 'main.i18n.json');
const main = JSON.parse(fs.readFileSync(mainPath, 'utf8'));
const pkgPath = path.join(outExt, 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
const baseVersion = pkg.version;
if (baseVersion !== appVersion) {
  throw new Error(`A versão da base PT-BR (${baseVersion}) não corresponde ao Devin instalado (${appVersion}). Use um pacote-base da mesma versão para preservar os índices NLS.`);
}
const mapped = {};
for (const [moduleId, entryKeys] of Object.entries(metadata.keys)) {
  const entries = entryKeys.map(item => typeof item === 'string' ? item : item.key);
  const source = metadata.messages[moduleId] || [];
  const base = main.contents[moduleId] || {};
  const moduleExtras = extra[moduleId] || {};
  const localized = {};
  for (const [localIndex, key] of entries.entries()) {
    const nlsIndex = nlsKeys.get(moduleId)?.get(key);
    const official = nlsIndex === undefined ? undefined : runtimeMessages[nlsIndex];
    const sourceText = source[localIndex];
    // Existing numeric catalogs are accepted only as an input for migration.
    // Devin's shipped loader reads contents[moduleId][key], never local indices.
    const translated = moduleExtras[key] ?? base[key] ?? base[String(localIndex)] ?? official;
    if (typeof translated === 'string' && translated.length && translated !== sourceText) {
      localized[key] = translated;
    }
  }
  if (Object.keys(localized).length) mapped[moduleId] = localized;
}
main.contents = mapped;
const credit = '\r\nTradução PT-BR: Emerson Teles';
for (const [moduleId, keys] of nlsKeys) {
  const localIndex = (metadata.keys[moduleId] || []).findIndex((item) => (typeof item === 'string' ? item : item.key) === 'aboutDetail');
  if (localIndex < 0) continue;
  const about = mapped[moduleId]?.aboutDetail;
  if (about && !about.includes('Tradução PT-BR: Emerson Teles')) mapped[moduleId].aboutDetail = about + credit;
}
fs.writeFileSync(mainPath, JSON.stringify(main));

pkg.name = 'devin-language-pack-pt-br';
pkg.displayName = 'Tradução PT-BR para Devin — Emerson Teles';
pkg.description = 'Pacote PT-BR adaptado para Devin Desktop, com base no pacote oficial Microsoft VS Code.';
pkg.publisher = 'EmersonTeles';
pkg.version = appVersion;
const revision = crypto.createHash('sha256');
for (const file of [__filename, extraPath, supplementalPath, path.resolve(__dirname, '..', 'translations', 'embedded-ui.json'), path.resolve(__dirname, 'patch-embedded-ui.cjs'), path.resolve(__dirname, 'vendor', 'acorn.cjs')]) {
  revision.update(fs.readFileSync(file));
}
pkg.devinTranslationRevision = revision.digest('hex');
pkg.engines.vscode = '^1.126.0';
const localization = pkg.contributes.localizations.find(item => item.languageId.toLowerCase() === 'pt-br');
if (localization) {
  localization.languageName = 'Portuguese (Brazil)';
  localization.localizedLanguageName = 'português (Brasil)';
}
fs.writeFileSync(pkgPath, JSON.stringify(pkg));

const manifestPath = path.join(targetDir, 'extension.vsixmanifest');
let manifest = fs.readFileSync(manifestPath, 'utf8');
manifest = manifest.replace(/<Identity\s+([^>]*?)\s*\/>/, (_m, attrs) => {
  attrs = attrs.replace(/Publisher="[^"]*"/, 'Publisher="EmersonTeles"')
    .replace(/Version="[^"]*"/, `Version="${appVersion}"`)
    .replace(/Id="[^"]*"/, 'Id="devin-language-pack-pt-br"');
  return `<Identity ${attrs} />`;
});
manifest = manifest.replace(/Value="\^1\.128\.0"/g, 'Value="^1.126.0"');
manifest = manifest.replace(/<DisplayName>[^<]*<\/DisplayName>/, '<DisplayName>Tradução PT-BR para Devin — Emerson Teles</DisplayName>');
manifest = manifest.replace(/(LocalizedLanguages" Value=")[^"]*(")/, '$1português (Brasil)$2');
fs.writeFileSync(manifestPath, manifest);

console.log('Pacote PT-BR para Devin preparado.');



