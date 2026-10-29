import { FormEvent, useState } from "react";
import { Link, Navigate, NavLink, Route, Routes } from "react-router-dom";
import { AdminArticle, AdminFaq, api, ApiError, CustomRequest, formatDateTime as date, formatPrice, Gift, Order, User, Wrapping } from "../api";
import { ErrorBox, Field, fieldError, LangSwitch, Loading, Modal } from "../components";
import { t } from "../i18n";
import { Icon } from "../icons";
import { useApi, useStore } from "../store";

type Stats = { gifts: number; active_gifts: number; orders: number; pending_orders: number; revenue: number; custom_requests: number; users: number; lists: number };

const ORDER_STATUS: Record<string, string> = { en_attente: "En attente de paiement", payee: "Payée", livree: "Livrée", annulee: "Annulée" };
const COUNTRIES = ["Côte d'Ivoire", "Sénégal", "Mali", "Burkina Faso", "Bénin", "Togo", "Guinée", "Niger", "Cameroun", "Gabon", "Congo", "RD Congo", "Ghana", "Nigeria", "France"];
const ROLES: Record<string, string> = { user: "Client", partner: "Boutique", admin: "Administrateur" };
const REQUEST_STATUS: Record<string, string> = { nouvelle: "Nouvelle", en_cours: "En cours", traitee: "Traitée" };

export default function Admin() {
  const { user, logout } = useStore();
  const isPartner = user?.role === "partner";
  return (
    <div className="admin">
      <aside className="admin-side">
        <Link to="/" className="logo"><img src="/img/logo.png" alt="cadoter.com" /></Link>
        <p className="eyebrow admin-eyebrow">{isPartner ? t("Espace boutique") : t("Administration")}</p>
        <nav>
          <NavLink to="/admin" end><Icon name="clock" size={18} />{isPartner ? t("Accueil") : t("Tableau de bord")}</NavLink>
          <NavLink to="/admin/cadeaux"><Icon name="gift" size={18} />{t("Cadeaux")}</NavLink>
          {!isPartner && <>
            <NavLink to="/admin/utilisateurs"><Icon name="user" size={18} />{t("Utilisateurs")}</NavLink>
            <NavLink to="/admin/boutiques"><Icon name="user" size={18} />{t("Boutiques partenaires")}</NavLink>
            <NavLink to="/admin/emballages"><Icon name="image" size={18} />{t("Emballages")}</NavLink>
            <NavLink to="/admin/commandes"><Icon name="list" size={18} />{t("Commandes")}</NavLink>
            <NavLink to="/admin/demandes"><Icon name="mail" size={18} />{t("Demandes perso.")}</NavLink>
            <NavLink to="/admin/inspirations"><Icon name="sparkle" size={18} />{t("Inspirations")}</NavLink>
            <NavLink to="/admin/faq"><Icon name="help" size={18} />{t("FAQ & contact")}</NavLink>
          </>}
        </nav>
        <div className="admin-user">
          <b>{isPartner ? user?.shop_name : user?.name}</b>
          <span className="note admin-email">{user?.email}</span>
          <LangSwitch />
          <button className="link" onClick={logout}><Icon name="logout" size={16} />{t("Se déconnecter")}</button>
        </div>
      </aside>
      <main className="admin-main">
        <Routes>
          <Route index element={isPartner ? <PartnerDashboard /> : <Dashboard />} />
          <Route path="cadeaux" element={<Gifts />} />
          {!isPartner && <>
            <Route path="utilisateurs" element={<Users />} />
            <Route path="boutiques" element={<Partners />} />
            <Route path="emballages" element={<Wrappings />} />
            <Route path="commandes" element={<Orders />} />
            <Route path="demandes" element={<Requests />} />
            <Route path="inspirations" element={<Inspirations />} />
            <Route path="faq" element={<Faqs />} />
          </>}
          <Route path="*" element={<Navigate to="/admin" replace />} />
        </Routes>
      </main>
    </div>
  );
}

function PartnerDashboard() {
  const { user } = useStore();
  const { data, error, loading, reload } = useApi<{ active_gifts: number; revenue: number }>("/admin/partner-stats");
  return (
    <>
      <h1 className="h1">{t("Bienvenue chez {name}", { name: user?.shop_name || t("votre boutique") })}</h1>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : data && (
        <div className="stats" style={{ marginBottom: 28 }}>
          <Link to="/admin/cadeaux" className="stat">
            <span className="note">{t("Cadeaux en ligne")}</span>
            <strong>{data.active_gifts}</strong>
            <span className="note">{t("Produits actuellement publiés")}</span>
          </Link>
          <div className="stat">
            <span className="note">{t("Chiffre d’affaires")}</span>
            <strong>{formatPrice(data.revenue)}</strong>
            <span className="note">{t("Commandes payées ou livrées")}</span>
          </div>
        </div>
      )}
      <div className="panel rose">
        <h2 className="h2">{t("Vos produits sur CADOTER")}</h2>
        <p className="muted small" style={{ margin: "10px 0 16px" }}>
          {t("Publiez vos cadeaux et gérez uniquement les produits de votre boutique. Ils apparaîtront dans le catalogue avec le nom de votre enseigne.")}
        </p>
        <Link to="/admin/cadeaux?new=1" className="btn btn-primary">{t("Publier un produit")} <Icon name="plus" size={18} /></Link>
      </div>
    </>
  );
}

type Partner = Pick<User, "id" | "name" | "email" | "phone" | "shop_name"> & { created_at: string };

function Partners() {
  const { notify } = useStore();
  const { data, error, loading, reload } = useApi<Partner[]>("/admin/partners");
  const [editing, setEditing] = useState<Partner | "new" | null>(null);

  return (
    <>
      <div className="admin-head">
        <h1 className="h1">Boutiques partenaires</h1>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>Ouvrir un compte <Icon name="plus" size={18} /></button>
      </div>
      <p className="muted small" style={{ marginBottom: 20 }}>Créez les accès des boutiques qui pourront publier et gérer leurs propres produits.</p>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>Boutique</th><th>Responsable</th><th>Email</th><th>Téléphone</th><th>Compte créé</th><th></th></tr></thead>
            <tbody>
              {data?.map(partner => (
                <tr key={partner.id}>
                  <td><b>{partner.shop_name}</b></td>
                  <td>{partner.name}</td>
                  <td>{partner.email}</td>
                  <td>{partner.phone || "—"}</td>
                  <td>{date(partner.created_at)}</td>
                  <td className="actions"><button className="link" onClick={() => setEditing(partner)}>{t("Modifier")}</button></td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 30 }}>Aucune boutique partenaire. Ouvrez le premier compte.</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <PartnerForm partner={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(editing === "new" ? "Compte boutique créé." : t("Boutique mise à jour.")); }} />}
    </>
  );
}

function PartnerForm({ partner, onClose, onSaved }: { partner: Partner | null; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({ name: partner?.name ?? "", shop_name: partner?.shop_name ?? "", email: partner?.email ?? "", phone: partner?.phone ?? "", password: "", password_confirmation: "" });
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (key: keyof typeof form) => (event: { target: { value: string } }) => setForm({ ...form, [key]: event.target.value });

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await api(partner ? `/admin/partners/${partner.id}` : "/admin/partners", { method: partner ? "PUT" : "POST", body: { ...form, phone: form.phone || null } });
      onSaved();
    } catch (e) {
      setError(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={partner ? t("Modifier la boutique") : "Ouvrir un compte boutique"} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <Field label="Nom de la boutique *" error={fieldError(error, "shop_name")}>
          <input className="input" required maxLength={120} value={form.shop_name} onChange={set("shop_name")} placeholder="Les fleurs de Grâce" />
        </Field>
        <Field label="Nom du responsable *" error={fieldError(error, "name")}>
          <input className="input" required maxLength={120} value={form.name} onChange={set("name")} placeholder="Grâce Kouassi" />
        </Field>
        <div className="grid-2">
          <Field label="Email de connexion *" error={fieldError(error, "email")}>
            <input className="input" type="email" required value={form.email} onChange={set("email")} />
          </Field>
          <Field label="Téléphone" error={fieldError(error, "phone")}>
            <input className="input" type="tel" value={form.phone} onChange={set("phone")} />
          </Field>
        </div>
        <div className="grid-2">
          <Field label={partner ? t("Nouveau mot de passe") : "Mot de passe initial *"} error={fieldError(error, "password")}>
            <input className="input" type="password" required={!partner} minLength={8} autoComplete="new-password" value={form.password} onChange={set("password")} />
          </Field>
          <Field label={partner ? t("Confirmer le mot de passe") : "Confirmer le mot de passe *"} error={fieldError(error, "password_confirmation")}>
            <input className="input" type="password" required={!partner || !!form.password} minLength={8} autoComplete="new-password" value={form.password_confirmation} onChange={set("password_confirmation")} />
          </Field>
        </div>
        {partner && <p className="note">{t("Laissez vide pour garder le mot de passe actuel. Un nouveau mot de passe déconnecte la boutique de ses appareils.")}</p>}
        <ErrorBox error={error instanceof ApiError && !Object.keys(error.errors).length ? error : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{partner ? (busy ? t("Enregistrement…") : t("Enregistrer")) : (busy ? "Création…" : "Créer le compte")}</button>
      </form>
    </Modal>
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
      <h1 className="h1">{t("Tableau de bord")}</h1>
      <div className="stats">
        {cards.map(([label, value, to]) => (
          <Link to={to} key={label} className="stat"><span className="note">{t(label)}</span><strong>{value}</strong></Link>
        ))}
      </div>
      <div className="panel rose" style={{ marginTop: 28 }}>
        <h2 className="h2">{t("Ajouter un cadeau au catalogue")}</h2>
        <p className="muted small" style={{ margin: "10px 0 16px" }}>{t("Les cadeaux publiés apparaissent immédiatement sur l'accueil, le catalogue, l'assistante IA et l'application mobile.")}</p>
        <Link to="/admin/cadeaux?new=1" className="btn btn-primary">{t("Nouveau cadeau")} <Icon name="plus" size={18} /></Link>
      </div>
    </>
  );
}

function Gifts() {
  const { notify, user } = useStore();
  const isPartner = user?.role === "partner";
  const [q, setQ] = useState("");
  const { data, error, loading, reload } = useApi<Gift[]>(`/admin/gifts${q ? `?q=${encodeURIComponent(q)}` : ""}`);
  const [editing, setEditing] = useState<Gift | "new" | null>(() => (new URLSearchParams(window.location.search).get("new") ? "new" : null));

  const toggle = async (g: Gift, key: "is_active" | "is_featured") => {
    await api(`/admin/gifts/${g.id}`, { method: "PUT", body: { [key]: !g[key] } });
    reload();
  };
  const remove = async (g: Gift) => {
    if (!window.confirm(t("Supprimer « {name} » du catalogue ?", { name: g.name }))) return;
    await api(`/admin/gifts/${g.id}`, { method: "DELETE" });
    notify(t("Cadeau supprimé."));
    reload();
  };

  return (
    <>
      <div className="admin-head">
        <h1 className="h1">{t("Cadeaux")}</h1>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>{t("Nouveau cadeau")} <Icon name="plus" size={18} /></button>
      </div>
      <input className="input admin-search" placeholder={t("Rechercher un cadeau…")} value={q} onChange={e => setQ(e.target.value)} />
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th></th><th>{t("Cadeau")}</th>{!isPartner && <th>{t("Vendeur")}</th>}<th>{t("Prix")}</th><th>{t("Lieu")}</th><th>{t("Stock")}</th><th>{t("En ligne")}</th>{!isPartner && <th>{t("À la une")}</th>}<th></th></tr></thead>
            <tbody>
              {data?.map(g => (
                <tr key={g.id}>
                  <td className="cell-thumb">{g.image_url && <img src={g.image_url} alt="" className="table-thumb" />}</td>
                  <td className="cell-main"><b>{g.name}</b><br /><span className="note">{(g.occasions ?? []).map(o => t(o)).join(", ")}</span></td>
                  {!isPartner && <td data-label={t("Vendeur")}>{g.seller_name}</td>}
                  <td data-label={t("Prix")}>{formatPrice(g.price, g.currency)}</td>
                  <td data-label={t("Lieu")}>{g.city}{g.area && ` · ${g.area}`}</td>
                  <td data-label={t("Stock")}>{g.stock ?? "∞"}</td>
                  <td data-label={t("En ligne")}><button className={`switch ${g.is_active ? "on" : ""}`} onClick={() => toggle(g, "is_active")} aria-label={t("En ligne")} aria-pressed={g.is_active} /></td>
                  {!isPartner && <td data-label={t("À la une")}><button className={`switch ${g.is_featured ? "on" : ""}`} onClick={() => toggle(g, "is_featured")} aria-label={t("À la une")} aria-pressed={g.is_featured} /></td>}
                  <td className="actions">
                    <button className="link" onClick={() => setEditing(g)}>{t("Modifier")}</button>
                    <button className="link-plain" onClick={() => remove(g)}>{t("Supprimer")}</button>
                  </td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={isPartner ? 7 : 9} className="muted" style={{ textAlign: "center", padding: 30 }}>{isPartner ? t("Aucun produit publié. Ajoutez le premier !") : t("Aucun cadeau. Créez le premier !")}</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <GiftForm gift={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(t("Cadeau enregistré.")); }} />}
    </>
  );
}

function GiftForm({ gift, onClose, onSaved }: { gift: Gift | null; onClose: () => void; onSaved: () => void }) {
  const { meta, user } = useStore();
  const isPartner = user?.role === "partner";
  const [form, setForm] = useState({
    name: gift?.name ?? "", description: gift?.description ?? "", price: gift ? String(gift.price) : "",
    country: gift?.country ?? "Côte d'Ivoire", city: gift?.city ?? "Abidjan", area: gift?.area ?? "", shop: gift?.shop ?? "", category: gift?.category ?? "",
    stock: gift?.stock != null ? String(gift.stock) : "", is_active: gift?.is_active ?? true, is_featured: gift?.is_featured ?? false,
  });
  const [forWho, setForWho] = useState<string[]>(gift?.for_who ?? []);
  const [occasions, setOccasions] = useState<string[]>(gift?.occasions ?? []);
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>(gift?.image_urls?.length ? gift.image_urls : gift?.image_url ? [gift.image_url] : []);
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
    images.forEach(image => fd.append("images[]", image));
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
    <Modal title={gift ? t("Modifier le cadeau") : t("Nouveau cadeau")} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <div className="image-picker">
          <div className="gift-image-previews">
            {previews.length ? previews.map((src, index) => <img key={`${src}-${index}`} className="gift-image-preview" src={src} alt={t("Photo {n}", { n: index + 1 })} />) : <div className="photo-empty"><Icon name="image" size={30} /></div>}
          </div>
          <Field label={t("Photos {required} (JPG, PNG, WEBP · 5 Mo max. chacune)", { required: gift ? "" : "*" })} error={fieldError(err, "images")}>
            <input className="input" type="file" multiple accept="image/png,image/jpeg,image/webp" onChange={e => {
              const selected = Array.from(e.currentTarget.files ?? []);
              if (selected.length > 4) {
                const message = t("Un cadeau peut avoir au maximum 4 photos.");
                setErr(new ApiError(message, 422, { images: [message] }));
                e.currentTarget.value = "";
                return;
              }
              setErr(null);
              setImages(selected);
              setPreviews(selected.map(file => URL.createObjectURL(file)));
            }} />
            <p className="note">{t("Jusqu’à 4 photos. Si vous les remplacez, sélectionnez toutes celles à conserver.")}</p>
          </Field>
        </div>
        <Field label={t("Nom *")} error={fieldError(err, "name")}><input className="input" required value={form.name} onChange={set("name")} placeholder={t("Le rituel du thé")} /></Field>
        <Field label={t("Description")} error={fieldError(err, "description")}><textarea className="input" value={form.description} onChange={set("description")} /></Field>
        <div className="grid-2">
          <Field label={t("Prix (FCFA) *")} error={fieldError(err, "price")}><input className="input" type="number" min={0} required value={form.price} onChange={set("price")} /></Field>
          <Field label={t("Stock (vide = illimité)")} error={fieldError(err, "stock")}><input className="input" type="number" min={0} value={form.stock} onChange={set("stock")} /></Field>
        </div>
        <Field label={t("Pays *")} error={fieldError(err, "country")}><input className="input" required maxLength={80} list="countries" value={form.country} onChange={set("country")} /></Field>
        <datalist id="countries">{COUNTRIES.map(c => <option key={c} value={c} />)}</datalist>
        <div className="grid-2">
          <Field label={t("Ville *")} error={fieldError(err, "city")}><input className="input" required list="cities" value={form.city} onChange={set("city")} /></Field>
          <Field label={t("Quartier")}><input className="input" value={form.area} onChange={set("area")} placeholder="Cocody" /></Field>
        </div>
        <datalist id="cities">{(meta?.cities ?? []).map(c => <option key={c} value={c} />)}</datalist>
        <div className="grid-2">
          <Field label={t("Point de vente")}><input className="input" value={form.shop} onChange={set("shop")} placeholder={t("Adresse ou nom du point de vente")} /></Field>
          <Field label={t("Catégorie")}><input className="input" value={form.category} onChange={set("category")} placeholder={t("Maison, Fleurs…")} /></Field>
        </div>
        <div className="field"><span>{t("Pour qui ?")}</span>
          <div className="chips">{(meta?.for_who ?? []).map(f => <button type="button" key={f} className={`chip ${forWho.includes(f) ? "on" : ""}`} onClick={() => setForWho(flip(forWho, f))}>{t(f)}</button>)}</div>
        </div>
        <div className="field"><span>{t("Occasions")}</span>
          <div className="chips">{(meta?.occasions ?? []).map(o => <button type="button" key={o} className={`chip ${occasions.includes(o) ? "on" : ""}`} onClick={() => setOccasions(flip(occasions, o))}>{t(o)}</button>)}</div>
        </div>
        <div className="chips">
          <label className="check"><input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} /><span className="box"><Icon name="check" size={14} /></span>{t("En ligne")}</label>
          {!isPartner && <label className="check"><input type="checkbox" checked={form.is_featured} onChange={e => setForm({ ...form, is_featured: e.target.checked })} /><span className="box"><Icon name="check" size={14} /></span>{t("À la une (page d'accueil)")}</label>}
        </div>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button>
      </form>
    </Modal>
  );
}

function Wrappings() {
  const { notify } = useStore();
  const { data, error, loading, reload } = useApi<Wrapping[]>("/admin/wrappings");
  const [editing, setEditing] = useState<Wrapping | "new" | null>(null);

  const toggle = async (w: Wrapping) => {
    await api(`/admin/wrappings/${w.id}`, { method: "PUT", body: { is_active: !w.is_active } });
    reload();
  };
  const remove = async (w: Wrapping) => {
    if (!window.confirm(t("Supprimer l'emballage « {name} » ? Les commandes passées gardent leur historique.", { name: w.name }))) return;
    await api(`/admin/wrappings/${w.id}`, { method: "DELETE" });
    notify(t("Emballage supprimé."));
    reload();
  };

  return (
    <>
      <div className="admin-head">
        <h1 className="h1">{t("Emballages")}</h1>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>{t("Nouvel emballage")} <Icon name="plus" size={18} /></button>
      </div>
      <p className="muted small" style={{ marginBottom: 20 }}>
        {t("Proposés au moment de commander un cadeau et dans le formulaire « cadeau personnalisé », sur le web et le mobile. Un emballage hors ligne n'est plus proposé aux clients.")}
      </p>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th></th><th>{t("Emballage")}</th><th>{t("Supplément")}</th><th>{t("Ordre")}</th><th>{t("En ligne")}</th><th></th></tr></thead>
            <tbody>
              {data?.map(w => (
                <tr key={w.id}>
                  <td className="cell-thumb">{w.image_url && <img src={w.image_url} alt="" className="table-thumb" />}</td>
                  <td className="cell-main"><b>{w.name}</b><br /><span className="note">{w.detail}</span></td>
                  <td data-label={t("Supplément")}>{w.price ? `+ ${formatPrice(w.price)}` : t("Offert")}</td>
                  <td data-label={t("Ordre")}>{w.position}</td>
                  <td data-label={t("En ligne")}><button className={`switch ${w.is_active ? "on" : ""}`} onClick={() => toggle(w)} aria-label={t("En ligne")} aria-pressed={w.is_active} /></td>
                  <td className="actions">
                    <button className="link" onClick={() => setEditing(w)}>{t("Modifier")}</button>
                    <button className="link-plain" onClick={() => remove(w)}>{t("Supprimer")}</button>
                  </td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucun emballage. Créez le premier !")}</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <WrappingForm wrapping={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(t("Emballage enregistré.")); }} />}
    </>
  );
}

function WrappingForm({ wrapping, onClose, onSaved }: { wrapping: Wrapping | null; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    name: wrapping?.name ?? "", detail: wrapping?.detail ?? "", price: wrapping ? String(wrapping.price) : "0",
    position: wrapping ? String(wrapping.position) : "", is_active: wrapping?.is_active ?? true,
  });
  const [image, setImage] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(wrapping?.image_url ?? null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, typeof v === "boolean" ? (v ? "1" : "0") : v));
    if (image) fd.append("image", image);
    setBusy(true);
    setErr(null);
    try {
      await api(wrapping ? `/admin/wrappings/${wrapping.id}` : "/admin/wrappings", { body: fd });
      onSaved();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={wrapping ? t("Modifier l'emballage") : t("Nouvel emballage")} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <div className="image-picker">
          {preview ? <img src={preview} alt="" /> : <div className="photo-empty"><Icon name="image" size={30} /></div>}
          <Field label={t("Photo {required} (JPG, PNG, WEBP · 5 Mo max.)", { required: wrapping ? "" : "*" })} error={fieldError(err, "image")}>
            <input className="input" type="file" accept="image/png,image/jpeg,image/webp" onChange={e => {
              const f = e.target.files?.[0] ?? null;
              setImage(f);
              if (f) setPreview(URL.createObjectURL(f));
            }} />
          </Field>
        </div>
        <Field label={t("Nom *")} error={fieldError(err, "name")}><input className="input" required maxLength={120} value={form.name} onChange={set("name")} placeholder={t("Rosé signature")} /></Field>
        <Field label={t("Détail")} error={fieldError(err, "detail")}><input className="input" maxLength={190} value={form.detail} onChange={set("detail")} placeholder={t("Papier rosé · Ruban magenta")} /></Field>
        <div className="grid-2">
          <Field label={t("Supplément (FCFA, 0 = offert)")} error={fieldError(err, "price")}><input className="input" type="number" min={0} value={form.price} onChange={set("price")} /></Field>
          <Field label={t("Ordre d'affichage")} error={fieldError(err, "position")}><input className="input" type="number" min={0} value={form.position} onChange={set("position")} placeholder={t("Automatique")} /></Field>
        </div>
        <label className="check">
          <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
          <span className="box"><Icon name="check" size={14} /></span>{t("En ligne (proposé aux clients)")}
        </label>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button>
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
      <div className="admin-head"><h1 className="h1">{t("Commandes")}</h1></div>
      <div className="chips" style={{ marginBottom: 20 }}>
        {[["", "Toutes"], ...Object.entries(ORDER_STATUS)].map(([k, l]) => <button key={k} className={`chip ${status === k ? "on" : ""}`} onClick={() => setStatus(k)}>{t(l)}</button>)}
      </div>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>{t("Réf.")}</th><th>{t("Date")}</th><th>{t("Cadeau")}</th><th>{t("Client")}</th><th>{t("Livraison")}</th><th>{t("Paiement")}</th><th>{t("Total")}</th><th>{t("Statut")}</th></tr></thead>
            <tbody>
              {data?.map(o => (
                <tr key={o.id}>
                  <td className="cell-main"><b>{o.reference}</b></td>
                  <td data-label={t("Date")}>{date(o.created_at)}</td>
                  <td data-label={t("Cadeau")} className="cell-wide">{o.gift_name} × {o.quantity}{o.wrapping && <><br /><span className="note">{t("Emballage : {name}", { name: o.wrapping.name })}</span></>}{o.message && <><br /><span className="note">« {o.message} »</span></>}</td>
                  <td data-label={t("Client")}>{o.customer_name}<br /><a className="note" href={`tel:${o.customer_phone}`}>{o.customer_phone}</a></td>
                  <td data-label={t("Livraison")}>{[o.delivery_city, o.delivery_address].filter(Boolean).join(", ") || "—"}</td>
                  <td data-label={t("Paiement")}>{o.payment_method === "mtn_momo" ? "MTN MoMo" : "Orange Money"}</td>
                  <td data-label={t("Total")} className="price">{formatPrice(o.total, o.currency)}</td>
                  <td data-label={t("Statut")}><select className="input input-sm" value={o.status} onChange={e => update(o, e.target.value)}>{Object.entries(ORDER_STATUS).map(([k, l]) => <option key={k} value={k}>{t(l)}</option>)}</select></td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={8} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucune commande.")}</td></tr>}
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
      <div className="admin-head"><h1 className="h1">{t("Demandes personnalisées")}</h1></div>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>{t("Date")}</th><th>{t("Client")}</th><th>{t("Budget")}</th><th>{t("Description")}</th><th>{t("Emballage")}</th><th>{t("Statut")}</th></tr></thead>
            <tbody>
              {data?.map(r => (
                <tr key={r.id}>
                  <td className="cell-main">{date(r.created_at)}</td>
                  <td data-label={t("Client")}>{r.name}<br /><a className="note" href={`tel:${r.phone}`}>{r.phone}</a></td>
                  <td data-label={t("Budget")} className="price">{formatPrice(r.budget)}</td>
                  <td data-label={t("Description")} className="cell-wide" style={{ maxWidth: 380 }}>{r.description}</td>
                  <td data-label={t("Emballage")}>{r.wrapping?.name ?? t("Sans")}</td>
                  <td data-label={t("Statut")}><select className="input input-sm" value={r.status} onChange={e => update(r, e.target.value)}>{Object.entries(REQUEST_STATUS).map(([k, l]) => <option key={k} value={k}>{t(l)}</option>)}</select></td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucune demande.")}</td></tr>}
            </tbody>
          </table>
        </div>
      )}
    </>
  );
}

function Inspirations() {
  const { notify } = useStore();
  const { data, error, loading, reload } = useApi<AdminArticle[]>("/admin/inspirations");
  const [editing, setEditing] = useState<AdminArticle | "new" | null>(null);

  const toggle = async (a: AdminArticle) => {
    await api(`/admin/inspirations/${a.id}`, { method: "PUT", body: { is_active: !a.is_active } });
    reload();
  };
  const remove = async (a: AdminArticle) => {
    if (!window.confirm(t("Supprimer l'article « {title} » ?", { title: a.title }))) return;
    await api(`/admin/inspirations/${a.id}`, { method: "DELETE" });
    notify(t("Article supprimé."));
    reload();
  };

  return (
    <>
      <div className="admin-head">
        <h1 className="h1">{t("Inspirations")}</h1>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>{t("Nouvel article")} <Icon name="plus" size={18} /></button>
      </div>
      <p className="muted small" style={{ marginBottom: 20 }}>{t("Articles de la page Inspirations et de l'accueil, du plus récent au plus ancien. Le plus récent est mis à la une. Un article hors ligne n'est plus visible.")}</p>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th></th><th>{t("Article")}</th><th>{t("Thème")}</th><th>{t("Publié le")}</th><th>{t("En ligne")}</th><th></th></tr></thead>
            <tbody>
              {data?.map(a => (
                <tr key={a.id}>
                  <td className="cell-thumb">{a.image_url && <img src={a.image_url} alt="" className="table-thumb" />}</td>
                  <td className="cell-main"><b>{a.title}</b>{a.excerpt && <><br /><span className="note">{a.excerpt.length > 120 ? `${a.excerpt.slice(0, 120)}…` : a.excerpt}</span></>}</td>
                  <td data-label={t("Thème")}>{a.tag}</td>
                  <td data-label={t("Publié le")}>{date(a.created_at)}</td>
                  <td data-label={t("En ligne")}><button className={`switch ${a.is_active ? "on" : ""}`} onClick={() => toggle(a)} aria-label={t("En ligne")} aria-pressed={a.is_active} /></td>
                  <td className="actions">
                    {a.is_active && <Link className="link-plain" to={`/inspirations/${a.slug}`} target="_blank">{t("Voir")}</Link>}
                    <button className="link" onClick={() => setEditing(a)}>{t("Modifier")}</button>
                    <button className="link-plain" onClick={() => remove(a)}>{t("Supprimer")}</button>
                  </td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={6} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucun article. Créez le premier !")}</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <InspirationForm article={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(t("Article enregistré.")); }} />}
    </>
  );
}

function InspirationForm({ article, onClose, onSaved }: { article: AdminArticle | null; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    title: article?.title ?? "", tag: article?.tag ?? "", excerpt: article?.excerpt ?? "", body: article?.body ?? "",
    title_en: article?.title_en ?? "", tag_en: article?.tag_en ?? "", excerpt_en: article?.excerpt_en ?? "", body_en: article?.body_en ?? "",
    minutes: article?.minutes != null ? String(article.minutes) : "", is_active: article?.is_active ?? true,
  });
  const [image, setImage] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(article?.image_url ?? null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, typeof v === "boolean" ? (v ? "1" : "0") : v));
    if (image) fd.append("image", image);
    setBusy(true);
    setErr(null);
    try {
      await api(article ? `/admin/inspirations/${article.id}` : "/admin/inspirations", { body: fd });
      onSaved();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={article ? t("Modifier l'article") : t("Nouvel article")} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <div className="image-picker">
          {preview ? <img src={preview} alt="" /> : <div className="photo-empty"><Icon name="image" size={30} /></div>}
          <Field label={t("Photo (JPG, PNG, WEBP · 5 Mo max.)")} error={fieldError(err, "image")}>
            <input className="input" type="file" accept="image/png,image/jpeg,image/webp" onChange={e => {
              const f = e.target.files?.[0] ?? null;
              setImage(f);
              if (f) setPreview(URL.createObjectURL(f));
            }} />
          </Field>
        </div>
        <Field label={t("Titre *")} error={fieldError(err, "title")}><input className="input" required maxLength={255} value={form.title} onChange={set("title")} placeholder={t("Pour papa, une attention qui compte.")} /></Field>
        <div className="grid-2">
          <Field label={t("Thème *")} error={fieldError(err, "tag")}><input className="input" required maxLength={80} value={form.tag} onChange={set("tag")} placeholder={t("Fête des pères")} /></Field>
          <Field label={t("Temps de lecture (min)")} error={fieldError(err, "minutes")}><input className="input" type="number" min={1} max={120} value={form.minutes} onChange={set("minutes")} placeholder={t("Automatique")} /></Field>
        </div>
        <Field label={t("Résumé")} error={fieldError(err, "excerpt")}><textarea className="input" maxLength={500} rows={2} value={form.excerpt} onChange={set("excerpt")} /></Field>
        <Field label={t("Texte de l'article *")} error={fieldError(err, "body")}>
          <textarea className="input" required maxLength={20000} rows={8} value={form.body} onChange={set("body")} />
          <p className="note">{t("Laissez une ligne vide entre deux paragraphes.")}</p>
        </Field>
        <details>
          <summary className="link-plain" style={{ cursor: "pointer" }}>{t("Version anglaise (facultative)")}</summary>
          <div className="form" style={{ marginTop: 14 }}>
            <Field label={t("Titre en anglais")} error={fieldError(err, "title_en")}><input className="input" maxLength={255} value={form.title_en} onChange={set("title_en")} /></Field>
            <Field label={t("Thème en anglais")} error={fieldError(err, "tag_en")}><input className="input" maxLength={80} value={form.tag_en} onChange={set("tag_en")} /></Field>
            <Field label={t("Résumé en anglais")} error={fieldError(err, "excerpt_en")}><textarea className="input" maxLength={500} rows={2} value={form.excerpt_en} onChange={set("excerpt_en")} /></Field>
            <Field label={t("Texte en anglais")} error={fieldError(err, "body_en")}><textarea className="input" maxLength={20000} rows={6} value={form.body_en} onChange={set("body_en")} /></Field>
          </div>
        </details>
        <label className="check">
          <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
          <span className="box"><Icon name="check" size={14} /></span>{t("En ligne (visible sur le site)")}
        </label>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button>
      </form>
    </Modal>
  );
}

function Faqs() {
  const { notify } = useStore();
  const { data, error, loading, reload } = useApi<AdminFaq[]>("/admin/faqs");
  const [editing, setEditing] = useState<AdminFaq | "new" | null>(null);

  const toggle = async (f: AdminFaq) => {
    await api(`/admin/faqs/${f.id}`, { method: "PUT", body: { is_active: !f.is_active } });
    reload();
  };
  const remove = async (f: AdminFaq) => {
    if (!window.confirm(t("Supprimer la question « {q} » ?", { q: f.question }))) return;
    await api(`/admin/faqs/${f.id}`, { method: "DELETE" });
    notify(t("Question supprimée."));
    reload();
  };

  return (
    <>
      <h1 className="h1" style={{ marginBottom: 20 }}>{t("FAQ & contact")}</h1>
      <WhatsAppSetting />
      <div className="admin-head" style={{ marginTop: 34 }}>
        <h2 className="h2">{t("Questions fréquentes")}</h2>
        <button className="btn btn-primary" onClick={() => setEditing("new")}>{t("Nouvelle question")} <Icon name="plus" size={18} /></button>
      </div>
      <p className="muted small" style={{ marginBottom: 20 }}>{t("Affichées sur la page FAQ du site. Une question hors ligne n'est plus visible.")}</p>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <div className="table-wrap">
          <table className="table">
            <thead><tr><th>{t("Question")}</th><th>{t("Ordre")}</th><th>{t("En ligne")}</th><th></th></tr></thead>
            <tbody>
              {data?.map(f => (
                <tr key={f.id}>
                  <td className="cell-main"><b>{f.question}</b><br /><span className="note">{f.answer.length > 120 ? `${f.answer.slice(0, 120)}…` : f.answer}</span></td>
                  <td data-label={t("Ordre")}>{f.position}</td>
                  <td data-label={t("En ligne")}><button className={`switch ${f.is_active ? "on" : ""}`} onClick={() => toggle(f)} aria-label={t("En ligne")} aria-pressed={f.is_active} /></td>
                  <td className="actions">
                    <button className="link" onClick={() => setEditing(f)}>{t("Modifier")}</button>
                    <button className="link-plain" onClick={() => remove(f)}>{t("Supprimer")}</button>
                  </td>
                </tr>
              ))}
              {data?.length === 0 && <tr><td colSpan={4} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucune question. Créez la première !")}</td></tr>}
            </tbody>
          </table>
        </div>
      )}
      {editing && <FaqForm faq={editing === "new" ? null : editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(t("Question enregistrée.")); }} />}
    </>
  );
}

function WhatsAppSetting() {
  const { notify } = useStore();
  const { data } = useApi<{ whatsapp_number: string | null }>("/admin/settings");
  const [number, setNumber] = useState<string | null>(null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const value = number ?? data?.whatsapp_number ?? "";

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      await api("/admin/settings", { method: "PUT", body: { whatsapp_number: value.trim() || null } });
      notify(t("Numéro WhatsApp enregistré."));
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <form className="panel" onSubmit={submit}>
      <h2 className="h2">{t("Contact WhatsApp")}</h2>
      <p className="muted small" style={{ margin: "8px 0 16px" }}>{t("Le formulaire « Nous contacter » ouvre WhatsApp vers ce numéro, avec le message du client pré-rempli.")}</p>
      <div className="form">
        <Field label={t("Numéro WhatsApp (avec l'indicatif)")} error={fieldError(err, "whatsapp_number")}>
          <input className="input" type="tel" value={value} onChange={e => setNumber(e.target.value)} placeholder="+225 07 00 00 00 00" />
        </Field>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <div><button className="btn btn-primary" disabled={busy || !data}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button></div>
      </div>
    </form>
  );
}

function FaqForm({ faq, onClose, onSaved }: { faq: AdminFaq | null; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    question: faq?.question ?? "", answer: faq?.answer ?? "", question_en: faq?.question_en ?? "", answer_en: faq?.answer_en ?? "",
    position: faq ? String(faq.position) : "", is_active: faq?.is_active ?? true,
  });
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      const body = { ...form, question_en: form.question_en || null, answer_en: form.answer_en || null, position: form.position === "" ? null : Number(form.position) };
      await api(faq ? `/admin/faqs/${faq.id}` : "/admin/faqs", { method: faq ? "PUT" : "POST", body });
      onSaved();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={faq ? t("Modifier la question") : t("Nouvelle question")} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <Field label={t("Question *")} error={fieldError(err, "question")}><input className="input" required maxLength={255} value={form.question} onChange={set("question")} placeholder={t("Comment payer ma commande ?")} /></Field>
        <Field label={t("Réponse *")} error={fieldError(err, "answer")}><textarea className="input" required maxLength={5000} rows={5} value={form.answer} onChange={set("answer")} /></Field>
        <Field label={t("Question en anglais (facultatif)")} error={fieldError(err, "question_en")}><input className="input" maxLength={255} value={form.question_en} onChange={set("question_en")} /></Field>
        <Field label={t("Réponse en anglais (facultatif)")} error={fieldError(err, "answer_en")}><textarea className="input" maxLength={5000} rows={4} value={form.answer_en} onChange={set("answer_en")} /></Field>
        <Field label={t("Ordre d'affichage")} error={fieldError(err, "position")}><input className="input" type="number" min={0} value={form.position} onChange={set("position")} placeholder={t("Automatique")} /></Field>
        <label className="check">
          <input type="checkbox" checked={form.is_active} onChange={e => setForm({ ...form, is_active: e.target.checked })} />
          <span className="box"><Icon name="check" size={14} /></span>{t("En ligne (visible sur la page FAQ)")}
        </label>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button>
      </form>
    </Modal>
  );
}

type AdminUser = Pick<User, "id" | "name" | "email" | "phone" | "role" | "shop_name" | "language"> & { created_at: string; lists_count: number; orders_count: number; gifts_count: number };

function Users() {
  const { notify } = useStore();
  const [editing, setEditing] = useState<AdminUser | null>(null);
  const [q, setQ] = useState("");
  const [role, setRole] = useState("");
  const params = new URLSearchParams(Object.entries({ q: q.trim(), role }).filter(([, v]) => v)).toString();
  const { data, error, loading, reload } = useApi<AdminUser[]>(`/admin/users${params ? `?${params}` : ""}`);

  return (
    <>
      <div className="admin-head"><h1 className="h1">{t("Utilisateurs")}</h1></div>
      <input className="input admin-search" placeholder={t("Rechercher un nom, un email, un téléphone…")} value={q} onChange={e => setQ(e.target.value)} />
      <div className="chips" style={{ margin: "16px 0 20px" }}>
        {[["", "Tous"], ...Object.entries(ROLES)].map(([k, l]) => <button key={k} className={`chip ${role === k ? "on" : ""}`} onClick={() => setRole(k)}>{t(l)}</button>)}
      </div>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : (
        <>
          {data && <p className="note" style={{ marginBottom: 12 }}>{t("{n} compte(s)", { n: data.length })}</p>}
          <div className="table-wrap">
            <table className="table">
              <thead><tr><th>{t("Nom")}</th><th>{t("Téléphone")}</th><th>{t("Rôle")}</th><th>{t("Listes")}</th><th>{t("Commandes")}</th><th>{t("Inscription")}</th><th></th></tr></thead>
              <tbody>
                {data?.map(u => (
                  <tr key={u.id}>
                    <td className="cell-main"><div><b>{u.name}</b>{u.shop_name && <> · {u.shop_name}</>}<br /><a className="note" href={`mailto:${u.email}`}>{u.email}</a></div></td>
                    <td data-label={t("Téléphone")}>{u.phone ? <a href={`tel:${u.phone}`}>{u.phone}</a> : "—"}</td>
                    <td data-label={t("Rôle")}><div><span className={`badge ${u.role === "user" ? "ok" : "off"}`}>{t(ROLES[u.role])}</span>{u.role === "partner" && <><br /><span className="note">{t("{n} produit(s)", { n: u.gifts_count })}</span></>}</div></td>
                    <td data-label={t("Listes")}>{u.lists_count}</td>
                    <td data-label={t("Commandes")}>{u.orders_count}</td>
                    <td data-label={t("Inscription")}>{date(u.created_at)}</td>
                    <td className="actions"><button className="link" onClick={() => setEditing(u)}>{t("Modifier")}</button></td>
                  </tr>
                ))}
                {data?.length === 0 && <tr><td colSpan={7} className="muted" style={{ textAlign: "center", padding: 30 }}>{t("Aucun utilisateur trouvé.")}</td></tr>}
              </tbody>
            </table>
          </div>
        </>
      )}
      {editing && <UserForm user={editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); reload(); notify(t("Compte mis à jour.")); }} />}
    </>
  );
}

function UserForm({ user, onClose, onSaved }: { user: AdminUser; onClose: () => void; onSaved: () => void }) {
  const { user: me } = useStore();
  const [form, setForm] = useState({ name: user.name, email: user.email, phone: user.phone ?? "", role: user.role as string, shop_name: user.shop_name ?? "", password: "", password_confirmation: "" });
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });
  const isMe = me?.id === user.id;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      await api(`/admin/users/${user.id}`, { method: "PUT", body: { ...form, phone: form.phone || null, shop_name: form.shop_name || null } });
      onSaved();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={t("Modifier le compte")} onClose={onClose}>
      <form className="form" onSubmit={submit}>
        <Field label={t("Nom *")} error={fieldError(err, "name")}><input className="input" required maxLength={120} value={form.name} onChange={set("name")} /></Field>
        <div className="grid-2">
          <Field label={t("Email *")} error={fieldError(err, "email")}><input className="input" type="email" required value={form.email} onChange={set("email")} /></Field>
          <Field label={t("Téléphone")} error={fieldError(err, "phone")}><input className="input" type="tel" value={form.phone} onChange={set("phone")} /></Field>
        </div>
        <div className="grid-2">
          <Field label={t("Rôle")} error={fieldError(err, "role")}>
            <select className="input" value={form.role} onChange={set("role")} disabled={isMe}>
              {Object.entries(ROLES).map(([k, l]) => <option key={k} value={k}>{t(l)}</option>)}
            </select>
          </Field>
          {form.role === "partner" && (
            <Field label={t("Nom de la boutique *")} error={fieldError(err, "shop_name")}><input className="input" required maxLength={120} value={form.shop_name} onChange={set("shop_name")} /></Field>
          )}
        </div>
        {isMe && <p className="note">{t("Vous ne pouvez pas modifier votre propre rôle.")}</p>}
        <div className="grid-2">
          <Field label={t("Nouveau mot de passe")} error={fieldError(err, "password")}>
            <input className="input" type="password" minLength={8} autoComplete="new-password" value={form.password} onChange={set("password")} />
          </Field>
          <Field label={t("Confirmer le mot de passe")} error={fieldError(err, "password_confirmation")}>
            <input className="input" type="password" minLength={8} required={!!form.password} autoComplete="new-password" value={form.password_confirmation} onChange={set("password_confirmation")} />
          </Field>
        </div>
        <p className="note">{t("Laissez vide pour garder le mot de passe actuel. Un nouveau mot de passe déconnecte le compte de ses appareils.")}</p>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Enregistrement…") : t("Enregistrer")}</button>
      </form>
    </Modal>
  );
}
