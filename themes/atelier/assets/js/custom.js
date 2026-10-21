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

  // Identifiants des étapes dont le GABARIT pose un bouton (addresses.tpl,
  // shipping.tpl). Le script ne recrée un bouton que là : il restaure ce
  // qu'un rechargement partiel a emporté, il n'en invente pas (ni à l'étape
  // Paiement, ni sur une étape encore inaccessible).
  var etapesAvecRetour = [];

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
      var retour = etape.querySelector('.atelier-step-back');
      if (retour && retour.textContent.trim()) {
        libelle = retour.textContent.trim();
        if (etapesAvecRetour.indexOf(etape.id) === -1) {
          etapesAvecRetour.push(etape.id);
        }
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

      var continuer = etape.querySelector('.continue');

      // Déjà en place : on ne réinstalle pas (et on n'empile pas d'écouteur).
      if (continuer && continuer.parentNode.classList.contains('atelier-step-actions')) {
        return;
      }

      if (!retour) {
        var contenu = etape.querySelector('.content');
        if (!libelle || !contenu || etapesAvecRetour.indexOf(etape.id) === -1) {
          return;
        }
        retour = document.createElement('button');
        retour.type = 'button';
        retour.className = 'btn btn-secondary atelier-step-back';
        retour.textContent = libelle;
        // Dans .content et non dans la <section> : Classic masque .content
        // quand l'étape n'est pas la courante, le bouton disparaît avec.
        contenu.appendChild(retour);
      }

      // « onclick = » et non addEventListener : la fonction est rejouée à
      // chaque rechargement partiel, une affectation remplace l'écouteur au
      // lieu d'en empiler un de plus.
      retour.onclick = function () {
        titrePrecedent.click();
      };

      // Une étape peut n'avoir AUCUN bouton « Continuer » : l'étape Livraison
      // n'en émet pas quand aucun transporteur ne dessert l'adresse du client
      // (themes/classic/.../steps/shipping.tpl:110, branche {if $delivery_options}).
      // Le bouton « Précédent » reste alors seul, mais fonctionnel — c'est
      // précisément le moment où le client en a besoin.
      if (!continuer) {
        retour.classList.add('atelier-step-back-seul');
        return;
      }

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
