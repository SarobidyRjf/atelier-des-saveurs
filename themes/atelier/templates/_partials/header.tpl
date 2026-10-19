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
 * (themes/classic/assets/js/theme.js, sélecteur *[id^='_desktop_']) et
 * #menu-icon bascule #mobile_top_menu_wrapper. Toutes ces ancres sont
 * reprises ci-dessous, sinon le menu et le panier meurent sur mobile.
 *}
{extends file='parent:_partials/header.tpl'}

{* Niveau contact de Classic : vidé de sa partie desktop, remontée au
   niveau 1. On garde la rangée mobile, qui reçoit le logo et le panier. *}
{block name='header_nav'}
  <nav class="header-nav">
    <div class="container">
      <div class="row">
        <div class="hidden-md-up text-sm-center mobile">
          <div class="float-xs-left" id="menu-icon">
            <i class="material-icons d-inline">&#xE5D2;</i>
          </div>
          <div class="float-xs-right" id="_mobile_cart"></div>
          <div class="float-xs-right" id="_mobile_user_info"></div>
          <div class="top-logo" id="_mobile_logo"></div>
          <div class="clearfix"></div>
        </div>
      </div>
    </div>
  </nav>
{/block}

{block name='header_top'}
  <div class="header-top">
    <div class="container">
      <div class="header-top-right atelier-header-row">
        <div class="hidden-sm-down" id="_desktop_logo">
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

      {* Conteneurs du menu mobile : remplis par le JS de Classic. *}
      <div id="mobile_top_menu_wrapper" class="row hidden-md-up" style="display:none;">
        <div class="js-top-menu mobile" id="_mobile_top_menu"></div>
        <div class="js-top-menu-bottom">
          <div id="_mobile_currency_selector"></div>
          <div id="_mobile_language_selector"></div>
          <div id="_mobile_contact_link"></div>
        </div>
      </div>
    </div>
  </div>
  {hook h='displayNavFullWidth'}
{/block}
