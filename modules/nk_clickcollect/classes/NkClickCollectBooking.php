<?php
/**
 * Réservation d'un créneau de retrait.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Une réservation = une ligne de la table nk_clickcollect_booking.
 * Elle relie un panier à un créneau pendant le checkout, puis à la commande une fois celle-ci validée.
 */
class NkClickCollectBooking extends ObjectModel
{
    /** @var int Panier du client (une seule réservation par panier : index UNIQUE en base) */
    public $id_cart;

    /** @var int|null Commande, renseignée à la validation de la commande */
    public $id_order;

    /** @var int Créneau réservé */
    public $id_slot;

    /** @var string Remplie automatiquement par ObjectModel::add() */
    public $date_add;

    /**
     * Description de la table pour ObjectModel.
     * allow_null : id_order reste NULL tant que la commande n'existe pas (classes/ObjectModel.php:493).
     */
    public static $definition = [
        'table' => 'nk_clickcollect_booking',
        'primary' => 'id_booking',
        'fields' => [
            'id_cart' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId', 'required' => true],
            'id_order' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId', 'allow_null' => true],
            'id_slot' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId', 'required' => true],
            'date_add' => ['type' => self::TYPE_DATE, 'validate' => 'isDate'],
        ],
    ];

    /**
     * Réservation liée à un panier.
     *
     * @param int $idCart
     *
     * @return NkClickCollectBooking|null
     */
    public static function getByCart($idCart)
    {
        return self::findBy('id_cart', $idCart);
    }

    /**
     * Réservation rattachée à une commande (confirmation client, fiche commande admin).
     *
     * @param int $idOrder
     *
     * @return NkClickCollectBooking|null
     */
    public static function getByOrder($idOrder)
    {
        return self::findBy('id_order', $idOrder);
    }

    /**
     * Première réservation dont la colonne donnée vaut l'identifiant.
     *
     * @param string $column Nom de colonne écrit dans le code (id_cart ou id_order), jamais une saisie utilisateur
     * @param int $id
     *
     * @return NkClickCollectBooking|null
     */
    private static function findBy($column, $id)
    {
        $query = (new DbQuery())
            ->select('id_booking')
            ->from('nk_clickcollect_booking')
            ->where(bqSQL($column) . ' = ' . (int) $id);
        $idBooking = (int) Db::getInstance()->getValue($query, false);

        return $idBooking ? new self($idBooking) : null;
    }
}
