# L'Atelier des Saveurs — PrestaShop 8.2 + module `nk_clickcollect`

Boutique de démonstration PrestaShop 8.2 (Docker) et module **Click & Collect** : le client qui choisit « Retrait en boutique » sélectionne un créneau de retrait, validé côté serveur, enregistré avec la commande et visible dans l'administration.

Ce dépôt contient :
- `modules/nk_clickcollect/` : le module (code, scénarios de test, README du module) ;
- `themes/atelier/` : le thème enfant de la boutique (en cours) ;
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
