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
 *
 * POURQUOI LA POSE EST REJOUÉE : à l'étape « Adresses », « Continuer » se
 * trouve à l'intérieur de <div class="js-address-form">, que themes/core.js
 * remplace intégralement quand le client change de pays. Notre barre et le
 * bouton qu'on y avait déplacé disparaissent avec. On réinstalle donc après
 * chaque rechargement, en recréant le bouton s'il a été emporté.
 */
(function () {
  'use strict';

  // Libellé repris du gabarit au premier passage, pour pouvoir recréer le
  // bouton à l'identique sans écrire de texte en dur dans ce fichier.
  var libelle = '';

  function etapePrecedente(etape) {
    var precedente = etape.previousElementSibling;
    while (precedente && !precedente.classList.contains('checkout-step')) {
      precedente = precedente.previousElementSibling;
    }
    return precedente;
  }

  function installerBoutonsRetour() {
    // Barres laissées vides par un rechargement partiel.
    document.querySelectorAll('.atelier-step-actions').forEach(function (barre) {
      if (!barre.querySelector('.continue')) {
        barre.remove();
      }
    });

    document.querySelectorAll('.checkout-step').forEach(function (etape) {
      var continuer = etape.querySelector('.continue');
      if (!continuer) {
        return;
      }

      var retour = etape.querySelector('.atelier-step-back');
      if (retour && retour.textContent.trim()) {
        libelle = retour.textContent.trim();
      }

      var precedente = etapePrecedente(etape);
      var titrePrecedent = precedente ? precedente.querySelector('.js-step-title') : null;

      // Première étape : un bouton « Précédent » n'aurait pas de sens.
      if (!titrePrecedent) {
        if (retour) {
          retour.remove();
        }
        return;
      }

      // Déjà en place : on ne réinstalle pas (et on n'empile pas d'écouteur).
      if (continuer.parentNode.classList.contains('atelier-step-actions')) {
        return;
      }

      if (!retour) {
        if (!libelle) {
          return;
        }
        retour = document.createElement('button');
        retour.type = 'button';
        retour.className = 'btn btn-secondary atelier-step-back';
        retour.textContent = libelle;
      }

      retour.addEventListener('click', function () {
        titrePrecedent.click();
      });

      var barre = document.createElement('div');
      barre.className = 'atelier-step-actions';
      continuer.parentNode.insertBefore(barre, continuer);
      barre.appendChild(retour);
      barre.appendChild(continuer);
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    installerBoutonsRetour();

    // Évènements émis par le cœur après un rechargement partiel du tunnel.
    if (window.prestashop && typeof window.prestashop.on === 'function') {
      window.prestashop.on('updatedAddressForm', installerBoutonsRetour);
      window.prestashop.on('updatedDeliveryForm', installerBoutonsRetour);
    }
  });
})();
