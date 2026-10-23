import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { api, ApiError, formatPrice, Gift, GiftList, giftPlace } from "../api";
import { Badge, Breadcrumb, ErrorBox, IllustrativeNote, Loading, Photo } from "../components";
import { Icon } from "../icons";
import { t } from "../i18n";
import { useApi, useStore } from "../store";

export default function GiftPage() {
  const { id = "" } = useParams();
  const nav = useNavigate();
  const { user, favorites, toggleFavorite, notify, meta } = useStore();
  const { data: gift, error, loading } = useApi<Gift>(`/gifts/${encodeURIComponent(id)}`);
  const { data: lists } = useApi<GiftList[]>(user ? "/lists" : null, [user?.id]);
  const [listId, setListId] = useState("");
  const [photo, setPhoto] = useState(0);
  const [busy, setBusy] = useState(false);

  useEffect(() => { if (lists?.length && !listId) setListId(String(lists[0].id)); }, [lists, listId]);

  if (loading) return <div className="wrap"><Loading /></div>;
  if (error || !gift) {
    return <div className="wrap"><Breadcrumb items={[[t("Accueil"), "/"], [t("Cadeaux"), "/cadeaux"]]} /><ErrorBox error={error?.status === 404 ? t("Ce cadeau n'existe plus.") : error} /></div>;
  }

  const wrap = meta?.wrappings[0];
  const photos = [gift.image_url, wrap?.image_url].filter(Boolean) as string[];
  const isFav = favorites.includes(gift.id);

  const addToList = async () => {
    if (!user) return nav(`/connexion?next=/cadeaux/${gift.slug}`);
    if (!listId) return nav("/listes");
    setBusy(true);
    try {
      await api(`/lists/${listId}/items`, { body: { gift_id: gift.id } });
      notify(t("« {name} » ajouté à votre liste.", { name: gift.name }));
    } catch (e) {
      notify(e instanceof ApiError ? e.message : t("Impossible d'ajouter ce cadeau."));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Accueil"), "/"], [t("Cadeaux"), "/cadeaux"], [gift.name]]} />
      <div className="product">
        <div>
          <Photo className="main-photo" src={photos[photo] ?? gift.image_url} alt={gift.name} />
          {photos.length > 1 && (
            <div className="thumbs">
              {photos.map((src, i) => (
                <button key={src} className={i === photo ? "on" : ""} onClick={() => setPhoto(i)} aria-label={t("Photo {n}", { n: i + 1 })}><img src={src} alt="" /></button>
              ))}
            </div>
          )}
          <IllustrativeNote />
        </div>

        <div className="product-info">
          <Badge status={gift.available ? "Disponible" : "Indisponible"} />
          <h1 className="display" style={{ fontSize: 52, lineHeight: 1.15 }}>{gift.name}</h1>
          <p className="big-price">{formatPrice(gift.price, gift.currency)}</p>
          <p className="place"><Icon name="pin" />{giftPlace(gift)}{gift.shop && ` · ${gift.shop}`}</p>
          {gift.description && <p className="lead" style={{ fontSize: 16 }}>{gift.description}</p>}
          <p className="small">{t("À vérifier auprès du marchand : disponibilité, retrait et modalités de livraison.")}</p>

          {user && lists && lists.length > 0 ? (
            <label className="field">
              <span>{t("Ajouter à une liste")}</span>
              <select className="input" value={listId} onChange={e => setListId(e.target.value)}>
                {lists.map(l => <option key={l.id} value={l.id}>{l.title}</option>)}
              </select>
            </label>
          ) : (
            <p className="small muted">{user ? t("Créez d'abord une liste pour y ajouter ce cadeau.") : t("Connectez-vous pour l'ajouter à une liste.")}</p>
          )}

          <div className="btn-row">
            <button className="btn btn-primary" onClick={addToList} disabled={busy}>
              {user && !lists?.length ? t("Créer une liste") : t("Ajouter à ma liste")} <Icon name="plus" size={18} />
            </button>
            <button className="btn btn-outline" onClick={() => toggleFavorite(gift)} aria-pressed={isFav}>
              {isFav ? t("Dans mes favoris") : t("Mes favoris")} <Icon name="heart" size={18} className={isFav ? "price fill" : "price"} />
            </button>
          </div>
          <Link to={`/commander/${gift.slug}`} className={`btn btn-outline btn-block ${gift.available ? "" : "disabled"}`} aria-disabled={!gift.available}>
            {t("Commander ce cadeau")}
          </Link>

          {wrap && (
            <div className="panel final-touch">
              {wrap.image_url && <img src={wrap.image_url} alt="" />}
              <div>
                <h3>{t("La touche finale")}</h3>
                <p>{wrap.name}{wrap.detail && ` · ${wrap.detail}`}.</p>
                <Link to={`/commander/${gift.slug}`} className="link">{t("Choisir ce modèle ou en découvrir d'autres →")}</Link>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
