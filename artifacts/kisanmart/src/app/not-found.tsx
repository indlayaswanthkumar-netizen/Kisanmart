import Link from "next/link";

export default function NotFound() {
  return (
    <main className="km-page">
      <section className="auth-panel-wrap">
        <div className="auth-panel">
          <div className="auth-panel-eyebrow">KisanMart</div>
          <h2>We couldn’t find that page.</h2>
          <p className="auth-panel-intro">
            The address may have changed, or the page may not be part of this
            Phase 1 starter site.
          </p>
          <Link className="auth-submit" href="/">
            Back to KisanMart
          </Link>
        </div>
      </section>
    </main>
  );
}
