<?php
/**
 * Suppression des tables du module (désinstallation propre).
 * Inclus par Nk_Clickcollect::uninstall() : renvoie true si toutes les requêtes passent.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

$sql = [
    'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'nk_clickcollect_booking`',
    'DROP TABLE IF EXISTS `' . _DB_PREFIX_ . 'nk_clickcollect_slot`',
];

foreach ($sql as $query) {
    if (!Db::getInstance()->execute($query)) {
        return false;
    }
}

return true;
