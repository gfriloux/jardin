// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { remarkMermaid } from './src/plugins/remark-mermaid.mjs';

export default defineConfig({
  markdown: {
    remarkPlugins: [remarkMermaid],
  },
  vite: {
    // mermaid n'est chargé que par un import dynamique, donc Vite ne le
    // découvre qu'à la première page contenant un diagramme. Il re-optimise
    // alors ses dépendances, et la page déjà chargée demande un hash périmé :
    // l'import répond 504 et aucun diagramme ne s'affiche. Le pré-déclarer
    // force le pré-bundling au démarrage du serveur.
    optimizeDeps: { include: ['mermaid'] },
  },
  integrations: [
    starlight({
      title: 'Jardin',
      description:
        "Réseau de télémétrie du terrain : sondes d'humidité du sol, LoRa, et à terme irrigation automatisée.",
      defaultLocale: 'root',
      locales: {
        root: { label: 'Français', lang: 'fr' },
      },
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/gfriloux/jardin',
        },
      ],
      customCss: ['./src/styles/custom.css'],
      components: {
        Head: './src/components/Head.astro',
      },
      sidebar: [
        { slug: 'index', label: 'Accueil' },
        {
          label: 'Le projet',
          items: [
            'projet/contexte',
            'projet/feuille-de-route',
            'projet/principes',
            'projet/modele-de-donnees',
          ],
        },
        {
          label: 'Matériel',
          items: [
            'materiel/inventaire',
            'materiel/risques',
            'materiel/coque-des-sondes',
            'materiel/photos',
          ],
        },
        {
          label: 'Objectifs',
          items: [
            'objectifs/o0-socle',
            'objectifs/o1-une-sonde',
            'objectifs/o2-multiplexage',
            'objectifs/o3-calibration',
            'objectifs/o4-lien-radio',
            'objectifs/o5-chaine-de-donnees',
            'objectifs/o6-autonomie',
            'objectifs/o7-mise-au-jardin',
            'objectifs/o8-exploitation',
            'objectifs/o9-irrigation',
          ],
        },
        { label: 'Décisions', items: ['decisions'] },
      ],
      lastUpdated: true,
      pagination: true,
      editLink: {
        baseUrl: 'https://github.com/gfriloux/jardin/edit/main/docs/',
      },
    }),
  ],
});
