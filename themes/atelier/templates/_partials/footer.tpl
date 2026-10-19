{**
 * Pied de page du thème « atelier ».
 *
 * On hérite du pied de page de Classic et on ajoute une seule ligne à la fin
 * du bloc de copyright, avec le drapeau « append ».
 *
 * Cette ligne n'est pas décorative : la licence du modèle FoodMart
 * (TemplatesJungle), dont le design de ce thème s'inspire, impose de
 * conserver un lien de crédit vers templatesjungle.com. Aucun fichier du
 * modèle n'est repris dans ce dépôt ; seules les valeurs de la charte
 * graphique ont été reproduites dans assets/css/custom.css.
 *}
{extends file='parent:_partials/footer.tpl'}

{block name='copyright_link' append}
  <span class="atelier-credit">
    {l s='Design inspiré de FoodMart —' d='Shop.Theme.Global'}
    <a href="https://templatesjungle.com/" target="_blank" rel="noopener noreferrer nofollow">TemplatesJungle</a>
  </span>
{/block}
