{**
 * Bloc panier de l'en-tête, surchargé pour le thème « atelier ».
 *
 * Le gabarit de Classic ne contient aucun {block}, on ne peut donc pas en
 * hériter : il est recopié et modifié. Deux changements seulement :
 *   - le libellé « Panier » devient « Votre panier » ;
 *   - le TOTAL du panier s'affiche sous le libellé, comme dans la maquette.
 *
 * À NE PAS TOUCHER : l'identifiant #_desktop_cart (le JS de Classic déplace
 * ce bloc dans #_mobile_cart sur petit écran), les classes .blockcart et
 * .cart-preview, l'attribut data-refresh-url et .cart-products-count : le JS
 * du module remplace ce bloc après chaque ajout au panier en s'appuyant
 * dessus (modules/ps_shoppingcart/ps_shoppingcart.js).
 *
 * On affiche le SOUS-TOTAL des produits et non $cart.totals.total.value :
 * ce dernier passe par getOrderTotal(true, Cart::BOTH) et inclut donc les
 * frais de port, ce qui n'a pas de sens dans un en-tête où le client n'a pas
 * encore choisi son mode de livraison.
 *}
<div id="_desktop_cart">
  <div class="blockcart cart-preview {if $cart.products_count > 0}active{else}inactive{/if}" data-refresh-url="{$refresh_url}">
    {* « title » : bulle au survol dans la barre mobile, où le libellé est masqué. *}
    <div class="header" title="{l s='Votre panier' d='Shop.Theme.Checkout'}">
      {if $cart.products_count > 0}
        <a rel="nofollow" aria-label="{l s='Shopping cart link containing %nbProducts% product(s)' sprintf=['%nbProducts%' => $cart.products_count] d='Shop.Theme.Checkout'}" href="{$cart_url}">
      {/if}
        <i class="material-icons shopping-cart" aria-hidden="true">shopping_cart</i>
        <span class="cart-text hidden-sm-down">
          <span class="cart-label">{l s='Votre panier' d='Shop.Theme.Checkout'}</span>
          <span class="cart-total-value">{$cart.subtotals.products.value}</span>
        </span>
        <span class="cart-products-count">({$cart.products_count})</span>
      {if $cart.products_count > 0}
        </a>
      {/if}
    </div>
  </div>
</div>
