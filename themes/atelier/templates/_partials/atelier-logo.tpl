{**
 * Logo de la boutique : le nom écrit en toutes lettres, précédé d'un
 * pictogramme SVG.
 *
 * Écrit une fois ici puis inclus par templates/_partials/header.tpl et
 * templates/checkout/_partials/header.tpl, pour ne pas le dupliquer.
 *
 * Pourquoi du texte et pas une image : rien de binaire à versionner, et la
 * boutique est identique après restauration du dump, sans téléversement.
 * Le nom vient de la configuration ($shop.name), pas du gabarit.
 *
 * La balise est un <h1> sur l'accueil uniquement (c'est le titre principal
 * de la page), un <div> ailleurs : même règle que Classic. Le pied de page
 * passe « dans_pied=true » : sinon l'accueil aurait deux <h1>.
 *
 * Le lien vise $urls.pages.index (comme le renderLogo de Classic,
 * _partials/helpers.tpl) et non $urls.base_url : avec plusieurs langues,
 * seul le premier garde le préfixe de langue (/en/).
 *}
{assign var='logo_titre' value=($page.page_name == 'index' && empty($dans_pied))}
{if $logo_titre}<h1 class="atelier-logo-wrapper">{else}<div class="atelier-logo-wrapper">{/if}
  <a class="atelier-logo" href="{$urls.pages.index}" title="{$shop.name|escape:'html':'UTF-8'}">
    <svg class="atelier-logo-mark" width="34" height="34" viewBox="0 0 34 34" aria-hidden="true" focusable="false">
      <circle cx="17" cy="17" r="16" fill="#FFC43F"/>
      <path d="M11 9v8a3 3 0 0 0 3 3v5M14 9v6M11 24h6M22 9c-1.7 1.6-2.5 3.9-2.5 6.5S20.3 20.4 22 22v3" stroke="#222" stroke-width="1.8" fill="none" stroke-linecap="round"/>
    </svg>
    <span class="atelier-logo-text">{$shop.name|escape:'html':'UTF-8'}</span>
  </a>
{if $logo_titre}</h1>{else}</div>{/if}
