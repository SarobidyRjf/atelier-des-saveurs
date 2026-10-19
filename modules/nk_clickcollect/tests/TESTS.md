# Scénarios de test — module nk_clickcollect

Ces scénarios se rejouent à la main, dans le navigateur. Pour chacun : suivre les étapes, comparer avec l'attendu, cocher **OK** ou **KO**.
Rejouer **T0 à T11 après une réinstallation du module** (exigence du cahier des charges : « y compris après une réinstallation »).

## Pré-requis
- Boutique lancée et module installé (voir le `README.md` à la racine du dépôt) ; `docker ps` affiche `prestashop … (healthy)`.
- Back-office : http://localhost:8080/admin1616 (identifiants du fichier `.env`). Boutique : http://localhost:8080.
- Un compte client avec une adresse en France (création décrite dans le README). Paiement : « Payer par chèque ».
- Créneaux de démo (créés à l'installation) : 7 jours à partir de demain, 10:00–12:00 et 14:00–16:00 ; **le créneau de J+2 14:00–16:00 est inactif**. Pour les régénérer (dates dépassées, données modifiées) : relancer `modules/nk_clickcollect/tests/reinstall.sh`.
- Les tests de l'admin se font dans **Commandes > Click & Collect**.

## Tests automatisés (à lancer avant chaque commit, depuis la racine du dépôt)
| Commande | Vérifie |
|---|---|
| `modules/nk_clickcollect/tests/lint.sh` | syntaxe PHP de tout le module (dans le conteneur) |
| `modules/nk_clickcollect/tests/reinstall.sh` | install → uninstall → réinstall : module, tables, 14 créneaux de démo, transporteur, onglet, hooks |

Attendu : « Lint : aucune erreur. » puis « Réinstallation : tous les contrôles sont OK. » (code retour 0). Attention : `reinstall.sh` vide les tables et recrée la démo.

---

## T0 — Installation, désinstallation, réinstallation
1. Lancer `tests/lint.sh` puis `tests/reinstall.sh`.
2. Dans le back-office : Commandes > Click & Collect, la liste contient 14 créneaux.

**Attendu** : les deux scripts passent ; 14 créneaux, dont 1 inactif ; le transporteur « Retrait en boutique » est visible dans Livraison > Transporteurs. ☐ OK ☐ KO

## T1 — Admin : lister, créer, modifier, activer/désactiver
1. Cliquer sur **Ajouter un créneau** : date dans 10 jours, début `09:00`, fin `10:00`, Actif = Oui. Enregistrer.
2. Modifier ce créneau : fin `10:30`. Enregistrer.
3. Cliquer sur la coche (ou la croix) de la colonne **Actif**.

**Attendu** : message de confirmation à chaque action ; le créneau apparaît avec `09:00` / `10:30` ; la colonne Actif bascule ; la liste est triée par date puis heure ; colonne **Réservations** = 0. ☐ OK ☐ KO

## T2 — Admin : refus de saisies invalides
Dans le formulaire d'ajout, tenter successivement (chaque cas doit être refusé avec un message, la saisie restant affichée) :
- date d'hier ; date `2026-9-30` (passée, écrite sans zéro) ;
- fin avant le début ; fin égale au début ;
- heure `25:00` ; heure `abc` ; heures vides ; date vide.

**Attendu** : aucun créneau créé ; messages en français avec les libellés « Date », « Heure de début », « Heure de fin » (jamais `slot_date`). ☐ OK ☐ KO

## T3 — Admin : créneau réservé
Pré-requis : avoir passé la commande de T6 (créneau réservé, colonne Réservations = 1).
1. Cliquer sur **Supprimer** sur ce créneau.
2. Modifier sa date, puis son heure de début : Enregistrer.
3. Le ré-enregistrer sans rien changer ; puis basculer seulement « Actif ».

**Attendu** : suppression refusée (« désactivez-le au lieu de le supprimer ») ; changement de date/heure refusé (« désactivez-le et créez-en un autre ») ; ré-enregistrement identique et bascule « Actif » acceptés. ☐ OK ☐ KO

## T4 — Checkout : affichage des créneaux
1. Se connecter, ajouter un produit, **Commander**, confirmer l'adresse.
2. À l'étape Mode de livraison, choisir **Retrait en boutique**.
3. Choisir un créneau, **Continuer**, puis revenir en arrière sur l'étape livraison.

**Attendu** : les créneaux actifs et futurs s'affichent sous « Retrait en boutique » (le créneau inactif de J+2 14:00 n'y figure pas) ; ils sont absents sous les autres transporteurs ; le créneau choisi est pré-coché au retour. ☐ OK ☐ KO

## T5 — Checkout : refus côté serveur
Avec « Retrait en boutique » sélectionné, cliquer sur **Continuer** dans chaque cas :
1. Aucun créneau choisi.
2. Créneau inexistant : dans les outils du navigateur (F12 > Éléments), remplacer la `value` d'un bouton radio `nk_clickcollect_slot` par `99999`, puis choisir ce bouton.
3. Créneau inactif : même manipulation avec l'identifiant du créneau inactif (colonne ID de la liste admin).
4. Valeur piégée : remplacer la `value` par `abc'; DROP TABLE x` (ne doit rien casser).

**Attendu** : on reste sur l'étape Mode de livraison avec un message d'erreur rouge (« Veuillez choisir un créneau… » ou « Ce créneau n'est plus disponible… ») ; aucune erreur SQL ; les tables sont intactes. ☐ OK ☐ KO

## T6 — Commande complète en Click & Collect
1. Choisir **Retrait en boutique** et un créneau valide, **Continuer**, payer par chèque, valider la commande.
2. Sur la page de confirmation, lire le bloc « Retrait en boutique ».
3. Dans le back-office, ouvrir Commandes > Commandes, puis cette commande.
4. Dans phpMyAdmin (http://localhost:8081), table `ps_nk_clickcollect_booking`.

**Attendu** : la confirmation indique la date et les heures du créneau ; la fiche commande a une carte **Click & Collect** (créneau de retrait : date, heures) ; la ligne de réservation a `id_order` rempli ; la colonne Réservations du créneau passe à 1. ☐ OK ☐ KO

## T7 — Commande avec un autre transporteur
1. Passer une commande avec le transporteur **Click and collect** (ancien, avec « and ») ou « My carrier », sans créneau.

**Attendu** : commande acceptée sans erreur ; aucun bloc de créneau sur la confirmation ; aucune carte dans la fiche commande ; aucune ligne de réservation pour cette commande. ☐ OK ☐ KO

## T8 — Changement de transporteur après le choix d'un créneau
1. Choisir « Retrait en boutique » + un créneau, **Continuer**.
2. Revenir à l'étape livraison, choisir un autre transporteur, **Continuer**, payer.
3. Regarder la colonne Réservations du créneau et la table `ps_nk_clickcollect_booking`.

**Attendu** : la commande n'a pas de créneau ; la réservation orpheline est supprimée ; le créneau n'est pas compté comme réservé. ☐ OK ☐ KO

## T9 — Transporteur modifié en back-office
1. Livraison > Transporteurs : modifier « Retrait en boutique » (par exemple son délai) et enregistrer (PrestaShop crée un nouveau transporteur avec un nouvel identifiant).
2. Refaire une commande comme en T6.

**Attendu** : « Retrait en boutique » reste proposé avec ses créneaux ; la commande est bien rattachée au créneau (même résultat qu'en T6). ☐ OK ☐ KO

## T10 — Après réinstallation
1. Lancer `tests/reinstall.sh`.
2. Rejouer T1, T4, T5 et T6.

**Attendu** : mêmes résultats qu'avant ; les 14 créneaux de démo sont recréés (les créneaux saisis à la main et les réservations ont disparu : c'est voulu). ☐ OK ☐ KO

## T11 — Sécurité
1. Copier l'adresse d'une action de la liste admin (par exemple Supprimer), retirer le paramètre `token=…`, l'ouvrir.

**Attendu** : sans jeton valide, PrestaShop affiche la page « Clé de sécurité invalide » (avec un bouton « Je comprends les risques… » qu'il ne faut **pas** cliquer) et n'exécute pas l'action : le créneau n'est pas supprimé. ☐ OK ☐ KO

Note : les créneaux ne contiennent que des dates et des heures validées côté serveur (pas de texte libre) ; les valeurs affichées sont de toute façon échappées dans les templates.

---

## Limites connues (comportements attendus, pas des anomalies)
- Un créneau désactivé ou dépassé **entre** l'étape livraison et le paiement n'empêche pas la commande.
- Le créneau n'est pas modifiable après la commande.
- La désinstallation supprime les réservations : les anciennes commandes n'affichent plus leur créneau.
