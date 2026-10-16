#!/usr/bin/env bash
# Test automatisé « installation → désinstallation → réinstallation » du module.
# Le cahier des charges exige que le fonctionnement soit correct « y compris après une réinstallation ».
# À lancer depuis l'hôte : modules/nk_clickcollect/tests/reinstall.sh
# Attention : la désinstallation supprime les tables du module (créneaux et réservations).
set -u

MODULE=nk_clickcollect
PREFIX=ps_
failures=0

# Requête SQL dans le conteneur MySQL (identifiants lus dans ses variables d'environnement).
q() {
    docker exec some-mysql sh -c 'mysql -N -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "$0"' "$1" 2>/dev/null
}

# check "libellé" "valeur obtenue" "valeur attendue"
check() {
    if [ "$2" = "$3" ]; then
        echo "  OK     $1"
    else
        echo "  ÉCHEC  $1 (obtenu : '$2', attendu : '$3')"
        failures=$((failures + 1))
    fi
}

# Console PrestaShop lancée en www-data : en root, elle laisserait un cache illisible par le serveur web.
console() {
    docker exec -u www-data prestashop php bin/console prestashop:module "$1" "$MODULE" > /dev/null 2>&1
}

check_installed() {
    local ref
    ref=$(q "SELECT value FROM ${PREFIX}configuration WHERE name = 'NK_CLICKCOLLECT_CARRIER_REF'")
    check "module enregistré" "$(q "SELECT COUNT(*) FROM ${PREFIX}module WHERE name = '$MODULE'")" "1"
    check "table des créneaux" "$(q "SHOW TABLES LIKE '${PREFIX}nk_clickcollect_slot'")" "${PREFIX}nk_clickcollect_slot"
    check "table des réservations" "$(q "SHOW TABLES LIKE '${PREFIX}nk_clickcollect_booking'")" "${PREFIX}nk_clickcollect_booking"
    check "référence transporteur en configuration" "$([ -n "$ref" ] && echo présente)" "présente"
    check "transporteur actif, lié au module" \
        "$(q "SELECT COUNT(*) FROM ${PREFIX}carrier WHERE id_reference = '${ref:-0}' AND deleted = 0 AND active = 1 AND is_module = 1 AND need_range = 1 AND external_module_name = '$MODULE'")" "1"
    check "onglet Commandes > Click & Collect" "$(q "SELECT COUNT(*) FROM ${PREFIX}tab WHERE class_name = 'AdminNkClickCollectSlots' AND module = '$MODULE'")" "1"
    check "6 hooks enregistrés" \
        "$(q "SELECT COUNT(*) FROM ${PREFIX}hook_module hm JOIN ${PREFIX}module m ON m.id_module = hm.id_module WHERE m.name = '$MODULE'")" "6"
}

check_uninstalled() {
    local ref=$1
    check "module désenregistré" "$(q "SELECT COUNT(*) FROM ${PREFIX}module WHERE name = '$MODULE'")" "0"
    check "tables supprimées" "$(q "SHOW TABLES LIKE '${PREFIX}nk_clickcollect%'")" ""
    check "référence transporteur supprimée" "$(q "SELECT COUNT(*) FROM ${PREFIX}configuration WHERE name = 'NK_CLICKCOLLECT_CARRIER_REF'")" "0"
    # La ligne doit toujours exister (anciennes commandes) mais être marquée supprimée.
    check "transporteur conservé avec deleted = 1" \
        "$(q "SELECT CONCAT(COUNT(*), '/', SUM(deleted)) FROM ${PREFIX}carrier WHERE id_reference = '${ref:-0}'")" "1/1"
    check "onglet retiré" "$(q "SELECT COUNT(*) FROM ${PREFIX}tab WHERE module = '$MODULE'")" "0"
}

# Point de départ propre : si le module est déjà installé, on le désinstalle d'abord.
if [ "$(q "SELECT COUNT(*) FROM ${PREFIX}module WHERE name = '$MODULE'")" = "1" ]; then
    console uninstall
fi

echo "1) Installation"
console install || echo "  ÉCHEC  commande install"
check_installed

echo "2) Désinstallation"
ref=$(q "SELECT value FROM ${PREFIX}configuration WHERE name = 'NK_CLICKCOLLECT_CARRIER_REF'")
console uninstall || echo "  ÉCHEC  commande uninstall"
check_uninstalled "$ref"

echo "3) Réinstallation"
console install || echo "  ÉCHEC  commande install"
check_installed

echo
if [ "$failures" -eq 0 ]; then
    echo "Réinstallation : tous les contrôles sont OK."
else
    echo "Réinstallation : $failures contrôle(s) en échec."
fi
exit $(( failures > 0 ))
