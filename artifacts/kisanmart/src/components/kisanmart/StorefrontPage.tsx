import {
  ArrowRight,
  Home,
  LayoutGrid,
  ShoppingBag,
  UserRound,
} from "lucide-react";
import Image from "next/image";
import {
  CategoryDiscovery,
  IllustrativeProducts,
  SeasonNote,
  TrustNotes,
} from "./StorefrontSections";
import { StorefrontHeader } from "./StorefrontHeader";

function Hero() {
  return (
    <section className="km-hero" id="home" aria-labelledby="hero-heading">
      <div className="km-wrap">
        <div className="km-hero-panel km-reveal">
          <div className="km-hero-copy">
            <div className="km-eyebrow">
              A thoughtful start for every season
            </div>
            <h1 id="hero-heading">
              Your farm deserves <span>good beginnings.</span>
            </h1>
            <p>
              Explore useful farm inputs and everyday essentials, brought
              together with the details that help you make an informed choice.
            </p>
            <a className="km-hero-cta" href="#categories">
              Explore farm essentials{" "}
              <ArrowRight size={16} aria-hidden="true" />
            </a>
          </div>
          <div className="km-hero-art">
            <Image
              src="/kisanmart-field-hero.png"
              alt="Softly illustrated green crop rows stretching toward low hills at sunrise"
              fill
              priority
              sizes="(max-width: 760px) 100vw, 50vw"
            />
            <div className="km-hero-stamp" aria-hidden="true">
              <strong>Farm</strong>
              <span>first</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function MobileNavigation() {
  return (
    <nav className="km-mobile-nav" aria-label="Mobile navigation">
      <a href="#home" aria-current="page">
        <Home aria-hidden="true" />
        <span>Home</span>
      </a>
      <a href="#categories">
        <LayoutGrid aria-hidden="true" />
        <span>Categories</span>
      </a>
      <a href="#products">
        <ShoppingBag aria-hidden="true" />
        <span>Examples</span>
      </a>
      <a href="#about-kisanmart">
        <UserRound aria-hidden="true" />
        <span>About</span>
      </a>
    </nav>
  );
}

export default function StorefrontPage({
  isSignedIn = false,
  userName,
}: {
  isSignedIn?: boolean;
  userName?: string;
}) {
  return (
    <main className="km-page">
      <StorefrontHeader isSignedIn={isSignedIn} userName={userName} />
      <Hero />
      <div className="km-wrap">
        <CategoryDiscovery />
        <SeasonNote />
        <IllustrativeProducts />
        <TrustNotes />
      </div>
      <footer className="km-footer">
        <div className="km-wrap km-footer-inner">
          <span className="km-footer-brand">
            KisanMart · For every growing season
          </span>
          <span>
            Illustrative Phase 1 storefront · Product details will be shown with
            their source information.
          </span>
        </div>
      </footer>
      <MobileNavigation />
    </main>
  );
}
