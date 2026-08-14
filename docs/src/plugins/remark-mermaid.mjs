import { visit } from 'unist-util-visit';

const escapeHtml = (value) =>
  value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

/**
 * Transforme les blocs ```mermaid en `<pre class="mermaid">`, que le script
 * de `src/components/Head.astro` rend côté client. On garde la source telle
 * quelle dans le `<pre>` : mermaid la lit via `textContent`, ce qui déséchappe
 * les entités au passage.
 */
export function remarkMermaid() {
  return (tree) => {
    visit(tree, 'code', (node, index, parent) => {
      if (node.lang !== 'mermaid' || !parent || index === undefined) return;
      parent.children[index] = {
        type: 'html',
        value: `<pre class="mermaid">${escapeHtml(node.value)}</pre>`,
      };
    });
  };
}
