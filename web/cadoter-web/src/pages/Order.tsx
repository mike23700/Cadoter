import { FormEvent, useEffect, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { api, ApiError, formatPrice, Gift, giftPlace, Order as OrderT } from "../api";
import { Breadcrumb, ErrorBox, Field, fieldError, Loading, Photo } from "../components";
import { Icon } from "../icons";
import { useApi, useStore } from "../store";

/** Commande d'un cadeau du catalogue (depuis la fiche ou une liste partagée). */
export default function Order() {
  const { slug = "" } = useParams();
  const [params] = useSearchParams();
  const listItem = params.get("item");
  const { user, meta } = useStore();
  const { data: gift, error, loading } = useApi<Gift>(`/gifts/${encodeURIComponent(slug)}`);

  const [form, setForm] = useState({
    customer_name: "", customer_phone: "", customer_email: "", delivery_city: "", delivery_address: "",
    message: "", quantity: 1, payment_method: "orange_money", wrapping_id: "" as number | "",
  });
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState<{ order: OrderT; message: string } | null>(null);

  useEffect(() => {
    if (user) setForm(f => ({ ...f, customer_name: f.customer_name || user.name, customer_phone: f.customer_phone || user.phone || "", customer_email: f.customer_email || user.email }));
  }, [user]);
  useEffect(() => { if (gift) setForm(f => ({ ...f, delivery_city: f.delivery_city || gift.city })); }, [gift]);

  if (loading) return <div className="wrap"><Loading /></div>;
  if (!gift) return <div className="wrap"><ErrorBox error={error ?? "Cadeau introuvable."} /></div>;

  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });
  const wrapping = meta?.wrappings.find(w => w.id === form.wrapping_id);
  const total = gift.price * form.quantity + (wrapping?.price ?? 0);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      setDone(await api("/orders", {
        body: { ...form, gift_id: gift.id, list_item_id: listItem ? Number(listItem) : null, wrapping_id: form.wrapping_id || null, quantity: Number(form.quantity) },
      }));
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  if (done) {
    return (
      <div className="wrap">
        <div className="panel success" style={{ marginTop: 50, maxWidth: 640, marginInline: "auto" }}>
          <span className="success-icon"><Icon name="check" size={30} /></span>
          <h1 className="h1">Merci pour cette belle attention.</h1>
          <p className="muted">{done.message}</p>
          <p>Référence : <b>{done.order.reference}</b> · Total : <b className="price">{formatPrice(done.order.total, done.order.currency)}</b></p>
          <p className="note">La facture est émise par la boutique. Livraison et retrait à confirmer avec le marchand.</p>
          <Link to="/cadeaux" className="btn btn-primary">Continuer mes découvertes</Link>
        </div>
      </div>
    );
  }

  return (
    <div className="wrap">
      <Breadcrumb items={[["Accueil", "/"], ["Cadeaux", "/cadeaux"], [gift.name, `/cadeaux/${gift.slug}`], ["Commander"]]} />
      <h1 className="display page-title" style={{ fontSize: 48 }}>Offrir, en toute simplicité.</h1>

      <form className="two-col custom" onSubmit={submit}>
        <div className="panel">
          <h2 className="h2" style={{ marginBottom: 24 }}>Vos coordonnées</h2>
          <div className="form">
            <div className="grid-2">
              <Field label="Nom *" error={fieldError(err, "customer_name")}><input className="input" required value={form.customer_name} onChange={set("customer_name")} placeholder="Aïcha Koné" /></Field>
              <Field label="Téléphone Mobile Money *" error={fieldError(err, "customer_phone")}><input className="input" required type="tel" value={form.customer_phone} onChange={set("customer_phone")} placeholder="+225 07 00 00 00 00" /></Field>
            </div>
            <div className="grid-2">
              <Field label="Email" error={fieldError(err, "customer_email")}><input className="input" type="email" value={form.customer_email} onChange={set("customer_email")} placeholder="aicha@exemple.com" /></Field>
              <Field label="Quantité"><input className="input" type="number" min={1} max={20} value={form.quantity} onChange={set("quantity")} /></Field>
            </div>
            <div className="grid-2">
              <Field label="Ville de livraison"><input className="input" value={form.delivery_city} onChange={set("delivery_city")} /></Field>
              <Field label="Adresse / quartier"><input className="input" value={form.delivery_address} onChange={set("delivery_address")} placeholder="Cocody, Riviera 2" /></Field>
            </div>
            <Field label="Petit mot (facultatif)"><textarea className="input" value={form.message} onChange={set("message")} placeholder="Joyeux anniversaire !" /></Field>
            <div className="field">
              <span>Paiement *</span>
              <div className="chips">
                {(meta?.payment_methods ?? [{ code: "orange_money", name: "Orange Money" }, { code: "mtn_momo", name: "MTN Mobile Money" }]).map(p => (
                  <button type="button" key={p.code} className={`chip ${form.payment_method === p.code ? "on" : ""}`} onClick={() => setForm({ ...form, payment_method: p.code })}>{p.name}</button>
                ))}
              </div>
            </div>
            <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
            <button className="btn btn-primary btn-block" disabled={busy || !gift.available}>
              {busy ? "Envoi…" : `Commander · ${formatPrice(total, gift.currency)}`}
            </button>
            <p className="note">Vous recevrez une demande de paiement Mobile Money. Un cadeau de liste n'est marqué « acheté » qu'une fois le paiement validé.</p>
          </div>
        </div>

        <div>
          <div className="order-summary">
            <Photo src={gift.image_url} alt={gift.name} />
            <div>
              <h3 className="h3">{gift.name}</h3>
              <p className="muted small">{giftPlace(gift)}</p>
              <p className="price">{formatPrice(gift.price, gift.currency)}</p>
            </div>
          </div>
          <h2 className="h2" style={{ margin: "28px 0 8px" }}>Et pour la touche finale…</h2>
          <p className="muted small">Des modèles d'exemple à choisir selon l'occasion.</p>
          <WrapPicker value={form.wrapping_id} onChange={id => setForm({ ...form, wrapping_id: id })} />
        </div>
      </form>
    </div>
  );
}

export function WrapPicker({ value, onChange }: { value: number | ""; onChange: (id: number | "") => void }) {
  const { meta } = useStore();
  const wraps = meta?.wrappings ?? [];
  return (
    <>
      <div className="wrap-grid" style={{ marginTop: 18 }}>
        {wraps.map(w => (
          <button type="button" key={w.id} className={`wrap-card ${value === w.id ? "on" : ""}`} onClick={() => onChange(w.id)} aria-pressed={value === w.id}>
            {w.image_url && <img src={w.image_url} alt="" />}
            <span><i className="radio">{value === w.id && <Icon name="check" size={12} />}</i>{w.name}</span>
            <small className="muted">{w.detail}{w.price ? ` · +${formatPrice(w.price)}` : ""}</small>
          </button>
        ))}
      </div>
      <button type="button" className="no-wrap" onClick={() => onChange("")}>
        <i className={`radio ${value === "" ? "on" : ""}`}>{value === "" && <Icon name="check" size={12} />}</i>
        Sans emballage · Visuels illustratifs, à confirmer lors du suivi.
      </button>
    </>
  );
}
