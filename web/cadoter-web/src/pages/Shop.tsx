import { useParams } from "react-router-dom";
import { Gift } from "../api";
import { Breadcrumb, ErrorBox, GiftCard, GiftGridSkeleton } from "../components";
import { locale, t, tn } from "../i18n";
import { useApi } from "../store";

type ShopT = { id: number; shop_name: string; created_at: string; gifts: Gift[] };

/** Page publique d'une boutique partenaire : ses produits en ligne. */
export default function Shop() {
  const { id = "" } = useParams();
  const { data: shop, error, loading, reload } = useApi<ShopT>(`/shops/${encodeURIComponent(id)}`);

  if (error?.status === 404) return <div className="wrap"><div className="empty" style={{ marginTop: 60 }}>{t("Boutique introuvable.")}</div></div>;

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Accueil"), "/"], [t("Cadeaux"), "/cadeaux"], [shop?.shop_name ?? t("Boutique")]]} />
      <ErrorBox error={error} onRetry={reload} />
      {loading && !shop ? <GiftGridSkeleton /> : shop && (
        <>
          <p className="eyebrow" style={{ marginBottom: 14 }}>{t("Boutique partenaire")}</p>
          <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>{shop.shop_name}</h1>
          <p className="lead page-lead">
            {tn(shop.gifts.length, "{n} cadeau en ligne", "{n} cadeaux en ligne")} · {t("Sur CADOTER depuis {date}", { date: new Date(shop.created_at).toLocaleDateString(locale(), { month: "long", year: "numeric" }) })}
          </p>
          {shop.gifts.length === 0
            ? <div className="empty">{t("Cette boutique n'a pas encore de produit en ligne.")}</div>
            : <div className="gift-grid" style={{ marginBottom: 60 }}>{shop.gifts.map(g => <GiftCard key={g.id} gift={g} />)}</div>}
        </>
      )}
    </div>
  );
}
