# L'Atelier des Saveurs — PrestaShop 8.2 + module `nk_clickcollect`

Boutique de démonstration PrestaShop 8.2 (Docker) et module **Click & Collect** : le client qui choisit « Retrait en boutique » sélectionne un créneau de retrait, validé côté serveur, enregistré avec la commande et visible dans l'administration.

Ce dépôt contient :
- `modules/nk_clickcollect/` : le module (code, scénarios de test, README du module) ;
- `themes/atelier/` : le thème enfant de la boutique (design inspiré de FoodMart) ;
- `data/` : le catalogue de démonstration (`dump.sql`, images des produits) ;
- `docker-compose.yml`, `.env.example` : l'environnement ;
- `docs/journal.html` : le journal de bord du projet.

## Prérequis
- Docker et Docker Compose v2.
- Windows : lancer toutes les commandes **depuis WSL** (le montage des dossiers est cassé sinon).
- Ports libres : 8080 (boutique), 8081 (phpMyAdmin), 8025 (Mailpit).

## Lancement

```bash
cp .env.example .env          # puis adapter les mots de passe si besoin (ne jamais commiter .env)
docker compose up -d
```

Au premier démarrage, PrestaShop s'installe tout seul (quelques minutes). Attendre que `docker ps` affiche `prestashop … (healthy)` et que http://localhost:8080 réponde.
Si `prestashop` reste `(unhealthy)`, voir « Dépannage ».

### Charger le catalogue de démonstration (versionné dans `data/`)

```bash
docker exec -i some-mysql sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' < data/dump.sql
docker cp data/img-products/. prestashop:/var/www/html/img/p/
docker exec prestashop chown -R www-data:www-data img/p
docker exec prestashop rm -rf var/cache/dev var/cache/prod
docker exec prestashop chown -R www-data:www-data var/cache var/logs
```

Deux conséquences de cette restauration (le dump remplace toute la base) :
- **Garder `PS_PORT=8080`** dans `.env` : le dump enregistre l'adresse de la boutique `localhost:8080`, un autre port provoque des redirections vers le port 8080.
- **Le compte administrateur est celui du dump**, pas celui de `.env` : le réinitialiser avec les identifiants de `.env` (déjà présents dans l'environnement du conteneur) :

```bash
docker exec -u www-data prestashop php -r 'require "/var/www/html/config/config.inc.php"; $e = new Employee(1); $e->email = getenv("ADMIN_MAIL"); $e->passwd = (new PrestaShop\PrestaShop\Core\Crypto\Hashing())->hash(getenv("ADMIN_PASSWD"), _COOKIE_KEY_); $e->last_passwd_gen = date("Y-m-d H:i:s", strtotime("-1 day")); echo $e->update() ? "admin mis à jour\n" : "échec\n";'
```

### Installer le module

Le catalogue ne contient pas le module : l'installer avec la console PrestaShop (**toujours en `www-data`**, sinon le cache est reconstruit en root et le back-office tombe en erreur 500).

```bash
docker exec -u www-data prestashop php bin/console prestashop:module install nk_clickcollect
```

Le message « L'action Install sur le module nk_clickcollect a réussi » confirme l'installation. Le module crée ses deux tables, le transporteur **Retrait en boutique**, l'onglet **Commandes > Click & Collect** et **14 créneaux de démonstration** (7 jours à partir de demain, 2 par jour, dont 1 inactif).

### Activer le thème de la boutique

Le thème enfant `atelier` est dans le dépôt mais n'est pas actif par défaut. L'activer (console **toujours en `www-data`**), puis vider le cache :

```bash
docker exec -u www-data prestashop php bin/console prestashop:theme:enable atelier
docker exec prestashop rm -rf var/cache/dev var/cache/prod
docker exec prestashop chown -R www-data:www-data var/cache var/logs
```

Le dossier `themes/atelier/assets/cache/` doit appartenir à `www-data` : le cœur y écrit les feuilles de style concaténées, et il est monté depuis l'hôte. Si l'accueil renvoie `Failed to create ".../assets/cache/": mkdir(): Permission denied` :

```bash
docker exec prestashop chown -R www-data:www-data themes/atelier/assets/cache
```

### Accès
| Service | Adresse |
|---|---|
| Boutique | http://localhost:8080 |
| Back-office | http://localhost:8080/admin1616 (identifiants `ADMIN_MAIL` / `ADMIN_PASSWD` de `.env`) |
| phpMyAdmin | http://localhost:8081 (tables du module : `ps_nk_clickcollect_slot`, `ps_nk_clickcollect_booking`) |
| Mailpit (e-mails de la boutique) | http://localhost:8025 |

### Créer un compte client de test
Les scénarios de test ont besoin d'un client avec une adresse en France.
1. Ouvrir http://localhost:8080, cliquer sur **Connexion > Pas de compte ? Créez-en un**.
2. Remplir le formulaire (n'importe quel e-mail fictif et un mot de passe de votre choix).
3. Lors de la première commande, saisir une adresse en France (ex. : 10 rue de Rivoli, 75001 Paris).

Aucun mot de passe de test n'est versionné dans le dépôt.

## Tester

Depuis la racine du dépôt :

```bash
modules/nk_clickcollect/tests/lint.sh        # syntaxe PHP du module, dans le conteneur
modules/nk_clickcollect/tests/reinstall.sh   # install → désinstallation → réinstallation, avec vérifications
```

`reinstall.sh` vide les tables du module puis les recrée avec les créneaux de démo : c'est aussi la façon de **régénérer les créneaux** quand leurs dates sont dépassées.

Les parcours client et administrateur (créer un créneau, choisir un créneau, erreurs, commande, fiche commande, après réinstallation) sont décrits pas à pas dans [modules/nk_clickcollect/tests/TESTS.md](modules/nk_clickcollect/tests/TESTS.md).

## Choix techniques

| Choix | Raison |
|---|---|
| Module « hybride legacy » : `ObjectModel`, `HelperList`/`HelperForm`, hooks. Ni Symfony, ni Composer | périmètre simple, un seul style, code explicable ligne par ligne |
| Nom technique `nk_clickcollect` (avec underscore) | imposé par le cahier des charges ; la doc PrestaShop le déconseille |
| `$this->l()` pour les traductions | l'underscore empêche `trans()` avec domaine |
| Le module crée **son propre** transporteur « Retrait en boutique » (`is_module`, `external_module_name`) | seul le module lié à un transporteur reçoit le hook `displayCarrierExtraContent` |
| On stocke l'**`id_reference`** du transporteur, pas son `id_carrier` | l'`id_carrier` change à chaque modification du transporteur en back-office ; l'`id_reference` est stable |
| `need_range = true`, `is_free = true`, `extends Module` (et non `CarrierModule`) | sans `need_range`, un transporteur de module n'est pas proposé ; gratuit : le module n'a pas à calculer de frais |
| Réservation liée au **panier** (`id_cart`, UNIQUE) pendant le checkout, rattachée à la **commande** à `actionValidateOrder` | le client peut changer d'avis avant de payer |
| « Maintenant » calculé en **PHP** (fuseau de la boutique), jamais `NOW()` | MySQL tourne en UTC dans ce conteneur (2 h d'écart avec Paris) |
| Validations côté **serveur** (créneau existant, actif, futur ; panier du client courant) | on ne fait jamais confiance au navigateur |
| Tables supprimées à la désinstallation ; transporteur conservé avec `deleted = 1` | les anciennes commandes restent liées à leur transporteur |

### Thème `atelier`

| Choix | Raison |
|---|---|
| Thème **enfant** de `classic` (`parent: classic`, `use_parent_assets: true`) | on hérite de tous les gabarits et du CSS de Classic ; le cœur et `themes/classic` ne sont jamais modifiés |
| `global_settings` **absent** du `theme.yml` de l'enfant | le cœur fusionne les deux fichiers par un `array_merge` de premier niveau (`src/Core/Addon/Theme/Theme.php:61`) : redéfinir cette clé effacerait les types d'images et l'affectation des hooks de Classic. Pour la même raison, `meta` et `theme_settings` sont réécrits **en entier** |
| Un seul `assets/css/custom.css` écrit à la main | le cœur le charge automatiquement après `theme.css` (priorité 1000, `classes/controller/FrontController.php:980`) ; le conteneur ne fournit pas les sources SCSS de Classic |
| 4 gabarits surchargés seulement, par héritage (`{extends file='parent:…'}` + `{block … append}`) | on n'ajoute que ce qui change au lieu de recopier des fichiers entiers : carte produit, en-tête, en-tête du tunnel, pied de page |
| Logo = **texte** (nom de la boutique) et non une image | rien de binaire à versionner, boutique identique après restauration du dump |
| Polices Nunito et Open Sans **embarquées** en woff2 (`assets/fonts/`) | aucun appel à un serveur externe à l'affichage ; licence SIL OFL 1.1, texte conservé dans `assets/fonts/` |
| Mise en page recréée en CSS, **sans Bootstrap 5** | Classic est en Bootstrap 4 ; mélanger les deux casserait le panier et le tunnel de commande |
| En-tête sur **2 niveaux** sans déplacer un seul hook | les hooks sont appelés depuis un conteneur unique et rangés en CSS (`order` + un élément de retour à la ligne) : l'affectation des modules aux hooks, héritée de Classic, reste intacte |
| Accueil : **Meilleures ventes** (`ps_bestsellers`) puis **Nouveautés** (`ps_newproducts`) | `ps_featuredproducts` affichait simplement la catégorie Accueil, donc les mêmes articles que les nouveautés. Les meilleures ventes sont calculées sur les commandes réellement validées : une vente n'est comptabilisée qu'au passage de la commande dans un état payé (`classes/order/OrderHistory.php:225`). Les deux modules produisant le même balisage, leur ordre d'affichage est réglé par leur **position sur le hook** (back-office) |
| Blocs de démonstration retirés du hook `displayHome` : `ps_imageslider` (« Sample 1 »), `ps_banner` (« 20% OFF ON CLOTHES ») et `ps_customtext` (lorem ipsum) | ils affichaient du contenu de démonstration sans rapport avec la boutique ; les modules ne sont pas désinstallés, la manœuvre est réversible depuis le back-office |
| Images du bandeau = **nos photos produits** redimensionnées (`assets/img/`, 147 Ko) | aucune image de la maquette n'est redistribuée |
| Ajout au panier **depuis la liste**, par un simple formulaire POST | même mécanisme que la fiche produit de Classic (`token` + `id_product` + `add`) : aucune ligne de JavaScript, et le compteur de quantité est un `input type="number"` dont le navigateur fournit les flèches |
| Boutons de carte **neutres** (gris) et non jaunes | comme la maquette : le jaune reste réservé aux appels à l'action principaux (bandeau, panier) |
| Un produit à déclinaisons affiche « Choisir le format » au lieu de « Ajouter au panier » | on ne peut pas l'ajouter sans avoir choisi un format ; un produit épuisé renvoie vers sa fiche |
| En-tête construit en **grille CSS** et non en flex qui se replie | avec un flex, le bloc « compte + panier » basculait sur sa propre ligne dès qu'un client était connecté (son nom s'ajoute aux liens) : en grille, chaque élément a une zone nommée et la disposition ne dépend plus de la largeur des contenus |
| Bloc newsletter surchargé (`modules/ps_emailsubscription/…`) | pour la mise en page en deux colonnes de la maquette ; tous les champs attendus par le module sont conservés, y compris le hook de consentement RGPD |
| Un seul fichier JS dans le thème (`assets/js/custom.js`, ~15 lignes) | uniquement pour placer le bouton « Précédent » à côté de « Continuer » : ce dernier est dans le formulaire de l'étape, hors de portée du bloc Smarty surchargeable. Le retour en arrière déclenche un clic sur le titre de l'étape précédente, c'est-à-dire le mécanisme de Classic |
| Animations en **CSS seul**, désactivées par `prefers-reduced-motion` | apparition en fondu, survols et retour au clic ; la coupure est une demande d'accessibilité, pas une préférence esthétique |
| Données de démonstration traduites et réécrites (réassurance, listes d'envies, message de confidentialité, titres du pied de page) | PrestaShop les installe en anglais ; ce sont des **données**, modifiables au back-office, reprises par le dump |
| Pas de note en étoiles sur les cartes | la note « 4.5 » de la maquette est une donnée de démonstration : l'inventer tromperait le visiteur. L'emplacement réel des avis (`displayProductListReviews`) est conservé et se remplira dès qu'un avis sera déposé |

Le design s'inspire du modèle gratuit **FoodMart** de [TemplatesJungle](https://templatesjungle.com/). Aucun fichier du modèle (image, CSS, JS) n'est repris dans ce dépôt : seules les valeurs de sa charte graphique ont été reproduites. Sa licence impose de conserver le lien de crédit, présent dans le pied de page de la boutique.

Hooks utilisés : `displayCarrierExtraContent` (créneaux sous le transporteur), `actionValidateStepComplete` (validation serveur à l'étape livraison), `actionValidateOrder` (rattache la réservation à la commande), `displayOrderConfirmation` (rappel au client), `displayAdminOrderMain` (créneau dans la fiche commande), `actionCarrierUpdate` (volontairement vide, voir plus bas).

## Limites connues
- **Le créneau n'est pas modifiable après la commande**, ni par le client ni par l'administrateur : en cas d'imprévu, la boutique contacte le client.
- Un créneau désactivé ou dépassé **entre** l'étape livraison et le paiement n'empêche pas la commande (`actionValidateOrder` arrive trop tard pour la bloquer).
- Un créneau qui a des réservations ne peut être ni supprimé ni déplacé : il se désactive.
- Désinstaller le module supprime ses tables : les anciennes commandes n'affichent plus leur créneau. Chaque réinstallation laisse aussi un transporteur « Retrait en boutique » supplémentaire marqué supprimé.
- `hookActionCarrierUpdate` est vide volontairement (grâce à l'`id_reference`, rien à mettre à jour).
- Les réservations de paniers abandonnés restent en base ; elles ne sont pas comptées comme des réservations.
- `reinstall.sh` lit le message de la console PrestaShop en français ou en anglais.
- Bonus non réalisés : places limitées par créneau, actualisation AJAX, refus des créneaux complets.

## Dépannage
- **`prestashop … (unhealthy)`** : le module ou le thème est vide dans le conteneur (montage cassé, fréquent après un `git switch` ou un redémarrage de Windows). Vérifier : `docker exec prestashop ls -A modules/nk_clickcollect themes/atelier`. Réparer : `docker compose up -d --force-recreate prestashop`.
- **Back-office en erreur 500 (`appParameters.php` introuvable)** : la console a été lancée en root. Réparer : `docker exec prestashop chown -R www-data:www-data var/cache var/logs`.
- **Vider le cache** : `docker exec prestashop rm -rf var/cache/dev var/cache/prod`.
- **Tout effacer et recommencer** : `docker compose down -v` supprime la boutique **et** la base (volumes `psdata` et `dbdata`).
