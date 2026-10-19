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
 * $cart.totals.total.value : même variable que Classic utilise dans
 * templates/checkout/_partials/cart-summary-totals.tpl:31.
 *}
<div id="_desktop_cart">
  <div class="blockcart cart-preview {if $cart.products_count > 0}active{else}inactive{/if}" data-refresh-url="{$refresh_url}">
    <div class="header">
      {if $cart.products_count > 0}
        <a rel="nofollow" aria-label="{l s='Shopping cart link containing %nbProducts% product(s)' sprintf=['%nbProducts%' => $cart.products_count] d='Shop.Theme.Checkout'}" href="{$cart_url}">
      {/if}
        <i class="material-icons shopping-cart" aria-hidden="true">shopping_cart</i>
        <span class="cart-text hidden-sm-down">
          <span class="cart-label">{l s='Votre panier' d='Shop.Theme.Checkout'}</span>
          <span class="cart-total-value">{$cart.totals.total.value}</span>
        </span>
        <span class="cart-products-count">({$cart.products_count})</span>
      {if $cart.products_count > 0}
        </a>
      {/if}
    </div>
  </div>
</div>
