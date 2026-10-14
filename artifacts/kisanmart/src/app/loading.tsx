export default function Loading() {
  return (
    <main className="km-loading-page" aria-busy="true">
      <div className="km-loading-wrap">
        <p className="km-loading-status" role="status" aria-live="polite">
          Loading KisanMart…
        </p>
        <div className="km-skeleton km-skeleton-header" aria-hidden="true" />
        <div className="km-skeleton km-skeleton-hero" aria-hidden="true" />
        <div
          className="km-skeleton km-skeleton-title"
          aria-hidden="true"
        />
        <div className="km-skeleton-grid" aria-hidden="true">
          {Array.from({ length: 4 }, (_, index) => (
            <div className="km-skeleton km-skeleton-card" key={index} />
          ))}
        </div>
      </div>
    </main>
  );
}
