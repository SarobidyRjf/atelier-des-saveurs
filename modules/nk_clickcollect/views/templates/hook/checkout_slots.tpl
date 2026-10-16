{**
 * Créneaux de retrait affichés sous le transporteur « Retrait en boutique »
 * (hook displayCarrierExtraContent). Les boutons radio font partie du formulaire
 * de l'étape livraison : le créneau choisi est envoyé avec « Continuer » et validé côté serveur.
 *}
<div class="nk-clickcollect">
  <p class="h6">{l s='Choisissez votre créneau de retrait en boutique' mod='nk_clickcollect'}</p>
  {if $nk_slots}
    <ul class="list-unstyled">
      {foreach $nk_slots as $slot}
        <li>
          <label for="nk_clickcollect_slot_{$slot.id|intval}">
            {* Même balisage que les boutons radio des transporteurs du thème Classic (shipping.tpl:46) *}
            <span class="custom-radio">
              <input type="radio" name="nk_clickcollect_slot" id="nk_clickcollect_slot_{$slot.id|intval}"
                     value="{$slot.id|intval}"{if $slot.id == $nk_selected_slot} checked{/if}>
              <span></span>
            </span>
            {$slot.date|escape:'html':'UTF-8'} — {$slot.start|escape:'html':'UTF-8'} – {$slot.end|escape:'html':'UTF-8'}
          </label>
        </li>
      {/foreach}
    </ul>
  {else}
    <p class="alert alert-warning">{l s='Aucun créneau de retrait n\'est disponible pour le moment.' mod='nk_clickcollect'}</p>
  {/if}
</div>
