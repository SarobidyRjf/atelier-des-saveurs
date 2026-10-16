<?php
/**
 * Protection : empêche de lister le contenu du dossier via le navigateur
 * (même modèle que les modules officiels, ex. modules/ps_wirepayment/index.php).
 */
header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
header('Last-Modified: ' . gmdate('D, d M Y H:i:s') . ' GMT');

header('Cache-Control: no-store, no-cache, must-revalidate');
header('Cache-Control: post-check=0, pre-check=0', false);
header('Pragma: no-cache');

header('Location: ../');
exit;
