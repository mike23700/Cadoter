import { Link } from "react-router-dom";
import { Gift } from "../api";
import { Breadcrumb, ErrorBox, GiftCard, GiftGridSkeleton } from "../components";
import { useApi, useStore } from "../store";

export default function Favorites() {
  const { favorites } = useStore();
  const { data, error, loading, reload } = useApi<Gift[]>("/favorites", [favorites.length]);
  return (
    <div className="wrap">
      <Breadcrumb items={[["Mon espace", "/listes"], ["Mes favoris"]]} />
      <h1 className="display page-title" style={{ fontSize: 52 }}>Vos coups de cœur.</h1>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <GiftGridSkeleton /> : data && data.length > 0
        ? <div className="gift-grid">{data.map(g => <GiftCard key={g.id} gift={g} />)}</div>
        : <div className="empty">Aucun favori pour l'instant. <Link className="link" to="/cadeaux">Explorer les cadeaux →</Link></div>}
    </div>
  );
}
