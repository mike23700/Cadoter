import { FormEvent, useState } from "react";
import { Link, NavLink, Route, Routes } from "react-router-dom";
import { api, ApiError, CustomRequest, formatPrice, Gift, Order } from "../api";
import { ErrorBox, Field, fieldError, Loading, Modal } from "../components";
import { Icon } from "../icons";
import { useApi, useStore } from "../store";

type Stats = { gifts: number; active_gifts: number; orders: number; pending_orders: number; revenue: number; custom_requests: number; users: number; lists: number };

const ORDER_STATUS: Record<string, string> = { en_attente: "En attente de paiement", payee: "Payée", livree: "Livrée", annulee: "Annulée" };
const REQUEST_STATUS: Record<string, string> = { nouvelle: "Nouvelle", en_cours: "En cours", traitee: "Traitée" };
const date = (s: string) => new Date(s).toLocaleString("fr-FR", { dateStyle: "short", timeStyle: "short" });

export default function Admin() {
  const { user, logout } = useStore();
  return (
    <div className="admin">
      <aside className="admin-side">
        <Link to="/" className="logo"><img src="/img/logo.png" alt="cadoter.com" /></Link>
        <p className="eyebrow" style={{ margin: "18px 0 10px" }}>Administration</p>
        <nav>
          <NavLink to="/admin" end><Icon name="clock" size={18} />Tableau de bord</NavLink>
          <NavLink to="/admin/cadeaux"><Icon name="gift" size={18} />Cadeaux</NavLink>
          <NavLink to="/admin/commandes"><Icon name="list" size={18} />Commandes</NavLink>
          <NavLink to="/admin/demandes"><Icon name="mail" size={18} />Demandes perso.</NavLink>
        </nav>
        <div className="admin-user">
          <b>{user?.name}</b>
          <span className="note">{user?.email}</span>
          <button className="link" onClick={logout}><Icon name="logout" size={16} />Se déconnecter</button>
        </div>
      </aside>
      <main className="admin-main">
        <Routes>
          <Route index element={<Dashboard />} />
          <Route path="cadeaux" element={<Gifts />} />
          <Route path="commandes" element={<Orders />} />
          <Route path="demandes" element={<Requests />} />
        </Routes>
      </main>
    </div>
  );
}

function Dashboard() {
  const { data, error, loading } = useApi<Stats>("/admin/stats");
  if (loading) return <Loading />;
  if (!data) return <ErrorBox error={error} />;
  const cards: [string, string | number, string][] = [
    ["Cadeaux en ligne", `${data.active_gifts} / ${data.gifts}`, "/admin/cadeaux"],
    ["Commandes en attente", data.pending_orders, "/admin/commandes"],
    ["Chiffre d'affaires (payé)", formatPrice(data.revenue), "/admin/commandes"],
    ["Demandes personnalisées", data.custom_requests, "/admin/demandes"],
    ["Utilisateurs", data.users, "/admin"],
    ["Listes créées", data.lists, "/admin"],
  ];
  return (
    <>
      <h1 className="h1">Tableau de bord</h1>
      <div className="stats">
        {cards.map(([label, value, to]) => (
          <Link to={to} key={label} className="stat"><span className="note">{label}</span><strong>{value}</strong></Link>
        ))}
      </div>
      <div className="panel rose" style={{ marginTop: 28 }}>
        <h2 className="h2">Ajouter un cadeau au catalogue</h2>
        <p className="muted small" style={{ margin: "10px 0 16px" }}>Les cadeaux publiés apparaissent immédiatement sur l'accueil, le catalogue, l'assistante IA et l'application mobile.</p>
        <Link to="/admin/cadeaux?new=1" className="btn btn-primary">Nouveau cadeau <Icon name="plus" size={18} /></Link>
      </div>
    </>
  );
}

function Gifts() {
  const { notify } = useStore();
  const [q, setQ] = useState("");
  const { data, error, loading, reload } = useApi<Gift[]>(`/admin/gifts${q ? `?q=${encodeURIComponent(q)}` : ""}`);
  const [editing, setEditing] = useState<Gift | "new" | null>(() => (new URLSearchParams(window.location.search).get("new") ? "new" : null));

  const toggle = async (g: Gift, key: "is_active" | "is_featured") => {
    await api(`/admin/gifts/${g.id}`, { method: "PUT", body: { [key]: !g[key] } });
    reload();
  };
  const remove = async (g: Gift) => {
    if (!window.confirm(`Supprimer « ${g.name} » du catalogue ?`)) return;
    await api(`/admin/gifts/${g.id}`, { method: "DELETE" });
    notify("Cadeau supprimé.");
    reload();
  };

  return (
    <>
      <div className="admin-head">
        <h1 className="h1">Cadeaux</h1>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>Nouveau cadeau <Icon name="plus" size={18} /></button>
      </div>
      <input className="input" style={{ maxWidth: 360, marginBottom: 20 }} placeholder="Rechercher un cadeau…" value={q} onChange={e => setQ(e.target.value)} />
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th></th><th>Cadeau</th><th>Prix</th><th>Lieu</th><th>Stock</th><th>En ligne</th><th>À la une</th><th></th></tr></thead>
            <tbody>
              {data?.map(g => (
                <tr key={g.id}>
                  <td>{g.image_url && <img src={g.image_url} alt="" className="table-thumb" />}</td>
                  <td><b>{g.name}</b><br /><span className="note">{(g.occasions ?? []).join(", ")}</span></td>
                  <td>{formatPrice(g.price, g.currency)}</td>
                  <td>{g.city}{g.area && ` · ${g.area}`}</td>
                  <td>{g.stock ?? "∞"}</td>
                  <td><button className={`switch ${g.is_active ? "on" : ""}`} onClick={() => toggle(g, "is_active")} aria-label="En ligne" aria-pressed={g.is_active} /></td>
                  <td><button className={`switch ${g.is_featured ? "on" : ""}`} onClick={() => toggle(g, "is_featured")} aria-label="À la une" aria-pressed={g.is_featured} /></td>
                  <td className="actions">
                    <button className="link" onClick={() => setEditing(g)}>Modifier</button>
                    <button className="link-plain" onClick={() => remove(g)}>Supprimer</button>
                  </td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={8} className="muted" style={{ textAlign: "center", padding: 30 }}>Aucun cadeau. Créez le premier !</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <GiftForm gift={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify("Cadeau enregistré."); }} />}
    </>
  );
}

function GiftForm({ gift, onClose, onSaved }: { gift: Gift | null; onClose: () => void; onSaved: () => void }) {
  const { meta } = useStore();
  const [form, setForm] = useState({
    name: gift?.name ?? "", description: gift?.description ?? "", price: gift ? String(gift.price) : "",
    city: gift?.city ?? "Abidjan", area: gift?.area ?? "", shop: gift?.shop ?? "", category: gift?.category ?? "",
    stock: gift?.stock != null ? String(gift.stock) : "", is_active: gift?.is_active ?? true, is_featured: gift?.is_featured ?? false,
  });
  const [forWho, setForWho] = useState<string[]>(gift?.for_who ?? []);
  const [occasions, setOccasions] = useState<string[]>(gift?.occasions ?? []);
  const [image, setImage] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(gift?.image_url ?? null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });
  const flip = (arr: string[], v: string) => (arr.includes(v) ? arr.filter(x => x !== v) : [...arr, v]);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, typeof v === "boolean" ? (v ? "1" : "0") : v));
    fd.append("for_who", JSON.stringify(forWho));
    fd.append("occasions", JSON.stringify(occasions));
    if (image) fd.append("image", image);
    setBusy(true);
    setErr(null);
    try {
      await api(gift ? `/admin/gifts/${gift.id}` : "/admin/gifts", { body: fd });
      onSaved();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={gift ? "Modifier le cadeau" : "Nouveau cadeau"} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <div className="image-picker">
          {preview ? <img src={preview} alt="" /> : <div className="photo-empty"><Icon name="image" size={30} /></div>}
          <Field label={`Photo ${gift ? "" : "*"} (JPG, PNG, WEBP · 5 Mo max.)`} error={fieldError(err, "image")}>
            <input className="input" type="file" accept="image/png,image/jpeg,image/webp" onChange={e => {
              const f = e.target.files?.[0] ?? null;
              setImage(f);
              if (f) setPreview(URL.createObjectURL(f));
            }} />
          </Field>
        </div>
        <Field label="Nom *" error={fieldError(err, "name")}><input className="input" required value={form.name} onChange={set("name")} placeholder="Le rituel du thé" /></Field>
        <Field label="Description" error={fieldError(err, "description")}><textarea className="input" value={form.description} onChange={set("description")} /></Field>
        <div className="grid-2">
          <Field label="Prix (FCFA) *" error={fieldError(err, "price")}><input className="input" type="number" min={0} required value={form.price} onChange={set("price")} /></Field>
          <Field label="Stock (vide = illimité)" error={fieldError(err, "stock")}><input className="input" type="number" min={0} value={form.stock} onChange={set("stock")} /></Field>
        </div>
        <div className="grid-2">
          <Field label="Ville *" error={fieldError(err, "city")}><input className="input" required list="cities" value={form.city} onChange={set("city")} /></Field>
          <Field label="Quartier"><input className="input" value={form.area} onChange={set("area")} placeholder="Cocody" /></Field>
        </div>
        <datalist id="cities">{(meta?.cities ?? []).map(c => <option key={c} value={c} />)}</datalist>
        <div className="grid-2">
          <Field label="Boutique"><input className="input" value={form.shop} onChange={set("shop")} /></Field>
          <Field label="Catégorie"><input className="input" value={form.category} onChange={set("category")} placeholder="Maison, Fleurs…" /></Field>
        </div>
        <div className="field"><span>Pour qui ?</span>
          <div className="chips">{(meta?.for_who ?? []).map(f => <button type="button" key={f} className={`chip ${forWho.includes(f) ? "on" : ""}`} onClick={() => setForWho(flip(forWho, f))}>{f}</button>)}</div>
        </div>
        <div className="field"><span>Occasions</span>
          <div className="chips">{(meta?.occasions ?? []).map(o => <button type="button" key={o} className={`chip ${occasions.includes(o) ? "on" : ""}`} onClick={() => setOccasions(flip(occasions, o))}>{o}</button>)}</div>
        </div>
        <div className="chips">
          <label className="check"><input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} /><span className="box"><Icon name="check" size={14} /></span>En ligne</label>
          <label className="check"><input type="checkbox" checked={form.is_featured} onChange={e => setForm({ ...form, is_featured: e.target.checked })} /><span className="box"><Icon name="check" size={14} /></span>À la une (page d'accueil)</label>
        </div>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Enregistrement…" : "Enregistrer"}</button>
      </form>
    </Modal>
  );
}

function Orders() {
  const [status, setStatus] = useState("");
  const { data, error, loading, reload } = useApi<Order[]>(`/admin/orders${status ? `?status=${status}` : ""}`);
  const update = async (o: Order, s: string) => { await api(`/admin/orders/${o.id}`, { method: "PUT", body: { status: s } }); reload(); };
  return (
    <>
      <div className="admin-head"><h1 className="h1">Commandes</h1></div>
      <div className="chips" style={{ marginBottom: 20 }}>
        {[["", "Toutes"], ...Object.entries(ORDER_STATUS)].map(([k, l]) => <button key={k} className={`chip ${status === k ? "on" : ""}`} onClick={() => setStatus(k)}>{l}</button>)}
      </div>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>Réf.</th><th>Date</th><th>Cadeau</th><th>Client</th><th>Livraison</th><th>Paiement</th><th>Total</th><th>Statut</th></tr></thead>
            <tbody>
              {data?.map(o => (
                <tr key={o.id}>
                  <td><b>{o.reference}</b></td>
                  <td>{date(o.created_at)}</td>
                  <td>{o.gift_name} × {o.quantity}{o.wrapping && <><br /><span className="note">Emballage : {o.wrapping.name}</span></>}{o.message && <><br /><span className="note">« {o.message} »</span></>}</td>
                  <td>{o.customer_name}<br /><a className="note" href={`tel:${o.customer_phone}`}>{o.customer_phone}</a></td>
                  <td>{[o.delivery_city, o.delivery_address].filter(Boolean).join(", ") || "—"}</td>
                  <td>{o.payment_method === "mtn_momo" ? "MTN MoMo" : "Orange Money"}</td>
                  <td className="price">{formatPrice(o.total, o.currency)}</td>
                  <td><select className="input input-sm" value={o.status} onChange={e => update(o, e.target.value)}>{Object.entries(ORDER_STATUS).map(([k, l]) => <option key={k} value={k}>{l}</option>)}</select></td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={8} className="muted" style={{ textAlign: "center", padding: 30 }}>Aucune commande.</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

function Requests() {
  const { data, error, loading, reload } = useApi<CustomRequest[]>("/admin/custom-requests");
  const update = async (r: CustomRequest, s: string) => { await api(`/admin/custom-requests/${r.id}`, { method: "PUT", body: { status: s } }); reload(); };
  return (
    <>
      <div className="admin-head"><h1 className="h1">Demandes personnalisées</h1></div>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>Date</th><th>Client</th><th>Budget</th><th>Description</th><th>Emballage</th><th>Statut</th></tr></thead>
            <tbody>
              {data?.map(r => (
                <tr key={r.id}>
                  <td>{date(r.created_at)}</td>
                  <td>{r.name}<br /><a className="note" href={`tel:${r.phone}`}>{r.phone}</a></td>
                  <td className="price">{formatPrice(r.budget)}</td>
                  <td style={{ maxWidth: 380 }}>{r.description}</td>
                  <td>{r.wrapping?.name ?? "Sans"}</td>
                  <td><select className="input input-sm" value={r.status} onChange={e => update(r, e.target.value)}>{Object.entries(REQUEST_STATUS).map(([k, l]) => <option key={k} value={k}>{l}</option>)}</select></td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 30 }}>Aucune demande.</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}
