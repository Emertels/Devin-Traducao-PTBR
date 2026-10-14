#!/usr/bin/env node
const fs = require('node:fs');
const [metadataPath, catalogPath] = process.argv.slice(2);
if (!metadataPath || !catalogPath) {
  console.error('Uso: node audit-catalog.cjs <nls.metadata.json> <main.i18n.json>');
  process.exit(2);
}
const metadata = JSON.parse(fs.readFileSync(metadataPath, 'utf8'));
const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8')).contents;
const runtimePath = process.env.DEVIN_NLS_MESSAGES || require('node:path').resolve(process.env.LOCALAPPDATA || '', 'Programs', 'Devin', 'resources', 'app', 'out', 'nls.messages.json');
const runtime = JSON.parse(fs.readFileSync(runtimePath, 'utf8'));
const keysPath = process.env.DEVIN_NLS_KEYS || require('node:path').resolve(process.env.LOCALAPPDATA || '', 'Programs', 'Devin', 'resources', 'app', 'out', 'nls.keys.json');
const nlsKeys = new Map();
let globalNlsIndex = 0;
for (const [moduleId, keys] of JSON.parse(fs.readFileSync(keysPath, 'utf8'))) { nlsKeys.set(moduleId, new Map(keys.map((key, index) => [key, globalNlsIndex + index]))); globalNlsIndex += keys.length; }
let total = 0;
let translated = 0;
const missing = [];
for (const [moduleId, entryKeys] of Object.entries(metadata.keys)) {
  const entries = entryKeys.map(item => typeof item === 'string' ? item : item.key);
  const source = metadata.messages[moduleId] || [];
  const localized = catalog[moduleId] || {};
  entries.forEach((key, index) => {
    const runtimeIndex = nlsKeys.get(moduleId)?.get(key) ?? -1;
    const text = runtimeIndex >= 0 ? runtime[runtimeIndex] : source[index];
    if (typeof text !== 'string' || !text.trim()) return;
    total++;
    // Match the lookup in the shipped Devin loader: contents[moduleId][key].
    const localizedText = localized[key];
    if (typeof localizedText === 'string' && localizedText.length && localizedText !== text) translated++;
    else missing.push({ module: moduleId, key, text });
  });
}
console.log(`Cobertura direta de chaves: ${translated}/${total} (${(translated / total * 100).toFixed(1)}%)`);
console.log(`Lacunas: ${missing.length}`);
const invalid = [];
for (const [moduleId, entries] of Object.entries(catalog)) {
  const validKeys = nlsKeys.get(moduleId);
  for (const key of Object.keys(entries)) {
    if (!validKeys?.has(key)) invalid.push(`${moduleId}\t${key}`);
  }
}
if (invalid.length) {
  console.error(`Catálogo incompatível: ${invalid.length} chaves não reconhecidas pelo carregador NLS.`);
  process.exitCode = 1;
}
if (!process.argv.includes('--summary')) {
  for (const item of missing) console.log(`${item.module}\t${item.key}\t${item.text.replace(/\s+/g, ' ')}`);
}






