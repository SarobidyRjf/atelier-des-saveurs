{**
 * Carte produit du thème « atelier », d'après la maquette :
 * vignette · titre · ligne d'information · prix · compteur + ajout au panier.
 *
 * On N'A PAS recopié le gabarit de Classic : « parent: » est une ressource
 * Smarty enregistrée par le cœur pour le thème parent
 * (config/smartyfront.config.inc.php:51). On ne redéfinit que deux blocs.
 *
 * Deux écarts assumés avec la maquette, et pourquoi :
 *
 * 1. La maquette affiche « 1 UNIT ★ 4.5 » sous chaque titre. La note est une
 *    donnée de démonstration : l'inventer serait mentir au visiteur. On garde
 *    donc l'emplacement réel des avis (hook displayProductListReviews, servi
 *    par productcomments, vide tant qu'aucun avis n'existe) et on affiche à
 *    côté une information vraie : le format par défaut d'un produit à
 *    déclinaisons. (La disponibilité n'est pas renseignée dans les listes de
 *    produits, seulement sur la fiche : on ne l'affiche donc pas ici.)
 *
 * 2. La maquette ajoute au panier depuis la liste. C'est possible sans une
 *    ligne de JavaScript : un simple formulaire POST vers le contrôleur
 *    panier, exactement comme la fiche produit de Classic
 *    (themes/classic/templates/catalog/product.tpl:96-99). Le jeton
 *    $static_token est obligatoire, sinon le contrôleur refuse la requête
 *    (controllers/front/CartController.php:282).
 *    En revanche un produit à déclinaisons ne PEUT pas être ajouté depuis la
 *    liste : il faut d'abord choisir un format. Ces produits reçoivent donc
 *    un lien « Choisir le format », et un produit épuisé un bouton neutre
 *    ($product.add_to_cart_url vaut null dans ce cas,
 *    src/Adapter/Presenter/Product/ProductLazyArray.php:215-222).
 *
 * Le compteur de quantité est un <input type="number"> : le navigateur fournit
 * les flèches « + / − » nativement, sans JavaScript.
 *}
{extends file='parent:catalog/_partials/miniatures/product.tpl'}

{* Ligne d'information, juste sous le titre. *}
{block name='product_name' append}
  <div class="atelier-card-meta">
    {* Produit à déclinaisons : on annonce le format par défaut. *}
    {if $product.id_product_attribute}
      {foreach from=$product.attributes item=attribut name=attributs}
        {if $smarty.foreach.attributs.first}
          {* On n'affiche que la valeur : le nom du groupe d'attributs
             (« Poids - produits solides ») est un libellé de gestion. *}
          <span class="atelier-card-format">{$attribut.name|escape:'html':'UTF-8'}</span>
        {/if}
      {/foreach}
    {/if}
    {hook h='displayProductListReviews' product=$product}
  </div>
{/block}

{* Ce bloc contient chez Classic le seul appel à displayProductListReviews ;
   on le remplace par la rangée d'action, le hook étant appelé ci-dessus. *}
{block name='product_reviews'}
  <div class="atelier-card-actions">
    {* id_product_attribute vaut 0 pour un produit simple et porte l'id de la
       déclinaison par défaut sinon : c'est notre indicateur « a des formats ».
       ($product.main_variants ne sert qu'aux déclinaisons de type couleur
        affichées en liste, et reste vide ici.) *}
    {if $product.id_product_attribute}
      <a class="btn btn-secondary atelier-card-btn" href="{$product.url}">
        {l s='Choisir le format' d='Shop.Theme.Actions'}
      </a>
    {elseif $product.add_to_cart_url}
      <form class="atelier-card-form" action="{$urls.pages.cart}" method="post">
        <input type="hidden" name="token" value="{$static_token}">
        <input type="hidden" name="id_product" value="{$product.id_product|intval}">
        <input type="hidden" name="id_product_attribute" value="{$product.id_product_attribute|intval}">
        <input type="hidden" name="add" value="1">
        {* Pas de <label for> ici : un même produit peut figurer dans
           plusieurs listes de la même page (meilleures ventes ET nouveautés),
           et l'identifiant serait alors dupliqué — le libellé de la seconde
           carte pointerait vers le champ de la première. « aria-label » donne
           le même intitulé aux lecteurs d'écran sans identifiant. *}
        <input class="atelier-card-qty"
               type="number" name="qty" value="1" min="1" inputmode="numeric"
               aria-label="{l s='Quantité' d='Shop.Theme.Actions'}">
        {* Libellé court à l'écran pour tenir sur une ligne dans une carte
           étroite ; l'intitulé complet reste donné aux lecteurs d'écran. *}
        <button class="btn btn-secondary atelier-card-btn" type="submit"
                aria-label="{l s='Ajouter au panier' d='Shop.Theme.Actions'}">
          <i class="material-icons" aria-hidden="true">shopping_cart</i>
          <span aria-hidden="true">{l s='Ajouter' d='Shop.Theme.Actions'}</span>
        </button>
      </form>
    {else}
      <a class="btn btn-secondary atelier-card-btn" href="{$product.url}">
        {l s='Voir le produit' d='Shop.Theme.Actions'}
      </a>
    {/if}
  </div>
{/block}
