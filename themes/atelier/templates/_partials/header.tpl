{**
 * En-tête du thème « atelier », sur DEUX niveaux comme la maquette :
 *   niveau 1 : logo · recherche · « Une question ? » · compte · panier
 *   niveau 2 : menu des rayons · « Retrait en boutique gratuit »
 *
 * Classic en a trois (un bandeau contact séparé au-dessus). On ne change
 * PAS l'affectation des hooks en base — elle est héritée de Classic et tous
 * les modules du front en dépendent — on appelle simplement les mêmes hooks
 * depuis un seul conteneur, et le CSS fait les deux lignes :
 *   displayNav1  = coordonnées (ps_contactinfo)
 *   displayNav2  = compte, panier, langue, devise
 *   displayTop   = barre de recherche PUIS menu principal
 * Comme displayTop rend les deux d'un bloc, le conteneur est une GRILLE CSS
 * et chaque enfant est posé dans une zone nommée : le placement est alors
 * déterministe, là où un flex qui se replie changeait de disposition selon
 * la largeur du contenu (le nom du client connecté, par exemple).
 *
 * RÈGLE À NE PAS ENFREINDRE : le JS de Classic échange le contenu de tout
 * « #_desktop_xxx » avec celui de son jumeau « #_mobile_xxx »
 * (themes/classic/assets/js/theme.js, sélecteur *[id^='_desktop_']). Ces
 * ancres sont reprises ci-dessous, sinon le menu et le panier meurent sur
 * mobile.
 *
 * Sur mobile, l'en-tête se réduit au pictogramme du logo et à la recherche
 * (tout le reste de .header-top est hidden-sm-down) ; la navigation passe
 * dans une barre fixée en bas de l'écran (.atelier-bottom-nav). On y pose
 * #_mobile_user_info et #_mobile_cart, où le JS de Classic déplace le
 * compte et le panier. Le
 * panier reste à jour en AJAX : le module remplace « .blockcart » où qu'il
 * se trouve. Les rayons sont regroupés sous un seul onglet « Boutique ».
 * #_desktop_logo n'a pas de jumeau #_mobile_logo : le JS de Classic le
 * laisse donc en place, et il reste visible sur mobile.
 * Conséquence assumée : pas d'emplacement mobile pour la langue et la
 * devise (une seule de chaque, sélecteurs non rendus).
 *}
{extends file='parent:_partials/header.tpl'}

{* Niveau contact de Classic : sa partie desktop est remontée au niveau 1,
   sa partie mobile (logo, compte, panier) est répartie entre .header-top
   et la barre du bas. Il n'a donc plus rien à afficher. *}
{block name='header_nav'}{/block}

{block name='header_top'}
  <div class="header-top">
    <div class="container">
      <div class="header-top-right atelier-header-row">
        <div id="_desktop_logo">
          {include file='_partials/atelier-logo.tpl'}
        </div>

        {* Barre de recherche (niveau 1) + menu principal (niveau 2). *}
        {hook h='displayTop'}

        <div class="atelier-header-aside hidden-sm-down">
          {hook h='displayNav1'}
          {hook h='displayNav2'}
        </div>

        <a class="atelier-pickup-link hidden-sm-down" href="{$urls.pages.stores}">
          <i class="material-icons" aria-hidden="true">storefront</i>
          {l s='Retrait en boutique gratuit' d='Shop.Theme.Global'}
        </a>
      </div>

    </div>
  </div>

  {* Barre de navigation mobile, fixée en bas : Accueil, Boutique, Retrait,
     compte et panier. Les deux ancres « _mobile_ » sont remplies par le JS
     de Classic. *}
  <nav class="atelier-bottom-nav hidden-md-up" aria-label="{l s='Menu principal' d='Shop.Theme.Global'}">
    {* Icônes seules : le libellé est porté par « title » (bulle au survol)
       et « aria-label » (nom du lien pour les lecteurs d'écran, l'icône
       étant aria-hidden). *}
    <a class="atelier-bottom-nav-link{if $page.page_name == 'index'} current{/if}" href="{$urls.pages.index}"
       title="{l s='Accueil' d='Shop.Theme.Global'}" aria-label="{l s='Accueil' d='Shop.Theme.Global'}">
      <i class="material-icons" aria-hidden="true">home</i>
    </a>
    {* Un seul onglet pour tous les rayons : la catégorie racine (id 2, même
       lien que « Découvrir la boutique » de l'accueil) liste les
       sous-catégories et tous les produits. *}
    <a class="atelier-bottom-nav-link{if $page.page_name == 'category'} current{/if}" href="{url entity='category' id=2}"
       title="{l s='Boutique' d='Shop.Theme.Global'}" aria-label="{l s='Boutique' d='Shop.Theme.Global'}">
      <i class="material-icons" aria-hidden="true">category</i>
    </a>
    <a class="atelier-bottom-nav-link{if $page.page_name == 'stores'} current{/if}" href="{$urls.pages.stores}"
       title="{l s='Retrait en boutique' d='Shop.Theme.Global'}" aria-label="{l s='Retrait en boutique' d='Shop.Theme.Global'}">
      <i class="material-icons" aria-hidden="true">storefront</i>
    </a>
    <div id="_mobile_user_info"></div>
    <div id="_mobile_cart"></div>
  </nav>
  {hook h='displayNavFullWidth'}
{/block}
