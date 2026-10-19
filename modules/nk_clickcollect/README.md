# Module nk_clickcollect

Retrait en boutique avec choix d'un créneau horaire (PrestaShop 8.2). Installation, lancement, choix techniques et limites : voir le [README du dépôt](../../README.md). Scénarios de test : [tests/TESTS.md](tests/TESTS.md).

## Contenu
| Élément | Rôle |
|---|---|
| `nk_clickcollect.php` | classe `Nk_Clickcollect` : installation, transporteur, hooks |
| `classes/NkClickCollectSlot.php` | un créneau (date, heure de début, heure de fin, actif) |
| `classes/NkClickCollectBooking.php` | réservation : panier, puis commande ↔ créneau |
| `controllers/admin/AdminNkClickCollectSlotsController.php` | gestion des créneaux (Commandes > Click & Collect) |
| `sql/` | tables (`install.php`, `uninstall.php`) et créneaux de démo (`demo.php`) |
| `views/templates/hook/` | créneaux au checkout, rappel sur la confirmation, carte de la fiche commande |
| `tests/` | `lint.sh`, `reinstall.sh`, `TESTS.md` |

## Tables
- `ps_nk_clickcollect_slot` : `id_slot`, `slot_date`, `time_start`, `time_end`, `active`, `date_add`, `date_upd`.
- `ps_nk_clickcollect_booking` : `id_booking`, `id_cart` (unique), `id_order` (NULL jusqu'à la commande), `id_slot`, `date_add`.
