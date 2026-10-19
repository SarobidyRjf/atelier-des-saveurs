/**
 * Thème « atelier » — seul script du thème.
 * Chargé automatiquement par le cœur avec la priorité 1000, donc après le
 * theme.js de Classic (classes/controller/FrontController.php:989).
 *
 * Rôle unique : placer le bouton « Précédent » des étapes du tunnel à côté du
 * bouton « Continuer », et le relier à l'étape précédente.
 *
 * Le bouton est produit par un gabarit (pour que son libellé reste
 * traduisible) mais atterrit en fin de contenu d'étape, car « Continuer » est
 * dans le formulaire. On le déplace donc ici.
 *
 * Le retour en arrière ne réinvente rien : il déclenche un clic sur le titre
 * de l'étape précédente, exactement ce que fait un visiteur qui clique
 * dessus. C'est le mécanisme de Classic (themes/classic/assets/js/theme.js,
 * qui écoute les « .js-step-title »).
 */
document.addEventListener('DOMContentLoaded', function () {
  document.querySelectorAll('.checkout-step .atelier-step-back').forEach(function (retour) {
    var etape = retour.closest('.checkout-step');
    var precedente = etape ? etape.previousElementSibling : null;

    // Pas d'étape avant celle-ci : le bouton n'a pas de sens, on le retire.
    if (!precedente || !precedente.classList.contains('checkout-step')) {
      retour.remove();
      return;
    }

    var titrePrecedent = precedente.querySelector('.js-step-title');
    var continuer = etape.querySelector('.continue');
    if (!titrePrecedent || !continuer) {
      retour.remove();
      return;
    }

    // On encadre les deux boutons pour les afficher côte à côte.
    var barre = document.createElement('div');
    barre.className = 'atelier-step-actions';
    continuer.parentNode.insertBefore(barre, continuer);
    barre.appendChild(retour);
    barre.appendChild(continuer);

    retour.addEventListener('click', function () {
      titrePrecedent.click();
    });
  });
});
