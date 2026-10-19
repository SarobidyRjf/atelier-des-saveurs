<?php
/**
 * Créneau de retrait Click & Collect.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Un créneau = une ligne de la table nk_clickcollect_slot.
 * ObjectModel fournit add(), update(), delete(), toggleStatus() et la validation des champs.
 */
class NkClickCollectSlot extends ObjectModel
{
    /** @var string Date du créneau (AAAA-MM-JJ) */
    public $slot_date;

    /** @var string Heure de début (HH:MM ou HH:MM:SS) */
    public $time_start;

    /** @var string Heure de fin (HH:MM ou HH:MM:SS) */
    public $time_end;

    /** @var bool Créneau proposé aux clients */
    public $active = true;

    /** @var string Remplie automatiquement par ObjectModel::add() */
    public $date_add;

    /** @var string Remplie automatiquement par ObjectModel::add() et update() */
    public $date_upd;

    /**
     * Description de la table pour ObjectModel.
     * Les heures sont des TYPE_STRING : PrestaShop n'a ni type TIME ni Validate::isTime ;
     * leur format est contrôlé par isValidTime().
     */
    public static $definition = [
        'table' => 'nk_clickcollect_slot',
        'primary' => 'id_slot',
        'fields' => [
            'slot_date' => ['type' => self::TYPE_DATE, 'validate' => 'isDate', 'required' => true],
            'time_start' => ['type' => self::TYPE_STRING, 'size' => 8, 'required' => true],
            'time_end' => ['type' => self::TYPE_STRING, 'size' => 8, 'required' => true],
            'active' => ['type' => self::TYPE_BOOL, 'validate' => 'isBool'],
            'date_add' => ['type' => self::TYPE_DATE, 'validate' => 'isDate'],
            'date_upd' => ['type' => self::TYPE_DATE, 'validate' => 'isDate'],
        ],
    ];

    /**
     * Vérifie qu'une heure est au format H:MM ou HH:MM (secondes facultatives), entre 0:00 et 23:59.
     *
     * @param string $time
     *
     * @return bool
     */
    public static function isValidTime($time)
    {
        return (bool) preg_match('/^([01]?\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/', (string) $time);
    }

    /**
     * Créneaux proposables aux clients : actifs et pas encore commencés, triés par date puis heure.
     * « Maintenant » est calculé en PHP (fuseau de la boutique) et non avec NOW() de MySQL,
     * qui tourne en UTC dans ce conteneur.
     *
     * @return array Lignes de la table (id_slot, slot_date, time_start, time_end, ...)
     */
    public static function getBookableSlots()
    {
        $query = (new DbQuery())
            ->select('*')
            ->from('nk_clickcollect_slot')
            ->where('active = 1')
            ->where('CONCAT(slot_date, " ", time_start) > "' . pSQL(date('Y-m-d H:i:s')) . '"')
            ->orderBy('slot_date ASC, time_start ASC');

        return Db::getInstance()->executeS($query, true, false);
    }

    /**
     * Règle métier côté serveur : un créneau est réservable s'il existe, est actif et n'a pas commencé.
     *
     * @param int $idSlot
     *
     * @return bool
     */
    public static function isBookable($idSlot)
    {
        // On réutilise getBookableSlots() : la règle « réservable » n'est écrite qu'à un seul endroit.
        foreach (self::getBookableSlots() as $slot) {
            if ((int) $slot['id_slot'] === (int) $idSlot) {
                return true;
            }
        }

        return false;
    }

    /**
     * Nombre de réservations liées à un créneau et rattachées à une commande.
     *
     * @param int $idSlot
     *
     * @return int
     */
    public static function countBookings($idSlot)
    {
        $query = (new DbQuery())
            ->select('COUNT(*)')
            ->from('nk_clickcollect_booking')
            ->where('id_slot = ' . (int) $idSlot)
            ->where('id_order IS NOT NULL'); // sans id_order : panier abandonné, pas une vraie réservation

        return (int) Db::getInstance()->getValue($query);
    }
}
