{**
 * Pied de page du thème « atelier ».
 *
 * On hérite de celui de Classic et on ne touche qu'à deux blocs :
 *
 *  - « hook_footer » reçoit en TÊTE (drapeau « prepend ») une colonne
 *    d'identité — logo et une phrase sur la boutique — comme la première
 *    colonne du pied de page de la maquette. Le reste de la rangée vient
 *    des modules (ps_linklist, ps_customeraccountlinks, ps_contactinfo) et
 *    n'est pas touché : la disposition en colonnes est faite en CSS.
 *
 *  - « copyright_link » reçoit EN FIN le crédit du modèle. Ce n'est pas
 *    décoratif : la licence de FoodMart (TemplatesJungle), dont le design
 *    s'inspire, impose de conserver ce lien. Aucun fichier du modèle n'est
 *    repris ici ; seules les valeurs de sa charte ont été reproduites.
 *
 * Le logo est le même gabarit que dans les deux en-têtes, écrit une seule
 * fois dans _partials/atelier-logo.tpl.
 *}
{extends file='parent:_partials/footer.tpl'}

{block name='hook_footer' prepend}
  <div class="atelier-footer-brand">
    {include file='_partials/atelier-logo.tpl' dans_pied=true}
    <p class="atelier-footer-baseline">
      {l s='Confitures, miels, huiles et condiments préparés en petites quantités, à retirer gratuitement en boutique au créneau de votre choix.' d='Shop.Theme.Global'}
    </p>
    <a class="atelier-footer-pickup" href="{$urls.pages.stores}">
      <i class="material-icons" aria-hidden="true">storefront</i>
      {l s='Retrait en boutique gratuit' d='Shop.Theme.Global'}
    </a>
  </div>
{/block}

{block name='copyright_link' append}
  <span class="atelier-credit">
    {l s='Design inspiré de FoodMart —' d='Shop.Theme.Global'}
    <a href="https://templatesjungle.com/" target="_blank" rel="noopener noreferrer nofollow">TemplatesJungle</a>
  </span>
{/block}
