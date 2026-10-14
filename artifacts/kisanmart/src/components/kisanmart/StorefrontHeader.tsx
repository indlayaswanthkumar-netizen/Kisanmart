import {
  ArrowDown,
  Leaf,
  MapPin,
  Search,
  ShoppingBag,
  UserRound,
} from "lucide-react";
import Link from "next/link";

import { signOutAction } from "@/app/auth/actions";

export function StorefrontHeader({
  isSignedIn,
  userName,
}: {
  isSignedIn: boolean;
  userName?: string;
}) {
  return (
    <>
      <div className="km-topline">
        <div className="km-wrap km-topline-inner">
          <span>Good inputs. Better growing days.</span>
          <a href="#about-kisanmart">
            A marketplace built around farm needs{" "}
            <ArrowDown size={12} aria-hidden="true" />
          </a>
        </div>
      </div>
      <header className="km-header">
        <div className="km-wrap km-head-main">
          <a className="km-brand" href="#home" aria-label="KisanMart home">
            <span className="km-brand-mark">
              <Leaf size={24} strokeWidth={2.2} aria-hidden="true" />
            </span>
            <span>
              <span className="km-brand-name">KisanMart</span>
              <span className="km-brand-caption">For every growing season</span>
            </span>
          </a>
          <div className="km-location" aria-label="Delivery location">
            <MapPin className="km-location-icon" size={19} aria-hidden="true" />
            <span>
              <span className="km-loc-label">DELIVERY LOCATION</span>
              <span className="km-loc-value">For your farm</span>
            </span>
          </div>
          <a
            className="km-search"
            href="#products"
            aria-label="Browse the sample products section"
          >
            <Search size={18} aria-hidden="true" />
            <span>Browse seeds, tools and more</span>
          </a>
          <div className="km-head-actions" aria-label="Account and cart">
            {isSignedIn ? (
              <>
                <span className="km-head-greeting">
                  <UserRound size={19} aria-hidden="true" />
                  <span>{userName ? `Hi, ${userName}` : "Your account"}</span>
                </span>
                <form action={signOutAction}>
                  <button
                    className="km-head-signout"
                    type="submit"
                    data-testid="button-sign-out"
                  >
                    Sign out
                  </button>
                </form>
              </>
            ) : (
              <Link
                className="km-head-link"
                href="/login"
                data-testid="link-account"
              >
                <UserRound size={19} aria-hidden="true" />
                <span>Sign in</span>
              </Link>
            )}
            <span
              className="km-head-link km-cart-note"
              aria-label="Cart planned for a later phase"
            >
              <ShoppingBag size={19} aria-hidden="true" />
              <span>Cart</span>
              <small>Phase 2</small>
            </span>
          </div>
        </div>
        <nav className="km-header-nav" aria-label="Main navigation">
          <div className="km-wrap km-nav-inner">
            <a href="#categories">Shop by category</a>
            <a href="#season-notes">Seasonal notes</a>
            <a href="#products">Illustrative picks</a>
            <a href="#about-kisanmart">About KisanMart</a>
            <span className="km-nav-note">
              <Leaf size={14} aria-hidden="true" /> Practical choices for your
              farm
            </span>
          </div>
        </nav>
      </header>
    </>
  );
}
