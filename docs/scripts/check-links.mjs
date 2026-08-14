#!/usr/bin/env node
// Vérifie les liens internes et les ancres du site construit.
// Starlight ne le fait pas : une page renommée casse silencieusement les liens.
//
// Usage : node scripts/check-links.mjs [répertoire dist]

import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';

const root = resolve(process.argv[2] ?? 'dist');

if (!existsSync(root)) {
  console.error(`Répertoire introuvable : ${root} — lancer le build d'abord.`);
  process.exit(2);
}

const pages = [];
(function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) walk(path);
    else if (entry.endsWith('.html')) pages.push(path);
  }
})(root);

const route = (path) => '/' + path.slice(root.length + 1).replace(/index\.html$/, '');

// Les identifiants disponibles sur chaque page, pour valider les ancres.
const anchors = new Map(
  pages.map((path) => [
    route(path),
    new Set(
      [...readFileSync(path, 'utf8').matchAll(/\sid="([^"]+)"/g)].map((m) => m[1]),
    ),
  ]),
);

let problems = 0;

for (const path of pages) {
  const html = readFileSync(path, 'utf8');
  const from = route(path);

  for (const [, target, hash] of html.matchAll(/href="(\/[^"#]*)(#[^"]*)?"/g)) {
    if (target.startsWith('/_astro') || target.startsWith('/pagefind')) continue;

    // Fichier statique servi tel quel (favicon, image…).
    if (!target.endsWith('/') && existsSync(join(root, target))) continue;

    const page = target.endsWith('/') ? target : target + '/';
    if (!anchors.has(page)) {
      console.log(`LIEN MORT    ${from} -> ${target}`);
      problems++;
      continue;
    }

    if (hash) {
      const id = decodeURIComponent(hash.slice(1));
      if (!anchors.get(page).has(id)) {
        console.log(`ANCRE MORTE  ${from} -> ${target}${hash}`);
        problems++;
      }
    }
  }
}

if (problems > 0) {
  console.log(`\n${problems} problème(s) sur ${pages.length} pages.`);
  process.exit(1);
}

console.log(`OK — ${pages.length} pages, 0 lien mort, 0 ancre morte.`);
