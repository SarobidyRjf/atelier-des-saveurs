<?php
/**
 * Contrôleur de l'onglet « Commandes > Click & Collect ».
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Gestion des créneaux de retrait : liste (HelperList) et formulaire (HelperForm).
 * Le nom de la classe = class_name de l'onglet déclaré dans Nk_Clickcollect::$tabs + « Controller ».
 */
class AdminNkClickCollectSlotsController extends ModuleAdminController
{
    /**
     * Configure la table gérée, la liste et ses actions.
     */
    public function __construct()
    {
        $this->bootstrap = true;
        $this->table = 'nk_clickcollect_slot';
        $this->className = 'NkClickCollectSlot';
        // Avant parent::__construct() : sinon l'identifiant par défaut serait « id_nk_clickcollect_slot »
        // (classes/controller/AdminController.php:538).
        $this->identifier = 'id_slot';
        $this->_defaultOrderBy = 'slot_date';
        $this->_defaultOrderWay = 'ASC';
        // Tableau (même vide) obligatoire : PrestaShop y ajoute « Activer / Désactiver la sélection » grâce à la
        // colonne active (AdminController.php:2363), et ne traite les actions groupées que si c'est un tableau.
        // Pas de suppression groupée : elle contournerait le refus de supprimer un créneau réservé.
        $this->bulk_actions = [];

        parent::__construct();

        // Colonne calculée : nombre de réservations du créneau (explique pourquoi une suppression est refusée).
        // Seules comptent celles rattachées à une commande : une ligne sans id_order est un panier abandonné.
        $this->_select = '(SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'nk_clickcollect_booking` b
            WHERE b.`id_slot` = a.`id_slot` AND b.`id_order` IS NOT NULL) AS nb_bookings';

        $this->fields_list = [
            'id_slot' => ['title' => 'ID', 'align' => 'center', 'class' => 'fixed-width-xs'],
            'slot_date' => ['title' => $this->text('Date'), 'type' => 'date'],
            'time_start' => ['title' => $this->text('Début'), 'callback' => 'formatTime', 'search' => false],
            'time_end' => ['title' => $this->text('Fin'), 'callback' => 'formatTime', 'search' => false],
            'nb_bookings' => ['title' => $this->text('Réservations'), 'align' => 'center', 'search' => false],
            'active' => ['title' => $this->text('Actif'), 'active' => 'status', 'type' => 'bool', 'align' => 'center'],
        ];

        $this->addRowAction('edit');
        $this->addRowAction('delete');
    }

    /**
     * Ajoute le bouton « Ajouter un créneau » en haut de la liste
     * (même modèle que controllers/admin/AdminAttributesGroupsController.php:531).
     */
    public function initPageHeaderToolbar()
    {
        if (empty($this->display)) {
            $this->page_header_toolbar_btn['new_slot'] = [
                'href' => self::$currentIndex . '&add' . $this->table . '&token=' . $this->token,
                'desc' => $this->text('Ajouter un créneau'),
                'icon' => 'process-icon-new',
            ];
        }
        parent::initPageHeaderToolbar();
    }

    /**
     * Formulaire de création / modification d'un créneau (HelperForm).
     * Pas de type « time » dans les formulaires PrestaShop 8.2 : les heures sont des champs texte,
     * contrôlés côté serveur dans _childValidation().
     *
     * @return string
     */
    public function renderForm()
    {
        $this->fields_form = [
            'legend' => ['title' => $this->text('Créneau de retrait'), 'icon' => 'icon-time'],
            'input' => [
                // Pas de « class » sur ce champ : elle remplacerait la classe « datepicker » (calendrier).
                ['type' => 'date', 'label' => $this->text('Date'), 'name' => 'slot_date', 'required' => true],
                [
                    'type' => 'text',
                    'label' => $this->text('Heure de début'),
                    'name' => 'time_start',
                    'required' => true,
                    'class' => 'fixed-width-sm',
                    'desc' => $this->text('Format HH:MM, par exemple 10:00'),
                ],
                [
                    'type' => 'text',
                    'label' => $this->text('Heure de fin'),
                    'name' => 'time_end',
                    'required' => true,
                    'class' => 'fixed-width-sm',
                    'desc' => $this->text('Format HH:MM, par exemple 12:00'),
                ],
                [
                    'type' => 'switch',
                    'label' => $this->text('Actif'),
                    'name' => 'active',
                    'is_bool' => true,
                    'values' => [
                        ['id' => 'active_on', 'value' => 1, 'label' => $this->text('Oui')],
                        ['id' => 'active_off', 'value' => 0, 'label' => $this->text('Non')],
                    ],
                ],
            ],
            'submit' => ['title' => $this->text('Enregistrer')],
        ];

        return parent::renderForm();
    }

    /**
     * Tri par date puis par heure de début : _defaultOrderBy n'accepte qu'une colonne,
     * on complète donc la clause ORDER BY du cœur (classes/controller/AdminController.php:3379).
     *
     * @param string $orderBy
     * @param string $orderDirection
     *
     * @return string
     */
    protected function getOrderByClause($orderBy, $orderDirection)
    {
        $clause = parent::getOrderByClause($orderBy, $orderDirection);
        if (str_replace('`', '', $this->_orderBy) === 'slot_date' && !$this->_tmpTableFilter) {
            $clause .= ', a.`time_start` ' . $this->_orderWay;
        }

        return $clause;
    }

    /**
     * Refuse de supprimer un créneau qui a des réservations : il faut le désactiver
     * (les commandes concernées doivent garder leur créneau).
     *
     * @return bool|ObjectModel
     */
    public function processDelete()
    {
        if (NkClickCollectSlot::countBookings((int) Tools::getValue($this->identifier)) > 0) {
            $this->errors[] = $this->text('Ce créneau a des réservations : désactivez-le au lieu de le supprimer.');

            return false;
        }

        return parent::processDelete();
    }

    /**
     * Règles métier vérifiées côté serveur à l'ajout et à la modification d'un créneau.
     * Appelée par AdminController::validateRules() après les contrôles du cœur (champs requis, isDate) :
     * toute erreur ajoutée ici réaffiche le formulaire avec la saisie (classes/controller/AdminController.php:3730).
     */
    protected function _childValidation()
    {
        $date = (string) Tools::getValue('slot_date');
        $start = (string) Tools::getValue('time_start');
        $end = (string) Tools::getValue('time_end');
        $today = date('Y-m-d'); // fuseau de la boutique (config/config.inc.php:150)

        // Les erreurs du cœur sont rangées par nom de champ et citent ce nom technique
        // (« Ce champ est obligatoire : slot_date ») : on le remplace par le libellé du formulaire.
        $labels = [
            'slot_date' => $this->text('Date'),
            'time_start' => $this->text('Heure de début'),
            'time_end' => $this->text('Heure de fin'),
        ];
        foreach ($labels as $field => $label) {
            if (isset($this->errors[$field])) {
                $this->errors[$field] = str_replace($field, $label, $this->errors[$field]);
            }
        }

        // Validate::isDate accepte « 2026-9-30 » (classes/Validate.php:757) : on normalise en AAAA-MM-JJ
        // sinon la comparaison de chaînes est fausse (« 2026-9-30 » > « 2026-10-19 »).
        if (Validate::isDate($date)) {
            $date = date('Y-m-d', strtotime($date));
        }

        if (Validate::isDate($date) && $date < $today) {
            $this->errors[] = $this->text('La date du créneau ne peut pas être dans le passé.');
        }

        // Les heures vides sont déjà signalées par le cœur (champs requis).
        if ($start === '' || $end === '') {
            return;
        }

        // Modification d'un créneau réservé : date et heures verrouillées (la commande pointe vers ce créneau
        // par son id, le client serait attendu au mauvais moment). Seul « actif » reste modifiable.
        $idSlot = (int) Tools::getValue($this->identifier);
        if ($idSlot > 0 && NkClickCollectSlot::countBookings($idSlot) > 0) {
            $slot = new NkClickCollectSlot($idSlot);
            if (Validate::isLoadedObject($slot)
                && (strtotime($date) !== strtotime($slot->slot_date)
                    || strtotime('1970-01-01 ' . $start) !== strtotime('1970-01-01 ' . $slot->time_start)
                    || strtotime('1970-01-01 ' . $end) !== strtotime('1970-01-01 ' . $slot->time_end))) {
                $this->errors[] = $this->text('Ce créneau a des réservations : désactivez-le et créez-en un autre.');

                return;
            }
        }
        if (!NkClickCollectSlot::isValidTime($start) || !NkClickCollectSlot::isValidTime($end)) {
            $this->errors[] = $this->text('Les heures doivent être au format HH:MM, par exemple 10:00.');
        } elseif (strtotime('1970-01-01 ' . $end) <= strtotime('1970-01-01 ' . $start)) {
            $this->errors[] = $this->text('L\'heure de fin doit être après l\'heure de début.');
        } elseif ($date === $today && strtotime($date . ' ' . $start) <= time()) {
            $this->errors[] = $this->text('Ce créneau commence à une heure déjà passée.');
        }
    }

    /**
     * Valeur affichée dans un champ du formulaire : les heures sans les secondes (« 09:00 » et non « 09:00:00 »).
     *
     * @param ObjectModel $obj
     * @param string $key Nom du champ
     * @param int|null $id_lang
     *
     * @return mixed
     */
    public function getFieldValue($obj, $key, $id_lang = null)
    {
        $value = parent::getFieldValue($obj, $key, $id_lang);

        return in_array($key, ['time_start', 'time_end'], true) ? $this->formatTime($value) : $value;
    }

    /**
     * Affiche une heure stockée en TIME (« 10:00:00 ») sous la forme « 10:00 » dans la liste.
     *
     * @param string $value Valeur de la colonne
     *
     * @return string
     */
    public function formatTime($value)
    {
        // On ne retire que des secondes réelles : substr couperait « 9:30:15 » en « 9:30: ».
        return preg_replace('/^(\d{1,2}:\d{2}):\d{2}$/', '$1', (string) $value);
    }

    /**
     * Texte traduisible du contrôleur. $this->l() est déprécié dans ModuleAdminController en 8.2
     * (classes/controller/ModuleAdminController.php:104) : on passe par la traduction du module,
     * avec ce contrôleur comme source (classes/Translate.php:181).
     *
     * @param string $string
     *
     * @return string
     */
    private function text($string)
    {
        return $this->module->l($string, 'AdminNkClickCollectSlotsController');
    }
}
