#!/usr/bin/env node
// Tokenize JavaScript so strings in comments, regexes and templates stay distinct.
const fs = require('node:fs');
const path = require('node:path');
const acorn = require('./vendor/acorn.cjs');
const args = process.argv.slice(2);
const [dictionaryPath, inputPath, outputPath] = args;
if (!dictionaryPath) throw new Error('Uso: node patch-embedded-ui.cjs <dicionário> <entrada.js> <saída.js> | --scan <dicionário> <pasta>');
const dictionary = JSON.parse(fs.readFileSync(dictionaryPath, 'utf8'));
const localizedValues = new Set(Object.values(dictionary));
if (inputPath === '--scan') {
  const roots = args.slice(2);
  if (!roots.length) throw new Error('Informe uma ou mais pastas para varrer.');
  const needles = Object.keys(dictionary).filter(key => key.length >= 4).flatMap(key => [`"${key}"`, `'${key}'`, `\`${key}\``]);
  const candidates = [];
  function inspect(file) {
    if (!file.endsWith('.js')) return;
    const source = fs.readFileSync(file, 'utf8');
    // Do not overwrite the app's separately bundled non-English locales.
    // Keep the Brazilian Portuguese bundles in scope; skip only other locale chunks.
    if (/^(?!pt-)[a-z]{2}-[A-Za-z0-9_]{8,}\.js$/.test(path.basename(file))) return;
    if (needles.some(needle => source.includes(needle))) candidates.push(file);
  }
  function walk(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const file = path.join(directory, entry.name);
      if (entry.isDirectory()) walk(file);
      else if (entry.isFile()) inspect(file);
    }
  }
  for (const root of roots) if (fs.existsSync(root)) fs.statSync(root).isDirectory() ? walk(root) : inspect(root);
  console.log(JSON.stringify({ candidates: [...new Set(candidates)].sort() }));
  process.exit(0);
}
if (!inputPath || !outputPath) throw new Error('Uso: node patch-embedded-ui.cjs <dicionário> <entrada.js> <saída.js> | --scan <dicionário> <pasta>');
const source = fs.readFileSync(inputPath, 'utf8');
const patches = [];
let matchCount = 0;
const matchedKeys = new Set();
function translateStringOrJson(value) {
  let translated = translateValue(value);
  // Devin ships some UI catalogs as JSON inside JavaScript template literals.
  // Translate only catalog values; keys are identifiers and must stay stable.
  if (typeof translated === 'string' && translated.trimStart().startsWith('{')) {
    try {
      const parsed = JSON.parse(translated);
      const before = JSON.stringify(parsed);
      const after = JSON.stringify(translateValue(parsed));
      if (after !== before) translated = after;
    } catch { /* A regular template/string is not a JSON resource. */ }
  }
  return translated;
}
function translateValue(value) {
  if (typeof value === 'string') {
    if (Object.hasOwn(dictionary, value)) { matchCount++; matchedKeys.add(value); return dictionary[value]; }
    if (localizedValues.has(value)) { matchCount++; matchedKeys.add(Object.keys(dictionary).find(key => dictionary[key] === value)); }
    return value;
  }
  if (Array.isArray(value)) return value.map(translateValue);
  if (value && typeof value === 'object') {
    for (const key of Object.keys(value)) value[key] = translateValue(value[key]);
  }
  return value;
}
let pending;
function inspect(token, next) {
  if (!token) return;
  if (token.type.label === 'string') {
    // Never rename object keys, even when they happen to match a UI label.
    if (next.type.label === ':') return;
    const value = translateStringOrJson(token.value);
    if (value !== token.value) patches.push({ start: token.start, end: token.end, text: JSON.stringify(value) });
  } else if (token.type.label === 'template' && typeof token.value === 'string') {
    const value = translateStringOrJson(token.value);
    if (value !== token.value) {
      const raw = JSON.stringify(value).slice(1, -1).replace(/`/g, '\\`').replace(/\$\{/g, '\\${');
      patches.push({ start: token.start, end: token.end, text: raw });
    }
  }
}
for (const token of acorn.tokenizer(source, { ecmaVersion: 'latest', sourceType: 'module', allowHashBang: true })) {
  inspect(pending, token);
  pending = token;
}
inspect(pending, { type: { label: 'eof' } });
const chunks = [];
let offset = 0;
for (const patch of patches) {
  chunks.push(source.slice(offset, patch.start), patch.text);
  offset = patch.end;
}
chunks.push(source.slice(offset));
const changed = patches.length > 0;
if (changed) fs.writeFileSync(outputPath, chunks.join(''));
console.log(JSON.stringify({ changed, matchCount, matchedKeys: [...matchedKeys], patches: patches.length }));
