<?php
/**
 * Créneaux de démonstration : 2 par jour pendant les 7 jours qui suivent l'installation.
 * Inclus par Nk_Clickcollect::install() : renvoie true si tous les créneaux sont créés.
 * Les dates sont relatives à « aujourd'hui » : pour les régénérer, réinstaller le module.
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

// [début, fin] des deux plages proposées chaque jour.
$ranges = [['10:00:00', '12:00:00'], ['14:00:00', '16:00:00']];

for ($day = 1; $day <= 7; ++$day) {
    // « Maintenant » calculé en PHP (fuseau de la boutique), jamais avec NOW() : MySQL tourne en UTC.
    $date = date('Y-m-d', strtotime('+' . $day . ' day'));

    foreach ($ranges as $index => $range) {
        $slot = new NkClickCollectSlot();
        $slot->slot_date = $date;
        $slot->time_start = $range[0];
        $slot->time_end = $range[1];
        // Un créneau inactif (jour 2, après-midi) pour montrer qu'il n'est pas proposé aux clients.
        $slot->active = !($day === 2 && $index === 1);

        if (!$slot->add()) {
            return false;
        }
    }
}

return true;
