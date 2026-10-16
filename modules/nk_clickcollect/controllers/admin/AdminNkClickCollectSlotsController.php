<?php
/**
 * Contrôleur de l'onglet « Commandes > Click & Collect ».
 */
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Gestion des créneaux de retrait (la liste et le formulaire arrivent à l'étape feature/admin-slots).
 * Le nom de la classe = class_name de l'onglet déclaré dans Nk_Clickcollect::$tabs + « Controller ».
 */
class AdminNkClickCollectSlotsController extends ModuleAdminController
{
    /**
     * Active le thème Bootstrap de l'administration.
     */
    public function __construct()
    {
        $this->bootstrap = true;
        parent::__construct();
    }
}
