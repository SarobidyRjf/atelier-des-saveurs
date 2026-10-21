{**
 * En-tête d'une page de catégorie : bannière pleine largeur, image de fond,
 * fil d'Ariane et titre posés dessus.
 *
 * Le gabarit de Classic n'a aucun {block}, il est donc recopié et réorganisé.
 * Trois défauts de l'original sont corrigés au passage :
 *   - il enveloppait le tout dans « card card-block », ce qui donnait une
 *     carte dans une carte une fois notre habillage appliqué ;
 *   - il réservait 220 px de haut (« .block-category{min-height:13.75rem} »)
 *     pour une image affichée À CÔTÉ du texte, d'où un grand vide sans elle ;
 *   - il pointait vers $category.image.large.url, qui désigne la plus grande
 *     vignette CONFIGURÉE pour une catégorie, soit 141x180 px
 *     (src/Adapter/Image/ImageRetriever.php:282) — illisible en fond de
 *     bannière. On prend donc l'original déposé par le back-office, que
 *     PrestaShop conserve dans img/c/<id>.jpg.
 *
 * L'image vient de la couverture de la catégorie (Catalogue > Catégories >
 * Image). PrestaShop considère qu'elle existe dès que le fichier img/c/<id>.jpg
 * est là (classes/Category.php:166). Le tableau présenté n'expose PAS
 * « id_image » — c'est une propriété dynamique, pas un champ de la table —
 * d'où le test sur $category.image et l'URL construite depuis $category.id,
 * qui sont les deux seules clés disponibles ici. Sans couverture, la bannière
 * reste lisible — fond doux et texte sombre — au lieu d'un trou blanc.
 *
 * Le fil d'Ariane est rendu ICI pour être posé sur l'image. Celui de la page
 * est masqué en CSS tant que la bannière est présente, c'est-à-dire en page 1
 * uniquement (voir custom.css, section 26) :
 * le dupliquer visuellement serait une faute, mais le rendre deux fois dans
 * le HTML en serait une autre, donc un seul des deux est visible.
 *
 * « block-category » est conservée par prudence (d'autres feuilles de Classic
 * s'y accrochent) et « id="category-description" » reste la cible habituelle
 * du texte de catégorie.
 *}
<div id="js-product-list-header">
    {if $listing.pagination.items_shown_from == 1}
        <div class="block-category atelier-category-hero{if !empty($category.image)} has-image{/if}"
             {if !empty($category.image)}style="background-image: url('{$urls.img_cat_url}{$category.id|intval}.jpg');"{/if}>
            <div class="atelier-category-hero-inner">

                {if !empty($breadcrumb.links)}
                    <nav class="atelier-category-breadcrumb" aria-label="{l s='Fil d\'Ariane' d='Shop.Theme.Global'}">
                        <ol>
                            {foreach from=$breadcrumb.links item=etape name=fil}
                                <li>
                                    {if not $smarty.foreach.fil.last}
                                        <a href="{$etape.url}"><span>{$etape.title}</span></a>
                                    {else}
                                        <span aria-current="page">{$etape.title}</span>
                                    {/if}
                                </li>
                            {/foreach}
                        </ol>
                    </nav>
                {/if}

                <h1 class="h1 atelier-category-title">{$category.name}</h1>

                {if $category.description}
                    <div id="category-description" class="atelier-category-desc">{$category.description nofilter}</div>
                {/if}
            </div>
        </div>
    {/if}
</div>
