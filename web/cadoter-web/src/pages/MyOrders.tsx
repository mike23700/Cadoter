import { Link } from "react-router-dom";
import { formatPrice, Order } from "../api";
import { locale, t } from "../i18n";
import { Breadcrumb, ErrorBox, Loading } from "../components";
import { useApi } from "../store";

const STATUS: Record<string, string> = { en_attente: "En attente de paiement", payee: "Payée", livree: "Livrée", annulee: "Annulée" };

export default function MyOrders() {
  const { data, error, loading, reload } = useApi<Order[]>("/orders/mine");
  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Mon espace"), "/listes"], [t("Mon historique")]]} />
      <h1 className="display page-title" style={{ fontSize: 52 }}>{t("Vos attentions offertes.")}</h1>
      <ErrorBox error={error} onRetry={reload} />
      {loading ? <Loading /> : data && data.length > 0 ? data.map(o => (
        <div key={o.id} className="list-row" style={{ gridTemplateColumns: "1fr auto auto" }}>
          <div>
            <h4>{o.gift_name} × {o.quantity}</h4>
            <p>{o.reference} · {new Date(o.created_at).toLocaleDateString(locale())}</p>
          </div>
          <span className={`badge ${o.status === "annulee" ? "off" : "ok"}`}>{t(STATUS[o.status] ?? o.status)}</span>
          <b className="price">{formatPrice(o.total, o.currency)}</b>
        </div>
      )) : <div className="empty">{t("Aucune commande pour l'instant.")} <Link className="link" to="/cadeaux">{t("Explorer les cadeaux →")}</Link></div>}
    </div>
  );
}
