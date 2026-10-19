{**
 * Étape « shipping » du tunnel de commande.
 *
 * On hérite de celle de Classic et on n'ajoute qu'un bouton « Précédent ».
 *
 * Pourquoi ici et pas directement à côté de « Continuer » : ce bouton-là est
 * à l'intérieur du formulaire de l'étape, hors de portée du bloc que l'on
 * peut compléter. Le libellé est donc écrit ici — pour rester traduisible —
 * et assets/js/custom.js le déplace ensuite à côté de « Continuer ».
 *}
{extends file='parent:checkout/_partials/steps/shipping.tpl'}

{block name='step_content' append}
  <button type="button" class="btn btn-secondary atelier-step-back">
    {l s='Précédent' d='Shop.Theme.Actions'}
  </button>
{/block}
