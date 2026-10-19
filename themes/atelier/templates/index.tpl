{**
 * Page d'accueil du thème « atelier ».
 *
 * On hérite de l'accueil de Classic (qui se contente d'afficher le hook
 * displayHome) et on ajoute, AVANT ce hook, le bandeau de la maquette :
 * un grand bloc de présentation et deux cartes vers les deux rayons.
 *
 * Classic laisse exprès le bloc « page_content_top » vide
 * (themes/classic/templates/index.tpl:29) : c'est l'endroit prévu.
 *
 * Le carrousel de démonstration de PrestaShop (ps_imageslider, « Sample 1 »)
 * a été retiré du hook displayHome : il faisait double emploi avec ce
 * bandeau et montrait des visuels qui ne sont pas les nôtres.
 *
 * Les images sont NOS photos produits redimensionnées
 * (assets/img/, voir README) ; aucune image de la maquette FoodMart.
 * $urls.child_theme_assets pointe vers les assets de l'enfant : avec
 * « use_parent_assets: true », $urls.theme_assets désigne Classic
 * (classes/controller/FrontController.php:1578-1587).
 *}
{extends file='parent:index.tpl'}

{block name='page_content_top'}
  <section class="atelier-hero">

    <article class="atelier-hero-main">
      <div class="atelier-hero-text">
        <p class="atelier-hero-eyebrow">{l s='100 % artisanal' d='Shop.Theme.Global'}</p>
        <h2 class="atelier-hero-title">{l s='Des saveurs qui ont une histoire' d='Shop.Theme.Global'}</h2>
        <p class="atelier-hero-lead">{l s='Confitures, miels, huiles et condiments préparés en petites quantités, à retirer gratuitement en boutique au créneau de votre choix.' d='Shop.Theme.Global'}</p>
        <a class="btn btn-primary" href="{url entity='category' id=2}">{l s='Découvrir la boutique' d='Shop.Theme.Actions'}</a>
      </div>
      <img class="atelier-hero-img"
           src="{$urls.child_theme_assets}img/hero-miel.jpg"
           alt="{l s='Pot de miel de lavande' d='Shop.Theme.Global'}"
           width="640" height="640" loading="eager">
    </article>

    <article class="atelier-promo atelier-promo-sucree">
      <div class="atelier-promo-text">
        <p class="atelier-promo-eyebrow">{l s='Le rayon' d='Shop.Theme.Global'}</p>
        <h3 class="atelier-promo-title">{l s='Épicerie sucrée' d='Shop.Theme.Global'}</h3>
        <a class="atelier-promo-link" href="{url entity='category' id=10}">
          {l s='Voir les produits' d='Shop.Theme.Actions'}
          <i class="material-icons" aria-hidden="true">arrow_forward</i>
        </a>
      </div>
      <img class="atelier-promo-img"
           src="{$urls.child_theme_assets}img/promo-sucree.jpg"
           alt="" width="420" height="420" loading="lazy">
    </article>

    <article class="atelier-promo atelier-promo-salee">
      <div class="atelier-promo-text">
        <p class="atelier-promo-eyebrow">{l s='Le rayon' d='Shop.Theme.Global'}</p>
        <h3 class="atelier-promo-title">{l s='Épicerie salée' d='Shop.Theme.Global'}</h3>
        <a class="atelier-promo-link" href="{url entity='category' id=11}">
          {l s='Voir les produits' d='Shop.Theme.Actions'}
          <i class="material-icons" aria-hidden="true">arrow_forward</i>
        </a>
      </div>
      <img class="atelier-promo-img"
           src="{$urls.child_theme_assets}img/promo-salee.jpg"
           alt="" width="420" height="420" loading="lazy">
    </article>

  </section>

  {* Les rayons de la boutique, en cartes à icône comme la maquette.
     Les deux catégories (10 et 11) sont les seules de la boutique et font
     partie de sa structure : elles sont nommées ici, comme dans le bandeau.
     Les icônes viennent de Material Icons, déjà embarqué par Classic : rien
     à télécharger. *}
  <section class="atelier-rayons">
    <h2 class="atelier-rayons-title">{l s='Nos rayons' d='Shop.Theme.Global'}</h2>
    <div class="atelier-rayons-grid">

      <a class="atelier-rayon" href="{url entity='category' id=10}">
        <span class="atelier-rayon-icon"><i class="material-icons" aria-hidden="true">local_cafe</i></span>
        <span class="atelier-rayon-name">{l s='Épicerie sucrée' d='Shop.Theme.Global'}</span>
        <span class="atelier-rayon-desc">{l s='Confitures, miels et pâtes à tartiner' d='Shop.Theme.Global'}</span>
      </a>

      <a class="atelier-rayon" href="{url entity='category' id=11}">
        <span class="atelier-rayon-icon"><i class="material-icons" aria-hidden="true">restaurant</i></span>
        <span class="atelier-rayon-name">{l s='Épicerie salée' d='Shop.Theme.Global'}</span>
        <span class="atelier-rayon-desc">{l s='Huiles, condiments et tartinades' d='Shop.Theme.Global'}</span>
      </a>

      <a class="atelier-rayon" href="{$urls.pages.new_products}">
        <span class="atelier-rayon-icon"><i class="material-icons" aria-hidden="true">new_releases</i></span>
        <span class="atelier-rayon-name">{l s='Nouveautés' d='Shop.Theme.Global'}</span>
        <span class="atelier-rayon-desc">{l s='Les derniers arrivages de l\'atelier' d='Shop.Theme.Global'}</span>
      </a>

      <a class="atelier-rayon" href="{$urls.pages.stores}">
        <span class="atelier-rayon-icon"><i class="material-icons" aria-hidden="true">storefront</i></span>
        <span class="atelier-rayon-name">{l s='Retrait en boutique' d='Shop.Theme.Global'}</span>
        <span class="atelier-rayon-desc">{l s='Gratuit, au créneau de votre choix' d='Shop.Theme.Global'}</span>
      </a>

    </div>
  </section>
{/block}
