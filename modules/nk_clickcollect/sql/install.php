<?php
/**
 * Création des tables du module (même convention que modules/psgdpr/sql/install.php).
 * Inclus par Nk_Clickcollect::install() : renvoie true si toutes les requêtes passent.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

$sql = [];

// Un créneau de retrait : une date, une heure de début et une heure de fin.
$sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'nk_clickcollect_slot` (
    `id_slot` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `slot_date` DATE NOT NULL,
    `time_start` TIME NOT NULL,
    `time_end` TIME NOT NULL,
    `active` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `date_add` DATETIME NOT NULL,
    `date_upd` DATETIME NOT NULL,
    PRIMARY KEY (`id_slot`),
    INDEX `slot_date` (`slot_date`)
) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

// Une réservation : un panier (une seule réservation par panier, d'où UNIQUE)
// lié à un créneau, puis rattaché à la commande une fois celle-ci validée.
$sql[] = 'CREATE TABLE IF NOT EXISTS `' . _DB_PREFIX_ . 'nk_clickcollect_booking` (
    `id_booking` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
    `id_cart` INT(10) UNSIGNED NOT NULL,
    `id_order` INT(10) UNSIGNED NULL DEFAULT NULL,
    `id_slot` INT(10) UNSIGNED NOT NULL,
    `date_add` DATETIME NOT NULL,
    PRIMARY KEY (`id_booking`),
    UNIQUE KEY `id_cart` (`id_cart`),
    INDEX `id_order` (`id_order`),
    INDEX `id_slot` (`id_slot`)
) ENGINE=' . _MYSQL_ENGINE_ . ' DEFAULT CHARSET=utf8mb4;';

foreach ($sql as $query) {
    if (!Db::getInstance()->execute($query)) {
        return false;
    }
}

return true;
