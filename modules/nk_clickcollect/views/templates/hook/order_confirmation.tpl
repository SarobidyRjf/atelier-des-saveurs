{**
 * Rappel du créneau de retrait sur la page de confirmation de commande (hook displayOrderConfirmation).
 *}
<div class="nk-clickcollect-confirmation">
  <p class="h6">{l s='Retrait en boutique' mod='nk_clickcollect'}</p>
  <p>
    {l s='Votre commande vous attend le' mod='nk_clickcollect'}
    <strong>{$nk_slot.date|escape:'html':'UTF-8'}</strong>,
    {l s='de' mod='nk_clickcollect'} {$nk_slot.start|escape:'html':'UTF-8'}
    {l s='à' mod='nk_clickcollect'} {$nk_slot.end|escape:'html':'UTF-8'}.
  </p>
</div>
