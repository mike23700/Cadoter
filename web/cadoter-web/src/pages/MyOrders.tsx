import { Link } from "react-router-dom";
import { formatPrice, Order } from "../api";
import { Breadcrumb, ErrorBox, Loading } from "../components";
import { useApi } from "../store";

const STATUS: Record<string, string> = { en_attente: "En attente de paiement", payee: "Payée", livree: "Livrée", annulee: "Annulée" };

export default function MyOrders() {
  const { data, error, loading, reload } = useApi<Order[]>("/orders/mine");
  return (
    <div className="wrap">
      <Breadcrumb items={[["Mon espace", "/listes"], ["Mon historique"]]} />
      <h1 className="display page-title" style={{ fontSize: 52 }}>Vos attentions offertes.</h1>
      <ErrorBox error={error} onRetry={reload} />
      {loading ? <Loading /> : data && data.length > 0 ? data.map(o => (
        <div key={o.id} className="list-row" style={{ gridTemplateColumns: "1fr auto auto" }}>
          <div>
            <h4>{o.gift_name} × {o.quantity}</h4>
            <p>{o.reference} · {new Date(o.created_at).toLocaleDateString("fr-FR")}</p>
          </div>
          <span className={`badge ${o.status === "annulee" ? "off" : "ok"}`}>{STATUS[o.status] ?? o.status}</span>
          <b className="price">{formatPrice(o.total, o.currency)}</b>
        </div>
      )) : <div className="empty">Aucune commande pour l'instant. <Link className="link" to="/cadeaux">Explorer les cadeaux →</Link></div>}
    </div>
  );
}
