{**
 * En-tête du tunnel de commande.
 *
 * Le tunnel n'utilise PAS templates/_partials/header.tpl : il a son propre
 * en-tête allégé (ni menu ni recherche, pour ne pas distraire le client).
 * On en hérite et on ne redéfinit que le bloc header_nav, pour y mettre
 * notre logo à la place de {renderLogo}.
 *
 * Les ancres #_desktop_logo / #_mobile_logo, #_mobile_cart,
 * #_mobile_user_info et #menu-icon sont reprises telles quelles : le JS de
 * Classic s'en sert pour basculer l'affichage en mobile.
 *}
{extends file='parent:checkout/_partials/header.tpl'}

{block name='header_nav'}
  <nav class="header-nav">
    <div class="container">
      <div class="row">
        <div class="col-md-6 hidden-sm-down" id="_desktop_logo">
          {include file='_partials/atelier-logo.tpl'}
        </div>
        <div class="col-md-6 text-xs-right hidden-sm-down">
          {hook h='displayNav1'}
        </div>
        <div class="hidden-md-up text-sm-center mobile">
          {hook h='displayNav2'}
          <div class="float-xs-left" id="menu-icon">
            <i class="material-icons">&#xE5D2;</i>
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
