{**
 * Carte « Click & Collect » dans la fiche commande du back-office (hook displayAdminOrderMain).
 * Même balisage que les autres cartes de la fiche commande (classes card, card-header, card-body).
 *}
<div class="card mt-2">
  <div class="card-header">
    <h3 class="card-header-title">Click &amp; Collect</h3>
  </div>
  <div class="card-body">
    <p class="mb-0">
      {l s='Créneau de retrait :' mod='nk_clickcollect'}
      <strong>{$nk_slot.date|escape:'html':'UTF-8'}</strong>,
      {$nk_slot.start|escape:'html':'UTF-8'} – {$nk_slot.end|escape:'html':'UTF-8'}
    </p>
  </div>
</div>
