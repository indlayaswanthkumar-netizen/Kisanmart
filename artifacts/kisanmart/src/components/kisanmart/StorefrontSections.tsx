import {
  ArrowRight,
  Bug,
  Flower2,
  HandHelping,
  Leaf,
  PackageCheck,
  Shovel,
  Sprout,
  Tractor,
} from "lucide-react";

const categories = [
  { title: "Seeds", note: "Variety starts", icon: Sprout },
  { title: "Crop nutrition", note: "Soil & plant care", icon: Leaf },
  { title: "Crop protection", note: "Pest management", icon: Bug },
  { title: "Farm tools", note: "Everyday essentials", icon: Shovel },
  { title: "Irrigation", note: "Water equipment", icon: Tractor },
  { title: "Animal care", note: "Livestock needs", icon: Flower2 },
];

const products = [
  {
    type: "SEED · ILLUSTRATIVE",
    name: "Open-pollinated vegetable seeds",
    description: "A sample listing for seasonal vegetable seed varieties.",
    label: "Seed sample",
    swatch: "seed",
    pack: "Pack details vary",
  },
  {
    type: "SOIL CARE · ILLUSTRATIVE",
    name: "Organic soil amendment",
    description: "An example soil-care product. Check label for composition.",
    label: "Soil care",
    swatch: "soil",
    pack: "Composition on label",
  },
  {
    type: "IRRIGATION · ILLUSTRATIVE",
    name: "Drip irrigation connector set",
    description: "A representative fitting set for irrigation systems.",
    label: "Watering",
    swatch: "water",
    pack: "Sizing varies",
  },
  {
    type: "FARM TOOL · ILLUSTRATIVE",
    name: "Hand cultivator",
    description: "A simple hand tool example for small-scale field work.",
    label: "Field tool",
    swatch: "tool",
    pack: "Specifications vary",
  },
];

export function CategoryDiscovery() {
  return (
    <section
      className="km-section km-reveal"
      id="categories"
      aria-labelledby="categories-heading"
    >
      <div className="km-section-head">
        <div>
          <div className="km-section-kicker">A good place to begin</div>
          <h2 id="categories-heading">Explore by farm need</h2>
        </div>
        <a className="km-text-link" href="#products">
          See sample picks <ArrowRight size={15} aria-hidden="true" />
        </a>
      </div>
      <div className="km-categories">
        {categories.map(({ title, note, icon: Icon }) => (
          <a
            className="km-category"
            href="#products"
            key={title}
            aria-label={`${title}: browse illustrative picks`}
          >
            <span className="km-category-icon">
              <Icon size={27} strokeWidth={1.8} aria-hidden="true" />
            </span>
            <strong>{title}</strong>
            <small>{note}</small>
          </a>
        ))}
      </div>
    </section>
  );
}

export function SeasonNote() {
  return (
    <section
      className="km-season-banner km-reveal"
      id="season-notes"
      aria-labelledby="season-heading"
    >
      <div className="km-season-content">
        <div className="km-season-label">A note for the season</div>
        <h2 id="season-heading">Start with your soil and local conditions.</h2>
        <p>
          Crop needs vary with region, soil and season. Check product labels and
          seek local agricultural guidance when making input decisions.
        </p>
      </div>
      <a href="#about-kisanmart" className="km-season-link">
        How we think about farm inputs{" "}
        <ArrowRight size={15} aria-hidden="true" />
      </a>
    </section>
  );
}

export function IllustrativeProducts() {
  return (
    <section
      className="km-section km-reveal km-reveal-delay"
      id="products"
      aria-labelledby="products-heading"
    >
      <div className="km-section-head">
        <div>
          <div className="km-section-kicker">A first look</div>
          <h2 id="products-heading">Everyday farm essentials</h2>
        </div>
        <span className="km-text-link">Examples only</span>
      </div>
      <p className="km-product-disclaimer">
        Illustrative sample content — not live listings, recommendations, prices
        or availability.
      </p>
      <div className="km-products">
        {products.map((product, index) => (
          <article
            className="km-product"
            key={product.name}
            aria-label={`${product.name}, illustrative example`}
          >
            <div
              className={`km-product-visual km-product-visual-${product.swatch}`}
            >
              <span className="km-product-tag">{product.label}</span>
              <div className="km-product-art" aria-hidden="true">
                <span>
                  {index === 0
                    ? "SEED\nVARIETY"
                    : index === 1
                      ? "SOIL\nCARE"
                      : index === 2
                        ? "DRIP\nFITTING"
                        : "FIELD\nTOOL"}
                </span>
              </div>
            </div>
            <div className="km-product-detail">
              <div className="km-product-type">{product.type}</div>
              <h3>{product.name}</h3>
              <p className="km-product-description">{product.description}</p>
              <div className="km-product-foot">
                <span>{product.pack}</span>
                <strong>Sample</strong>
              </div>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

export function TrustNotes() {
  return (
    <section
      className="km-story-row"
      id="about-kisanmart"
      aria-label="About KisanMart"
    >
      <article className="km-story-card">
        <span className="km-story-icon">
          <PackageCheck size={25} aria-hidden="true" />
        </span>
        <div>
          <h3>Clear product information</h3>
          <p>
            We believe useful details should be easy to find. Always review the
            label and directions for each product.
          </p>
        </div>
      </article>
      <article className="km-story-card">
        <span className="km-story-icon">
          <HandHelping size={25} aria-hidden="true" />
        </span>
        <div>
          <h3>Built for real farm routines</h3>
          <p>
            A welcoming starting point for discovering farm inputs, with room to
            grow around local needs.
          </p>
        </div>
      </article>
    </section>
  );
}
