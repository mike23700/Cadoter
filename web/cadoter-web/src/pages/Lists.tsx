import { FormEvent, useEffect, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api, ApiError, formatDate, formatPrice, GiftList, ItemStatus, ListItem } from "../api";
import { Badge, Breadcrumb, ErrorBox, Field, fieldError, IllustrativeNote, Loading, Modal, Photo } from "../components";
import { Icon } from "../icons";
import { t, tn } from "../i18n";
import { useApi, useStore } from "../store";

const shareUrl = (code: string) => `${window.location.origin}/l/${code}`;

export default function Lists() {
  const { user, meta, notify } = useStore();
  const [params, setParams] = useSearchParams();
  const { data: lists, setData: setLists, error, loading, reload } = useApi<GiftList[]>("/lists");
  const selectedId = Number(params.get("id")) || lists?.[0]?.id;
  const list = lists?.find(l => l.id === selectedId) ?? lists?.[0];

  const replace = (l: GiftList) => setLists(ls => (ls ?? []).map(x => (x.id === l.id ? l : x)));
  const refresh = async (id: number) => replace(await api<GiftList>(`/lists/${id}`));

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Mon espace"), "/listes"], [t("Mes listes")]]} />
      <h1 className="display page-title" style={{ fontSize: 52 }}>{t("Vos envies, réunies et partagées.")}</h1>
      <ErrorBox error={error} onRetry={reload} />
      {loading ? <Loading /> : (
        <div className="lists-layout">
          <aside className="lists-side">
            {lists?.map(l => (
              <button key={l.id} className={`list-tab ${l.id === list?.id ? "on" : ""}`} onClick={() => setParams({ id: String(l.id) })}>
                <span className="eyebrow">{t("Mes listes")}</span>
                <h3>{l.title}</h3>
                <p>{tn(l.counts.total, "{n} cadeau", "{n} cadeaux")} · {tn(l.counts.reserved, "{n} réservé", "{n} réservés")}</p>
              </button>
            ))}
            <CreateList occasions={meta?.occasions ?? []} onCreated={l => { setLists(ls => [l, ...(ls ?? [])]); setParams({ id: String(l.id) }); notify(t("Votre liste est prête. Ajoutez vos envies !")); }} />
          </aside>

          {list ? <ListDetail key={list.id} list={list} onChange={replace} refresh={() => refresh(list.id)}
            onDeleted={() => { setLists(ls => (ls ?? []).filter(x => x.id !== list.id)); setParams({}); }} />
            : (
              <div className="panel rose share-box">
                <h2>{t("Bonjour {name}, créez votre première liste.", { name: user?.name.split(" ")[0] ?? "" })}</h2>
                <p>{t("Rassemblez vos envies de tous vos sites favoris, sans limite. Vos proches réservent pour éviter les doublons.")}</p>
                <Link to="/cadeaux" className="link">{t("Explorer les cadeaux →")}</Link>
              </div>
            )}
        </div>
      )}
    </div>
  );
}

function CreateList({ occasions, onCreated }: { occasions: string[]; onCreated: (l: GiftList) => void }) {
  const [form, setForm] = useState({ title: "", description: "", occasion: "" });
  const [image, setImage] = useState<File | null>(null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (image && image.size > 5 * 1024 * 1024) return setErr(new ApiError(t("L'image ne doit pas dépasser 5 Mo."), 422, { image: [t("L'image ne doit pas dépasser 5 Mo.")] }));
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, v));
    if (image) fd.append("image", image);
    setBusy(true);
    setErr(null);
    try {
      onCreated(await api<GiftList>("/lists", { body: fd }));
      setForm({ title: "", description: "", occasion: "" });
      setImage(null);
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <form className="panel form" onSubmit={submit} style={{ padding: 22 }}>
      <h2 className="h2" style={{ fontSize: 26 }}>{t("Une nouvelle envie ?")}</h2>
      <Field label={t("Titre *")} error={fieldError(err, "title")}><input className="input" required maxLength={120} placeholder={t("Le nom de votre liste")} value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} /></Field>
      <Field label={t("Description")}><textarea className="input" placeholder={t("Un petit mot pour vos proches…")} value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} /></Field>
      <Field label={t("Occasion *")} error={fieldError(err, "occasion")}>
        <select className="input" required value={form.occasion} onChange={e => setForm({ ...form, occasion: e.target.value })}>
          <option value="" disabled>{t("Choisir une occasion")}</option>
          {occasions.map(o => <option key={o} value={o}>{t(o)}</option>)}
        </select>
      </Field>
      {form.occasion.startsWith("Décès") && <p className="note">{t("Pour un deuil, une présentation sobre et un message de soutien seront privilégiés.")}</p>}
      <div className="field">
        <button type="button" className="btn btn-outline btn-block" onClick={() => fileRef.current?.click()}>
          {image ? image.name : t("Ajouter une image")} <Icon name="image" size={18} className="price" />
        </button>
        <input ref={fileRef} type="file" accept="image/png,image/jpeg" hidden onChange={e => setImage(e.target.files?.[0] ?? null)} />
        <em className={fieldError(err, "image") ? "field-error" : "note"}>{fieldError(err, "image") ?? t("JPG, PNG · 5 Mo maximum")}</em>
      </div>
      <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Création…") : t("Créer la liste")}</button>
    </form>
  );
}

function ListDetail({ list, onChange, refresh, onDeleted }: { list: GiftList; onChange: (l: GiftList) => void; refresh: () => Promise<void>; onDeleted: () => void }) {
  const { notify } = useStore();
  const [url, setUrl] = useState("");
  const [busy, setBusy] = useState(false);
  const [editing, setEditing] = useState(false);

  const addLink = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api(`/lists/${list.id}/items`, { body: { url: url.match(/^https?:\/\//) ? url : `https://${url}` } });
      setUrl("");
      await refresh();
      notify(t("Produit ajouté à votre liste."));
    } catch (e) {
      notify(e instanceof ApiError ? (e.field("url") ?? e.message) : t("Lien invalide."));
    } finally {
      setBusy(false);
    }
  };

  const setStatus = async (item: ListItem, status: ItemStatus) => {
    await api(`/lists/${list.id}/items/${item.id}`, { method: "PUT", body: { status } });
    await refresh();
  };
  const remove = async (item: ListItem) => {
    await api(`/lists/${list.id}/items/${item.id}`, { method: "DELETE" });
    await refresh();
    notify(t("Cadeau retiré de la liste."));
  };
  const copy = async () => {
    try { await navigator.clipboard.writeText(shareUrl(list.code)); notify(t("Lien copié !")); }
    catch { notify(shareUrl(list.code)); }
  };

  return (
    <section>
      <div className="list-head">
        <Photo src={list.image_url} alt="" />
        <div>
          <h2>{list.title}</h2>
          {list.description && <p>{list.description}</p>}
          <p className="meta muted">{formatDate(list.event_date ?? list.created_at)} · {t(list.occasion)}</p>
          <button className="link" onClick={() => setEditing(true)}>{t("Modifier le titre, la description ou l'image →")}</button>
        </div>
      </div>

      <form className="panel" onSubmit={addLink} style={{ marginBottom: 28 }}>
        <h3 style={{ fontFamily: "var(--sans)", fontWeight: 600, fontSize: 18, marginBottom: 16 }}>{t("Un coup de cœur sur un autre site ?")}</h3>
        <Field label={t("Lien du produit")}>
          <div className="link-form">
            <input className="input" required placeholder={t("https://boutique.exemple/produit")} value={url} onChange={e => setUrl(e.target.value)} />
            <button className="btn btn-primary" disabled={busy}>{busy ? t("Ajout…") : t("Ajouter ce lien")}</button>
          </div>
        </Field>
        <p className="note" style={{ marginTop: 12 }}>{t("Ajoutez des produits de tous vos sites favoris, sans limitation. Ou")} <Link to="/cadeaux" className="price">{t("choisissez dans le catalogue")}</Link>.</p>
      </form>

      <IllustrativeNote />
      <div className="section-head" style={{ margin: "22px 0 4px" }}>
        <b style={{ fontSize: 14 }}>{t("Mes cadeaux")}</b>
        <span className="small muted">{tn(list.counts.available, "{n} disponible", "{n} disponibles")} · {tn(list.counts.reserved, "{n} réservé", "{n} réservés")}</span>
      </div>
      {list.items.length === 0 && <div className="empty">{t("Votre liste est vide pour le moment.")}</div>}
      {list.items.map(item => (
        <div key={item.id} className="list-row">
          {item.image_url ? <img src={item.image_url} alt="" /> : <div className="photo-empty thumb"><Icon name="gift" /></div>}
          <div>
            <h4>{item.gift_slug ? <Link to={`/cadeaux/${item.gift_slug}`}>{item.name}</Link> : item.external_url ? <a href={item.external_url} target="_blank" rel="noreferrer noopener">{item.name}</a> : item.name}</h4>
            <p>{[item.city, item.area, formatPrice(item.price, item.currency)].filter(Boolean).join(" · ")}</p>
            {item.reserved_by_name && <p className="note">{t("Réservé par {name}", { name: item.reserved_by_name })}</p>}
          </div>
          <Badge status={item.status} />
          <MoreMenu items={[
            ...(item.status !== "Disponible" ? [[t("Remettre disponible"), () => setStatus(item, "Disponible")] as const] : []),
            ...(item.status !== "Réservé" ? [[t("Marquer réservé"), () => setStatus(item, "Réservé")] as const] : []),
            ...(item.status !== "Indisponible" ? [[t("Marquer indisponible"), () => setStatus(item, "Indisponible")] as const] : []),
            [t("Retirer de la liste"), () => remove(item)] as const,
          ]} />
        </div>
      ))}

      <div className="panel rose share-box" style={{ marginTop: 24 }}>
        <h2>{t("Vos proches n'ont plus qu'à choisir.")}</h2>
        <p>{t("Ils réservent pour éviter les doublons. Une réservation n'est pas un achat.")}</p>
        <Field label={t("Lien de partage")}>
          <div className="link-form">
            <input className="input" readOnly value={shareUrl(list.code).replace(/^https?:\/\//, "")} onFocus={e => e.target.select()} />
            <button type="button" className="btn btn-primary" onClick={copy}>{t("Copier le lien")} <Icon name="copy" size={18} /></button>
          </div>
        </Field>
        <p className="note" style={{ marginTop: 12 }}>
          <Icon name="lock" size={12} /> {list.is_locked ? <>{t("Protégée par le code")} <b>{list.access_code}</b>.</> : t("Lien public.")}{" "}
          <button className="price" onClick={() => setEditing(true)}>{list.is_locked ? t("Modifier le code") : t("Ajouter un code d'accès")}</button>
          {" · "}<Link className="price" to={`/l/${list.code}`}>{t("Voir comme un proche")}</Link>
        </p>
      </div>

      {editing && <EditList list={list} onClose={() => setEditing(false)} onSaved={l => { onChange(l); setEditing(false); notify(t("Liste mise à jour.")); }} onDeleted={onDeleted} />}
    </section>
  );
}

function MoreMenu({ items }: { items: readonly (readonly [string, () => void])[] }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => !ref.current?.contains(e.target as Node) && setOpen(false);
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, [open]);
  return (
    <div className="more" ref={ref}>
      <button className="icon-btn" aria-label={t("Plus d'actions")} aria-expanded={open} onClick={() => setOpen(o => !o)}><Icon name="more" /></button>
      {open && (
        <div className="more-menu" role="menu">
          {items.map(([label, fn]) => <button key={label} role="menuitem" onClick={() => { setOpen(false); fn(); }}>{label}</button>)}
        </div>
      )}
    </div>
  );
}

function EditList({ list, onClose, onSaved, onDeleted }: { list: GiftList; onClose: () => void; onSaved: (l: GiftList) => void; onDeleted: () => void }) {
  const { meta } = useStore();
  const [form, setForm] = useState({ title: list.title, description: list.description ?? "", occasion: list.occasion, access_code: list.access_code ?? "" });
  const [image, setImage] = useState<File | null>(null);
  const [err, setErr] = useState<unknown>(null);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    const fd = new FormData();
    Object.entries(form).forEach(([k, v]) => fd.append(k, v));
    if (image) fd.append("image", image);
    try { onSaved(await api<GiftList>(`/lists/${list.id}/update`, { body: fd })); } catch (e) { setErr(e); }
  };
  const del = async () => {
    if (!window.confirm(t("Supprimer la liste « {title} » ? Cette action est définitive.", { title: list.title }))) return;
    await api(`/lists/${list.id}`, { method: "DELETE" });
    onDeleted();
  };

  return (
    <Modal title={t("Modifier ma liste")} onClose={onClose}>
      <form className="form" onSubmit={save}>
        <Field label={t("Titre *")} error={fieldError(err, "title")}><input className="input" required value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} /></Field>
        <Field label={t("Description")}><textarea className="input" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} /></Field>
        <Field label={t("Occasion *")}>
          <select className="input" value={form.occasion} onChange={e => setForm({ ...form, occasion: e.target.value })}>
            {(meta?.occasions ?? [list.occasion]).map(o => <option key={o} value={o}>{t(o)}</option>)}
          </select>
        </Field>
        <Field label={t("Code d'accès (facultatif)")} error={fieldError(err, "access_code")}>
          <input className="input" maxLength={20} placeholder={t("Laisser vide pour un lien public")} value={form.access_code} onChange={e => setForm({ ...form, access_code: e.target.value })} />
        </Field>
        <Field label={t("Nouvelle image (JPG, PNG · 5 Mo max.)")} error={fieldError(err, "image")}>
          <input className="input" type="file" accept="image/png,image/jpeg" onChange={e => setImage(e.target.files?.[0] ?? null)} />
        </Field>
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <div className="btn-row">
          <button type="button" className="btn btn-outline" onClick={del}>{t("Supprimer la liste")}</button>
          <button className="btn btn-primary">{t("Enregistrer")}</button>
        </div>
      </form>
    </Modal>
  );
}
