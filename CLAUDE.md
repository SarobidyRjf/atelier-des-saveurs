# CLAUDE.md

Ce fichier guide Claude Code (claude.ai/code) lorsqu'il travaille sur le code de ce dépôt.

# Projet : L'Atelier des Saveurs — PrestaShop 8.2 + module nk_clickcollect

## Contexte
- Mission d'évaluation (2 semaines). Le cahier des charges complet est dans `docs/cahier_des_charges.pdf` : le relire avant chaque nouvelle fonctionnalité et s'y tenir strictement. Ne rien ajouter qui n'y figure pas ; les bonus (places limitées, AJAX, créneaux complets) seulement quand le périmètre obligatoire est stable et testé.
- Le développeur (Sarobidy) apprend PrestaShop et doit pouvoir **expliquer chaque ligne** en restitution. Travailler en mode pédagogique : avant d'écrire, expliquer brièvement le plan et le « pourquoi » ; après, résumer ce qui a changé et comment le tester. Petites étapes, une à la fois.

## Environnement
- Docker : `docker compose up -d`. Boutique http://localhost:8080, admin `/admin1616`, phpMyAdmin :8081, Mailpit :8025.
- Code versionné : `modules/nk_clickcollect/` et `themes/atelier/` (montés dans le conteneur). Ne jamais modifier le cœur PrestaShop ni le thème `classic`.
- Montage sous WSL : toujours lancer le projet depuis WSL. Si `docker ps` affiche `prestashop … (unhealthy)`, le module ou le thème est vide dans le conteneur (montage cassé) : vérifier avec `docker exec prestashop ls -A modules/nk_clickcollect themes/atelier`, réparer avec `docker compose up -d --force-recreate prestashop`. Vérifier ce point avant de déboguer un « code qui ne s'applique pas ». Arrive aussi après un `git switch` vers une branche où le dossier n'existe pas : Git supprime puis recrée le dossier, et Docker reste branché sur l'ancien. Réflexe : `docker ps` après chaque changement de branche.
- Commandes dans le conteneur : `docker exec prestashop <cmd>`. Vider le cache : `docker exec prestashop rm -rf var/cache/dev var/cache/prod`.
- **Console PrestaShop toujours en `www-data`** : `docker exec -u www-data prestashop php bin/console ...`. Lancée en root, elle reconstruit `var/cache/dev` en root et le back-office tombe en erreur 500 (`appParameters.php` introuvable). Réparation : `docker exec prestashop chown -R www-data:www-data var/cache var/logs`.
- Conteneurs : `prestashop` (PS 8.2, `PS_DEV_MODE=1`, cache dans `var/cache/dev`), `some-mysql` (MySQL 8, préfixe des tables `ps_`), `phpmyadmin`, `mailpit`. Identifiants dans `.env` (copié depuis `.env.example`, non versionné).
- Seuls le module et le thème sont montés depuis l'hôte ; tout le reste de PrestaShop vit dans le volume `psdata` (et la base dans `dbdata`). `docker compose down -v` efface donc la boutique et la base.
- Données catalogue versionnées : `data/dump.sql` (dump complet de la base `prestashop`, 3 catégories / 12 produits) et `data/img-products/` (contenu de `img/p`). Restauration :
  `docker exec -i some-mysql sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' < data/dump.sql`
  `docker cp data/img-products/. prestashop:/var/www/html/img/p/ && docker exec prestashop chown -R www-data:www-data img/p`
  (`backup.sql` et `backup-img/` à la racine sont des sauvegardes locales ignorées par Git.)
- Tests, sans aucune dépendance (pas de PHPUnit/PHPStan/Composer, choix assumé) :
  - Lint : `modules/nk_clickcollect/tests/lint.sh` (`php -l` sur chaque fichier PHP du module, dans le conteneur ; code retour 1 si erreur).
  - Réinstallation : `modules/nk_clickcollect/tests/reinstall.sh` enchaîne install → vérifications → uninstall → vérifications → install → vérifications (module, tables, transporteur actif + `NK_CLICKCOLLECT_CARRIER_REF`, onglet admin, 6 hooks ; après uninstall : tables supprimées, transporteur conservé avec `deleted = 1`, onglet retiré). Les tables étant supprimées à la désinstallation, elles sont **recréées** (vides, puis données de démo à l'étape 5). Couvre l'exigence « y compris après une réinstallation ».
  - Les deux scripts se lancent depuis l'hôte, à la racine du dépôt, avant chaque commit.
  - Parcours client (créneau, erreurs, commande, fiche admin) : scénarios manuels dans `modules/nk_clickcollect/tests/TESTS.md`.

## Sources de vérité (dans cet ordre)
1. Doc officielle PrestaShop **8** : https://devdocs.prestashop-project.org/8/ (jamais la doc 1.6 / 1.7 / 9 sans le signaler).
2. Le code source réel de PS 8.2 dans le conteneur. **Avant d'utiliser un hook, une méthode ou une propriété, vérifier qu'il existe** :
   - hook : `docker exec prestashop grep -rn "Hook::exec('nomDuHook'" classes controllers src`
   - classe : `docker exec prestashop grep -n "function nomMethode\|public \$prop" classes/Xxx.php`
3. Donner l'URL de la doc ou le fichier:ligne du cœur utilisé. Si une info n'est pas vérifiée, le dire explicitement.

## Architecture du module (choix figé, hybride legacy)
Ne pas en dévier sans accord explicite du développeur. Pas de Symfony/Doctrine/Twig ni de Composer.

```
nk_clickcollect/
├── nk_clickcollect.php        classe Nk_Clickcollect extends Module
├── index.php                  protection (un index.php dans CHAQUE dossier)
├── logo.png
├── classes/
│   ├── NkClickCollectSlot.php      ObjectModel : un créneau
│   └── NkClickCollectBooking.php   ObjectModel : lien panier/commande ↔ créneau
├── controllers/admin/
│   └── AdminNkClickCollectSlotsController.php   CRUD créneaux (ModuleAdminController + HelperList/HelperForm)
├── sql/
│   ├── install.php  uninstall.php  demo.php     tables + créneaux de démo
├── views/templates/
│   ├── hook/checkout_slots.tpl  order_confirmation.tpl  admin_order.tpl
├── tests/
│   ├── TESTS.md               scénarios de test manuels à rejouer
│   ├── lint.sh                php -l sur tout le module
│   └── reinstall.sh           test automatisé install → uninstall → réinstall
└── README.md
```
Pas de front controller ni de JS dans le périmètre obligatoire. `controllers/front/slot.php`, `views/js/front.js` et `actionFrontControllerSetMedia` uniquement pour le bonus AJAX.

### Nommage
- Nom technique imposé `nk_clickcollect` (underscore déconseillé par la doc mais imposé par le cahier des charges : choix documenté dans le README). Classe principale `Nk_Clickcollect`, écrite pareil partout.
- Clés de configuration préfixées `NK_CLICKCOLLECT_` (ex. `NK_CLICKCOLLECT_CARRIER_REF`).
- Tables : `_DB_PREFIX_ . 'nk_clickcollect_slot'` et `'nk_clickcollect_booking'`, jamais le préfixe `ps_` en dur.

### Base de données
- `nk_clickcollect_slot` : `id_slot` PK, `slot_date` DATE, `time_start` TIME, `time_end` TIME, `active` TINYINT, `date_add`, `date_upd` (bonus : `capacity` INT).
- `nk_clickcollect_booking` : `id_booking` PK, `id_cart` UNIQUE, `id_order` NULL + INDEX, `id_slot` + INDEX, `date_add`.
- La réservation est liée au panier pendant le checkout, puis rattachée à la commande.

### Transporteur
- Le module crée **son propre** transporteur « Retrait en boutique » à l'installation (`is_module = true`, `external_module_name = 'nk_clickcollect'`, gratuit, zones + groupes associés). Condition pour que `displayCarrierExtraContent` soit appelé (seul le module lié au transporteur reçoit ce hook).
- Stocker son **`id_reference`** (pas l'`id_carrier`, qui change à chaque édition en admin) dans `NK_CLICKCOLLECT_CARRIER_REF`. Comparer les transporteurs via `id_reference`.
- `need_range = true` obligatoire (sinon un transporteur de module est exclu des choix : `classes/Carrier.php:570`) ; `is_free = true` + `shipping_external = false` : le module n'a pas à calculer de frais, donc `extends Module` et non `CarrierModule` (`classes/Cart.php:3787` et `3911`).
- Désinstallation : transporteur passé à `deleted = 1`, jamais supprimé (anciennes commandes liées).
- Doc : https://devdocs.prestashop-project.org/8/modules/carrier/

### Hooks (vérifier chacun dans le code 8.2 avant usage)
| Hook | Rôle |
|---|---|
| `displayCarrierExtraContent` | Afficher les créneaux disponibles sous le transporteur Click & Collect (champ radio dans le formulaire de l'étape livraison) |
| `actionValidateStepComplete` | Validation **serveur** à l'étape livraison : si transporteur C&C, créneau obligatoire et valide, sinon renvoyer `false` + message d'erreur ; enregistrer/mettre à jour la réservation (clé `id_cart`) |
| `actionCarrierUpdate` | Garder la référence du transporteur cohérente si besoin |
| `actionValidateOrder` | Rattacher la réservation à la commande **uniquement si** le transporteur de la commande est le C&C |
| `displayOrderConfirmation` | Rappeler le créneau au client |
| `displayAdminOrderMain` | Afficher le créneau dans la fiche commande admin |

Onglet admin « Click & Collect » via la propriété `$tabs` du module (sous Commandes), retiré à la désinstallation.

### Règles métier côté serveur
Un créneau réservable = existe, `active = 1`, dans le futur (fuseau de la boutique) ; bonus : places restantes. Le panier doit appartenir au client courant (`$this->context->cart`). Un créneau ayant des réservations ne se supprime pas : il se désactive.
- « Maintenant » se calcule toujours en PHP (`date()`, fuseau `PS_TIMEZONE` = Europe/Paris) et se passe à la requête : **jamais `NOW()` en SQL**, MySQL tourne en UTC dans ce conteneur (2 h d'écart).
- Client de test pour les parcours front : `client.test@atelier-des-saveurs.test` / `ClickCollect2026!` (adresse à Paris), créé en base de dev uniquement.

### Ordre de développement (une branche feature par étape)
1. `feature/module-skeleton` : install/uninstall, tables, transporteur, onglet ; tester install → uninstall → réinstall.
2. `feature/admin-slots` : ObjectModel créneau + CRUD admin avec validations (date non passée, fin > début).
3. `feature/checkout-slot` : `displayCarrierExtraContent` + `actionValidateStepComplete`.
4. `feature/order-slot` : `actionValidateOrder`, confirmation, fiche commande admin.
5. `docs/tests-readme` : TESTS.md, README, données de démo.
6. Bonus seulement si 1 à 5 sont stables.

## Code
- Minimal : le moins de code possible qui remplit le cahier des charges. Pas d'abstraction « au cas où », pas de dépendance externe.
- PHP compatible 8.1, standards PrestaShop : pas de `?>` final, garde `if (!defined('_PS_VERSION_')) { exit; }` en tête de chaque fichier PHP, `index.php` de protection dans chaque dossier.
- Documentation : un PHPDoc court sur chaque classe et méthode publique (rôle, paramètres, retour) ; commentaires seulement pour le « pourquoi » non évident. En français.
- Textes affichés traduisibles (`$this->l()` / `{l s='...' mod='nk_clickcollect'}`). Le nom avec underscore empêche `trans()` à domaine, d'où `l()`. Dans le contrôleur admin, `$this->l()` est déprécié en 8.2 : utiliser `$this->module->l('texte', 'AdminNkClickCollectSlotsController')` (méthode `text()` du contrôleur). `l()` échappe le HTML : un nom propre contenant « & » s'écrit sans `l()`.

## Sécurité (obligatoire)
- Entrées : `Tools::getValue()` toujours casté/validé (`(int)`, `Validate::isDate`, etc.). Jamais de donnée utilisateur brute dans du SQL : `(int)`, `pSQL()`, `bqSQL()` ou `DbQuery`.
- Front : vérifier côté serveur que le créneau existe, est actif, futur, non complet, et que le panier appartient au client courant (`$this->context->cart`). Ne jamais faire confiance au JS.
- Admin : utiliser les mécanismes de token des contrôleurs admin ; pas d'action sensible en GET sans token.
- Templates : échapper les sorties (`{$var|escape:'html':'UTF-8'}`).
- Aucun secret, mot de passe, dump de base ou `.env` dans Git.

## Git
- Branches : `main` (restitution) ← `develop` (intégration) ← `feature/<sujet>`, `fix/<sujet>`, `docs/<sujet>`.
- **Jamais de commit ni de push direct sur `main` ou `develop`** : toujours une branche dédiée, puis pull request vers `develop`. La PR finale `develop` → `main` est la PR de restitution.
- Commits au format Conventional Commits, en français : `feat(clickcollect): ...`, `fix(theme): ...`, `docs(readme): ...`, `chore(docker): ...`, `refactor`, `test`. Un commit = une étape cohérente et testée.
- Ne jamais réécrire l'historique partagé (`push --force` interdit).
- Ne jamais committer ou pousser sans que le développeur l'ait demandé.
- Aucune ligne `Co-Authored-By: Claude` dans les commits, ni mention « Generated with Claude Code » dans les PR.
- Le push se fait par Sarobidy (identifiants GitHub) : Claude prépare la branche et le commit, puis donne la commande et le lien de PR.

## Journal de bord : `docs/journal.html`
Bloc-notes quotidien tenu tout au long du projet. Il sert de base au point écrit quotidien et au bilan personnel demandés par le cahier des charges (p.4-5), et fournit le « problème résolu par ses propres recherches » de la restitution.
- Carnet à pages (une visible à la fois, toutes de la même hauteur = écran moins la barre du bas, le surplus défile dans la feuille ; on les tourne avec ‹ ›, les flèches du clavier ou un glissement) : couverture, feuille de route, puis une page par jour. Ajouter un jour = copier le modèle en commentaire **à la fin** du carnet (`<article class="page day" data-date="AAAA-MM-JJ">`) ; numéro, sommaire et ancre `journal.html#AAAA-MM-JJ` sont générés par le script. Sans JS ou à l'impression, toutes les pages s'affichent à la suite.
- Publié pour le manager via GitHub Pages (dossier `/docs` de la branche `develop`) : https://sarobidyrjf.github.io/atelier-des-saveurs/journal.html (`#AAAA-MM-JJ` pour un jour précis). Le site se met à jour à chaque merge dans `develop` ; un jour sans merge d'étape, publier via une petite branche `docs/journal-JJMM` + PR. Le dépôt étant **public**, tout ce qui est dans `docs/` est publié : rien d'interne (le cahier des charges PDF est dans `.gitignore`).
- Rubriques de chaque jour : **Fait** (avec preuve : commit, test), **Erreurs & résolutions** (message exact, cause, solution, source doc/fichier:ligne), **Blocages**, **Prochaine étape**, **Avis** (ressenti, ce qu'on a appris).
- La mettre à jour à chaque fin d'étape ou dès qu'une erreur est résolue, sans attendre la fin de journée. Faits vérifiables uniquement : ne rien inventer, laisser « à compléter » ce que seul Sarobidy sait.
- Section « Feuille de route » : une case par tâche (boutique, étapes 1 à 6 du module, livrables). Cocher = ajouter la classe `done` au `<li class="task">` avec la preuve (`<code class="proof">hash</code>`), uniquement quand la tâche est réellement terminée et testée. Barre de progression et tampons « à faire / en cours / fait » sont calculés par le script inline.
- Vérifier le rendu sans installer de navigateur (Chrome headless dans un conteneur jetable) :
  `docker run --rm -v "$PWD/docs":/docs:ro -v <dossier_sortie>:/out zenika/alpine-chrome --no-sandbox --hide-scrollbars --window-size=1280,2400 --virtual-time-budget=5000 --screenshot=/out/journal.png file:///docs/journal.html` (390 de large pour le mobile ; le dossier de sortie doit être accessible en écriture).
- Design « carnet papier » : polices Google Fonts (Caveat, Patrick Hand), logo `docs/img/prestashop-logo.png` (copié depuis `modules/psgdpr/views/img/` du conteneur). Pas d'autre dépendance ; versionné dans Git (commit `docs(journal): ...`).

## Definition of done d'une étape
1. Le code fonctionne dans le conteneur (le tester réellement, dire comment).
2. `tests/lint.sh` passe ; `tests/reinstall.sh` passe si l'étape touche l'install, les tables ou le transporteur.
3. README mis à jour si l'installation, les choix techniques ou les tests changent.
4. `docs/journal.html` mis à jour (fait, erreurs/résolutions, prochaine étape).
5. Commit sur la branche de fonctionnalité.
