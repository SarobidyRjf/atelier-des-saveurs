{**
 * Bloc « compte » de l'en-tête, compacté.
 *
 * Classic affiche DEUX liens côte à côte quand le client est connecté
 * (« Déconnexion » puis son nom), ce qui charge inutilement la barre. On
 * garde le nom comme lien principal et on réduit la déconnexion à une icône
 * avec un intitulé accessible.
 *
 * L'identifiant #_desktop_user_info est conservé : le JS de Classic échange
 * son contenu avec #_mobile_user_info sur petit écran.
 *}
<div id="_desktop_user_info">
  <div class="user-info">
    {if $logged}
      <a class="account atelier-account"
         href="{$urls.pages.my_account}"
         title="{l s='Voir mon compte client' d='Shop.Theme.Customeraccount'}"
         rel="nofollow">
        <i class="material-icons" aria-hidden="true">&#xE7FF;</i>
        <span class="hidden-sm-down">{$customerName}</span>
      </a>
      <a class="logout atelier-logout hidden-sm-down"
         href="{$urls.actions.logout}"
         title="{l s='Se déconnecter' d='Shop.Theme.Actions'}"
         aria-label="{l s='Se déconnecter' d='Shop.Theme.Actions'}"
         rel="nofollow">
        <i class="material-icons" aria-hidden="true">&#xE879;</i>
      </a>
    {else}
      <a class="atelier-account"
         href="{$urls.pages.authentication}?back={$urls.current_url|urlencode}"
         title="{l s='Me connecter à mon compte client' d='Shop.Theme.Customeraccount'}"
         rel="nofollow">
        <i class="material-icons" aria-hidden="true">&#xE7FF;</i>
        <span class="hidden-sm-down">{l s='Connexion' d='Shop.Theme.Actions'}</span>
      </a>
    {/if}
  </div>
</div>
