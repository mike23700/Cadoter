import { FormEvent, useCallback, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, ApiError, formatPrice, GiftList, ListItem } from "../api";
import { Badge, ErrorBox, Field, IllustrativeNote, Loading, Modal, Photo } from "../components";
import { Icon } from "../icons";
import { t } from "../i18n";
import { useStore } from "../store";

/** La liste vue par un proche : il choisit un cadeau et le réserve (une personne par cadeau). */
export default function Shared() {
  const { code = "" } = useParams();
  const { user, notify } = useStore();
  const [list, setList] = useState<GiftList | null>(null);
  const [locked, setLocked] = useState<string | null>(null);
  const [accessCode, setAccessCode] = useState(() => { try { return sessionStorage.getItem(`cadoter:code:${code}`) ?? ""; } catch { return ""; } });
  const [error, setError] = useState<ApiError | null>(null);
  const [loading, setLoading] = useState(true);
  const [reserving, setReserving] = useState<ListItem | null>(null);
  const [tried, setTried] = useState(false);

  const load = useCallback(async (ac = accessCode) => {
    setLoading(true);
    setError(null);
    try {
      setList(await api<GiftList>(`/l/${encodeURIComponent(code)}`, { headers: ac ? { "X-Access-Code": ac } : {} }));
      setLocked(null);
      try { if (ac) sessionStorage.setItem(`cadoter:code:${code}`, ac); } catch { /* ignore */ }
    } catch (e) {
      if (e instanceof ApiError && e.status === 423) setLocked(e.data?.title ?? t("Liste protégée"));
      else setError(e as ApiError);
    } finally {
      setLoading(false);
    }
  }, [code]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => { load(); }, [load]);

  if (loading && !list) return <div className="wrap"><Loading /></div>;

  if (locked) {
    const submit = (e: FormEvent) => { e.preventDefault(); setTried(true); load(accessCode); };
    return (
      <div className="wrap">
        <form className="lock panel" onSubmit={submit}>
          <Icon name="lock" size={30} className="price" />
          <h1 className="h1" style={{ fontSize: 32 }}>{locked}</h1>
          <p className="muted">{t("Cette liste est protégée. Saisissez le code d'accès transmis par son créateur.")}</p>
          <input className="input" autoFocus required placeholder={t("Code d'accès")} value={accessCode} onChange={e => setAccessCode(e.target.value)} />
          {tried && !loading && <p className="field-error">{t("Code incorrect. Vérifiez auprès du créateur de la liste.")}</p>}
          <button className="btn btn-primary btn-block">{t("Ouvrir la liste")}</button>
        </form>
      </div>
    );
  }

  if (error || !list) {
    return <div className="wrap"><div style={{ marginTop: 60 }}><ErrorBox error={error?.status === 404 ? t("Cette liste n'existe pas ou a été supprimée.") : error ?? t("Liste introuvable.")} /></div></div>;
  }

  const first = list.owner_name?.split(" ")[0] ?? t("votre proche");

  return (
    <div className="wrap">
      <div className="shared" style={{ marginTop: 32 }}>
        <Photo className="cover" src={list.image_url} alt="" />
        <p className="eyebrow">{t("La liste de {name}", { name: first })}</p>
        <h1 className="display" style={{ fontSize: 48, margin: "8px 0 14px" }}>{list.title}</h1>
        {list.description && <p className="lead">« {list.description} »</p>}

        <div className="panel" style={{ margin: "26px 0", padding: "18px 20px" }}>
          <b>{t("Choisissez une attention.")}</b>
          <p className="small" style={{ marginTop: 6 }}>{t("Réserver prévient les autres proches. Cela ne vaut pas achat : vous achetez ensuite auprès du marchand, ou directement ici.")}</p>
        </div>
        <IllustrativeNote />

        {list.items.length === 0 && <div className="empty" style={{ marginTop: 20 }}>{t("{name} n'a pas encore ajouté de cadeau.", { name: first })}</div>}
        {list.items.map(item => {
          const free = item.status === "Disponible";
          return (
            <div key={item.id} className="shared-row">
              {item.image_url ? <img src={item.image_url} alt="" /> : <div className="photo-empty thumb"><Icon name="gift" /></div>}
              <div>
                <h4>{item.name}</h4>
                {item.price != null && <p className="price small" style={{ marginBottom: 8 }}>{formatPrice(item.price, item.currency)}</p>}
                {item.description && <p className="note" style={{ marginBottom: 8 }}>{item.description}</p>}
                {item.seller_name && <p className="note" style={{ marginBottom: 8 }}>{item.gift_id == null && !item.external_url ? t("Lieu / boutique : {name}", { name: item.seller_name }) : t("Vendu par {name}", { name: item.seller_name })}</p>}
                <Badge status={item.status}>{free ? t("Disponible à réserver") : item.status === "Réservé" ? t("Réservé · indisponible") : t("Indisponible")}</Badge>
                {!free && <p className="note" style={{ marginTop: 6 }}>{t("Un proche a déjà choisi ce cadeau.")}</p>}
              </div>
              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                <button className="btn btn-primary" disabled={!free} onClick={() => setReserving(item)}>{t("Je réserve ce cadeau")}</button>
                {free && item.gift_slug && <Link className="link" style={{ justifyContent: "center" }} to={`/commander/${item.gift_slug}?item=${item.id}`}>{t("ou l'offrir directement →")}</Link>}
                {free && item.external_url && <a className="link" style={{ justifyContent: "center" }} href={item.external_url} target="_blank" rel="noreferrer noopener">{t("Voir chez le marchand →")}</a>}
              </div>
            </div>
          );
        })}
      </div>

      {reserving && (
        <ReserveModal item={reserving} defaultName={user?.name ?? ""} onClose={() => setReserving(null)}
          onConfirm={async name => {
            try {
              await api(`/l/${encodeURIComponent(code)}/items/${reserving.id}/reserve`, { body: { name, access_code: accessCode } });
              notify(t("Merci ! « {name} » vous est réservé.", { name: reserving.name }));
            } catch (e) {
              notify(e instanceof ApiError ? e.message : t("Réservation impossible."));
            }
            setReserving(null);
            load();
          }} />
      )}
    </div>
  );
}

function ReserveModal({ item, defaultName, onClose, onConfirm }: { item: ListItem; defaultName: string; onClose: () => void; onConfirm: (name: string) => Promise<void> }) {
  const [name, setName] = useState(defaultName);
  const [busy, setBusy] = useState(false);
  return (
    <Modal title={t("Je réserve ce cadeau")} onClose={onClose}>
      <form className="form" onSubmit={async e => { e.preventDefault(); setBusy(true); await onConfirm(name); }}>
        <p className="muted">{t("Vous réservez")} <b>{item.name}</b>. {t("Les autres proches verront qu'il est déjà choisi.")}</p>
        <Field label={t("Votre prénom (visible par le créateur de la liste)")}>
          <input className="input" required maxLength={120} value={name} onChange={e => setName(e.target.value)} placeholder="Fatou" />
        </Field>
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Réservation…") : t("Confirmer la réservation")}</button>
      </form>
    </Modal>
  );
}
