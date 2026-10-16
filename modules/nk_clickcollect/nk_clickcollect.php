<?php
/**
 * Module Click & Collect pour L'Atelier des Saveurs (PrestaShop 8.2).
 *
 * Le client qui choisit le transporteur « Retrait en boutique » sélectionne
 * un créneau de retrait ; le créneau est validé côté serveur, enregistré
 * avec la commande et consultable dans l'administration.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

// Pas d'autoload Composer : les classes du module sont chargées à la main.
require_once __DIR__ . '/classes/NkClickCollectSlot.php';
require_once __DIR__ . '/classes/NkClickCollectBooking.php';

/**
 * Classe principale du module. Le nom de la classe doit correspondre au nom
 * technique du dossier (nk_clickcollect → Nk_Clickcollect).
 */
class Nk_Clickcollect extends Module
{
    /** Clé de configuration : id_reference du transporteur « Retrait en boutique ». */
    public const CONFIG_CARRIER_REF = 'NK_CLICKCOLLECT_CARRIER_REF';

    /** Hooks utilisés par le module (chacun vérifié dans le code de PrestaShop 8.2). */
    public const HOOKS = [
        'displayCarrierExtraContent',
        'actionValidateStepComplete',
        'actionCarrierUpdate',
        'actionValidateOrder',
        'displayOrderConfirmation',
        'displayAdminOrderMain',
    ];

    /**
     * Onglet admin « Commandes > Click & Collect » : créé à l'installation et retiré
     * à la désinstallation automatiquement par PrestaShop (src/Adapter/Module/Tab/ModuleTabRegister.php).
     *
     * @var array
     */
    protected $tabs = [
        [
            'name' => 'Click & Collect',
            'class_name' => 'AdminNkClickCollectSlots',
            'parent_class_name' => 'AdminParentOrders',
            'visible' => true,
        ],
    ];

    /**
     * Déclare l'identité du module auprès de PrestaShop.
     */
    public function __construct()
    {
        $this->name = 'nk_clickcollect';
        $this->tab = 'shipping_logistics';
        $this->version = '1.0.0';
        $this->author = 'Sarobidy';
        $this->need_instance = 0;
        $this->ps_versions_compliancy = ['min' => '8.0.0', 'max' => '8.99.99'];
        $this->bootstrap = true;

        parent::__construct();

        // Nom propre, non traduit : $this->l() échapperait « & » en « &amp; » (classes/Translate.php:209).
        $this->displayName = 'Click & Collect';
        $this->description = $this->l('Retrait en boutique avec choix d\'un créneau horaire.');
        $this->confirmUninstall = $this->l('Les créneaux et les réservations seront supprimés. Continuer ?');
    }

    /**
     * Installe le module : enregistrement auprès de PrestaShop (et de l'onglet $tabs),
     * puis tables, transporteur et hooks.
     * S'arrête au premier échec (opérateur && évalué de gauche à droite).
     *
     * @return bool
     */
    public function install()
    {
        // Multiboutique : installer pour toutes les boutiques (recommandation du tutoriel officiel).
        if (Shop::isFeatureActive()) {
            Shop::setContext(Shop::CONTEXT_ALL);
        }

        // Parenthèses obligatoires : sans elles, include engloberait toute la suite de l'expression.
        return parent::install()
            && (include __DIR__ . '/sql/install.php')
            && $this->createCarrier()
            && $this->registerHook(self::HOOKS);
    }

    /**
     * Désinstalle le module : transporteur retiré, tables supprimées, puis désenregistrement.
     *
     * @return bool
     */
    public function uninstall()
    {
        return $this->deleteCarrier()
            && (include __DIR__ . '/sql/uninstall.php')
            && parent::uninstall();
    }

    /**
     * Crée le transporteur « Retrait en boutique » lié à ce module et mémorise sa référence.
     * is_module + external_module_name : condition pour que PrestaShop appelle
     * displayCarrierExtraContent sur ce module (classes/checkout/DeliveryOptionsFinder.php:129).
     *
     * @return bool
     */
    private function createCarrier()
    {
        $carrier = new Carrier();
        $carrier->name = 'Retrait en boutique';
        $carrier->is_module = true;
        $carrier->external_module_name = $this->name;
        $carrier->is_free = true;
        $carrier->shipping_external = false; // gratuit : PrestaShop ne demande pas de frais au module
        // Obligatoire : un transporteur de module sans need_range est exclu des transporteurs proposés
        // (filtre « is_module = 0 OR need_range = 1 », classes/Carrier.php:570). Sans effet sur le prix :
        // is_free renvoie 0 avant tout calcul (classes/Cart.php:3787).
        $carrier->need_range = true;
        $carrier->active = true;
        foreach (Language::getLanguages(false) as $language) {
            $carrier->delay[(int) $language['id_lang']] = $this->l('Retrait en boutique sur le créneau choisi');
        }

        if (!$carrier->add()) {
            return false;
        }

        // add() écrit id_reference = id en base mais pas sur l'objet (classes/Carrier.php:233).
        $carrier->id_reference = (int) $carrier->id;

        foreach (Zone::getZones(true) as $zone) {
            $carrier->addZone((int) $zone['id_zone']);
        }
        $carrier->setGroups(array_column(Group::getGroups((int) $this->context->language->id), 'id_group'));

        // On garde id_reference et non id_carrier : l'id change à chaque modification en admin.
        return Configuration::updateValue(self::CONFIG_CARRIER_REF, $carrier->id_reference);
    }

    /**
     * Retire le transporteur sans le supprimer (deleted = 1) : les anciennes commandes y restent liées.
     *
     * @return bool
     */
    private function deleteCarrier()
    {
        $carrier = Carrier::getCarrierByReference((int) Configuration::get(self::CONFIG_CARRIER_REF));
        if ($carrier) {
            // « Le transporteur par défaut doit exister et être actif » (devdocs 8, modules/carrier).
            if ((int) Configuration::get('PS_CARRIER_DEFAULT') === (int) $carrier->id) {
                $this->_errors[] = $this->l('Choisissez un autre transporteur par défaut avant de désinstaller ce module.');

                return false;
            }
            $carrier->deleted = true;
            if (!$carrier->update()) {
                return false;
            }
        }

        return Configuration::deleteByName(self::CONFIG_CARRIER_REF);
    }

    /**
     * Le transporteur donné (par son id_reference) est-il le « Retrait en boutique » du module ?
     *
     * @param int $idReference
     *
     * @return bool
     */
    private function isClickCollectReference($idReference)
    {
        return (int) $idReference > 0 && (int) $idReference === (int) Configuration::get(self::CONFIG_CARRIER_REF);
    }

    /**
     * Affiche les créneaux réservables sous le transporteur « Retrait en boutique », à l'étape livraison.
     * Appelé uniquement pour le module lié au transporteur (classes/checkout/DeliveryOptionsFinder.php:129).
     *
     * @param array $params ['carrier' => array] (contient id_reference)
     *
     * @return string
     */
    public function hookDisplayCarrierExtraContent($params)
    {
        if (!$this->isClickCollectReference($params['carrier']['id_reference'] ?? 0)) {
            return '';
        }

        $slots = [];
        foreach (NkClickCollectSlot::getBookableSlots() as $row) {
            $slots[] = [
                'id' => (int) $row['id_slot'],
                'date' => Tools::displayDate($row['slot_date']), // format de date de la langue du client
                'start' => substr($row['time_start'], 0, 5),
                'end' => substr($row['time_end'], 0, 5),
            ];
        }
        // Créneau déjà choisi pour ce panier : le cœur ne re-coche pas les champs des modules.
        $booking = NkClickCollectBooking::getByCart((int) $this->context->cart->id);

        $this->context->smarty->assign([
            'nk_slots' => $slots,
            'nk_selected_slot' => $booking ? (int) $booking->id_slot : 0,
        ]);

        return $this->fetch('module:nk_clickcollect/views/templates/hook/checkout_slots.tpl');
    }

    /**
     * Valide côté serveur le créneau choisi quand le client clique sur « Continuer » à l'étape livraison,
     * puis enregistre la réservation du panier. Le cœur n'appelle ce hook que si le transporteur choisi
     * est celui de ce module (classes/checkout/CheckoutDeliveryStep.php:196-212).
     * Mettre $params['completed'] à false bloque le client sur l'étape livraison.
     *
     * @param array $params ['step_name' => string, 'request_params' => array, 'completed' => bool (par référence)]
     */
    public function hookActionValidateStepComplete($params)
    {
        if (($params['step_name'] ?? '') !== 'delivery') {
            return;
        }

        // Ne jamais faire confiance au formulaire : on caste et on revérifie tout côté serveur.
        $idSlot = (int) ($params['request_params']['nk_clickcollect_slot'] ?? 0);
        if ($idSlot <= 0) {
            $this->refuseStep($params, $this->l('Veuillez choisir un créneau de retrait.'));

            return;
        }
        if (!NkClickCollectSlot::isBookable($idSlot)) {
            $this->refuseStep($params, $this->l('Ce créneau n\'est plus disponible, veuillez en choisir un autre.'));

            return;
        }

        // La réservation est liée au panier de la session ($this->context->cart), jamais à un id venu
        // de la requête : un client ne peut donc réserver que pour son propre panier.
        $idCart = (int) $this->context->cart->id;
        $booking = NkClickCollectBooking::getByCart($idCart) ?: new NkClickCollectBooking();
        $booking->id_cart = $idCart;
        $booking->id_slot = $idSlot;
        if (!$booking->save()) {
            $this->refuseStep($params, $this->l('Votre créneau n\'a pas pu être enregistré, veuillez réessayer.'));
        }
    }

    /**
     * Bloque l'étape livraison et affiche un message d'erreur au client.
     * $params['completed'] est une référence vers la variable du cœur : la modifier ici la modifie là-bas.
     *
     * @param array $params Paramètres reçus par hookActionValidateStepComplete
     * @param string $message
     */
    private function refuseStep(array $params, $message)
    {
        $params['completed'] = false;
        $this->context->controller->errors[] = $message;
    }

    /**
     * Rien à faire : le transporteur est retrouvé par son id_reference, qui ne change pas
     * quand on le modifie en admin (seul l'id_carrier change). Justification complétée à l'étape feature/order-slot.
     *
     * @param array $params ['id_carrier' => int (ancien id), 'carrier' => Carrier (nouveau)]
     */
    public function hookActionCarrierUpdate($params)
    {
    }

    /**
     * Rattache la réservation du panier à la commande créée (étape feature/order-slot).
     *
     * @param array $params ['cart' => Cart, 'order' => Order, 'customer' => Customer, ...] (classes/PaymentModule.php:560)
     */
    public function hookActionValidateOrder($params)
    {
    }

    /**
     * Rappelle le créneau au client sur la page de confirmation (étape feature/order-slot).
     *
     * @param array $params ['order' => Order] (controllers/front/OrderConfirmationController.php:259)
     *
     * @return string
     */
    public function hookDisplayOrderConfirmation($params)
    {
        return '';
    }

    /**
     * Affiche le créneau dans la fiche commande de l'administration (étape feature/order-slot).
     *
     * @param array $params ['id_order' => int] (Admin/Sell/Order/Order/view.html.twig:73)
     *
     * @return string
     */
    public function hookDisplayAdminOrderMain($params)
    {
        return '';
    }
}
