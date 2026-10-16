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
     * Nombre de réservations liées à un créneau.
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
            ->where('id_slot = ' . (int) $idSlot);

        return (int) Db::getInstance()->getValue($query);
    }
}
