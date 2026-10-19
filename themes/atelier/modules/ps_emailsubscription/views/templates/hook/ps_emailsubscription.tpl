{**
 * Bloc d'inscription à la lettre d'information, mis à la forme de la maquette :
 * un panneau en deux colonnes, texte à gauche, formulaire à droite.
 *
 * Le gabarit de Classic n'a aucun {block}, il est donc recopié et réorganisé.
 * TOUT ce que le module attend côté serveur est conservé à l'identique :
 * l'identifiant #blockEmailSubscription_{$hookName} (cible de l'ancre après
 * envoi), l'action du formulaire, les champs « email », « submitNewsletter »,
 * « blockHookName » et « action », les messages, et les deux hooks
 * displayNewsletterRegistration et displayGDPRConsent (consentement RGPD).
 *
 * Ce qui change : la mise en page, un intitulé visible au-dessus du champ
 * (la maquette en a un, et c'est mieux pour l'accessibilité qu'un simple
 * texte d'invite), et la classe col-xs-12 au lieu de col-lg-8 pour occuper
 * toute la largeur. Attention : Classic est en Bootstrap 4 ALPHA, où la
 * classe sans point de rupture s'écrit « col-xs-12 » ; « col-12 » n'existe
 * pas et l'élément ne serait pas une colonne.
 *
 * La maquette annonce « 25 % de remise sur votre première commande » : c'est
 * une offre fictive du modèle, la boutique n'en propose pas. Le texte est
 * donc le vrai propos du bloc.
 *}
<div class="block_newsletter col-xs-12" id="blockEmailSubscription_{$hookName}">
  <div class="atelier-newsletter">

    <div class="atelier-newsletter-text">
      <p class="atelier-newsletter-eyebrow">{l s='La lettre de l\'atelier' d='Shop.Theme.Global'}</p>
      <h2 class="atelier-newsletter-title">
        {l s='Les nouveautés' d='Shop.Theme.Global'}
        <span>{l s='avant tout le monde' d='Shop.Theme.Global'}</span>
      </h2>
      <p class="atelier-newsletter-lead" id="block-newsletter-label">
        {l s='Nos arrivages, nos recettes de saison et nos créneaux de retrait, une fois par mois. Désinscription en un clic.' d='Shop.Theme.Global'}
      </p>
    </div>

    <form class="atelier-newsletter-form"
          action="{$urls.current_url}#blockEmailSubscription_{$hookName}"
          method="post">
      <label class="atelier-newsletter-label" for="atelier-newsletter-{$hookName}">
        {l s='Votre adresse e-mail' d='Shop.Forms.Labels'}
      </label>
      <input
        id="atelier-newsletter-{$hookName}"
        name="email"
        type="email"
        value="{$value}"
        placeholder="{l s='prenom.nom@exemple.fr' d='Shop.Forms.Labels'}"
        aria-labelledby="block-newsletter-label"
        required
      >

      <input type="hidden" name="blockHookName" value="{$hookName}">
      <input type="hidden" name="action" value="0">

      {if isset($id_module)}
        {hook h='displayGDPRConsent' id_module=$id_module}
      {/if}
      {hook h='displayNewsletterRegistration'}

      <button class="btn atelier-newsletter-btn" name="submitNewsletter" type="submit" value="1">
        {l s='Je m\'inscris' d='Shop.Theme.Actions'}
      </button>

      {if $conditions}
        <p class="atelier-newsletter-conditions">{$conditions}</p>
      {/if}
      {if $msg}
        <p class="alert {if $nw_error}alert-danger{else}alert-success{/if}">{$msg}</p>
      {/if}
    </form>

  </div>
</div>
