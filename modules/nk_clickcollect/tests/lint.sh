#!/usr/bin/env bash
# Vérifie la syntaxe de tous les fichiers PHP du module avec `php -l`, dans le conteneur
# (même version de PHP que la boutique). À lancer depuis l'hôte : modules/nk_clickcollect/tests/lint.sh
set -u

errors=0
files=$(docker exec prestashop find modules/nk_clickcollect -name '*.php' | sort)

for file in $files; do
    if output=$(docker exec prestashop php -l "$file" 2>&1); then
        echo "OK     $file"
    else
        echo "ÉCHEC  $file"
        echo "$output"
        errors=$((errors + 1))
    fi
done

echo
if [ "$errors" -eq 0 ]; then
    echo "Lint : aucune erreur."
else
    echo "Lint : $errors fichier(s) en erreur."
fi
exit $(( errors > 0 ))
