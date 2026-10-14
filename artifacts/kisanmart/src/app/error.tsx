"use client";

import Link from "next/link";

export default function AppError({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="km-page">
      <section className="auth-panel-wrap" aria-labelledby="error-heading">
        <div className="auth-panel">
          <div className="auth-panel-eyebrow">KisanMart</div>
          <h2 id="error-heading">We couldn’t load this page.</h2>
          <p className="auth-panel-intro">
            Please try again. If the problem continues, return to the
            storefront.
          </p>
          <div className="auth-form">
            <button
              className="auth-submit"
              type="button"
              onClick={() => reset()}
            >
              Try again
            </button>
            <Link className="auth-panel-foot" href="/">
              Back to KisanMart
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
