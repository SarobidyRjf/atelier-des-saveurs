{**
 * En-tête d'une page de catégorie : une bannière avec image de fond et le
 * titre posé dessus.
 *
 * Le gabarit de Classic n'a aucun {block}, il est donc recopié et réorganisé.
 * Deux défauts de l'original sont corrigés au passage :
 *   - il enveloppait le tout dans « card card-block », ce qui donnait une
 *     carte dans une carte une fois notre habillage appliqué ;
 *   - il réservait 220 px de haut (« .block-category{min-height:13.75rem} »)
 *     pour une image de couverture affichée à côté du texte, ce qui laissait
 *     un grand vide quand la catégorie n'en a pas.
 *
 * L'image vient de la COUVERTURE DE LA CATÉGORIE, gérée au back-office
 * (Catalogue > Catégories > Image). Sans couverture, la bannière reste
 * lisible : fond doux de la charte et texte sombre, au lieu d'un trou blanc.
 * La classe « has-image » dit au CSS lequel des deux rendus appliquer.
 *
 * « block-category » est conservée par prudence (d'autres feuilles de Classic
 * s'y accrochent) ; « id="category-description" » aussi, c'est la cible
 * habituelle du texte de catégorie.
 *}
<div id="js-product-list-header">
    {if $listing.pagination.items_shown_from == 1}
        <div class="block-category atelier-category-hero{if !empty($category.image.large.url)} has-image{/if}"
             {if !empty($category.image.large.url)}style="background-image: url('{$category.image.large.url|escape:'html':'UTF-8'}');"{/if}>
            <div class="atelier-category-hero-inner">
                <h1 class="h1 atelier-category-title">{$category.name}</h1>
                {if $category.description}
                    <div id="category-description" class="atelier-category-desc">{$category.description nofilter}</div>
                {/if}
            </div>
        </div>
    {/if}
</div>
