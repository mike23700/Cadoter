import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, ApiError } from "../api";
import { Breadcrumb, ErrorBox, Field, fieldError } from "../components";
import { Icon } from "../icons";
import { useStore } from "../store";
import { WrapPicker } from "./Order";

/** Cadeau personnalisé : formulaire uniquement, l'équipe recontacte (pas de commande directe). */
export default function Custom() {
  const { user, meta } = useStore();
  const [form, setForm] = useState({ name: "", phone: "", budget: "", description: "" });
  const [wrap, setWrap] = useState<number | "">("");
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [sent, setSent] = useState<string | null>(null);

  useEffect(() => { if (user) setForm(f => ({ ...f, name: f.name || user.name, phone: f.phone || user.phone || "" })); }, [user]);
  useEffect(() => { if (meta?.wrappings[0] && wrap === "") setWrap(meta.wrappings[0].id); }, [meta]); // eslint-disable-line react-hooks/exhaustive-deps

  const hero = meta?.wrappings.find(w => w.id === wrap)?.image_url ?? "/img/emballage-rose.jpg";
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      const budget = Number(form.budget.replace(/\D/g, ""));
      const res = await api<{ message: string }>("/custom-requests", { body: { ...form, budget, wrapping_id: wrap || null } });
      setSent(res.message);
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="wrap">
      <Breadcrumb items={[["Accueil", "/"], ["Cadeaux", "/cadeaux"], ["Cadeau personnalisé"]]} />
      <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>Vous l'imaginez. On vous accompagne.</h1>
      <p className="lead page-lead">Une envie particulière ? Décrivez votre attention, puis choisissez son écrin.</p>

      <div className="two-col custom" id="emballages">
        {sent ? (
          <div className="panel success">
            <span className="success-icon"><Icon name="check" size={30} /></span>
            <h2 className="h1" style={{ fontSize: 32 }}>Demande envoyée.</h2>
            <p className="muted">{sent}</p>
            <Link to="/cadeaux" className="btn btn-primary">Voir les cadeaux</Link>
          </div>
        ) : (
          <form className="panel" onSubmit={submit}>
            <h2 className="h2" style={{ fontSize: 28, marginBottom: 26 }}>Le cadeau que vous avez en tête</h2>
            <div className="form">
              <div className="grid-2">
                <Field label="Nom *" error={fieldError(err, "name")}><input className="input" required value={form.name} onChange={set("name")} placeholder="Aïcha Koné" /></Field>
                <Field label="Téléphone *" error={fieldError(err, "phone")}><input className="input" type="tel" required value={form.phone} onChange={set("phone")} placeholder="+225 07 00 00 00 00" /></Field>
              </div>
              <Field label="Budget *" error={fieldError(err, "budget")}><input className="input" required inputMode="numeric" value={form.budget} onChange={set("budget")} placeholder="30 000 FCFA" /></Field>
              <Field label="Description du cadeau *" error={fieldError(err, "description")}>
                <textarea className="input" required value={form.description} onChange={set("description")} placeholder="Un coffret de thé pour ma mère, avec une tasse en céramique et un petit mot manuscrit. Elle aime les couleurs douces." />
              </Field>
              <p className="note">* Champs obligatoires. Vos coordonnées servent uniquement au suivi de votre demande.</p>
              <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
              <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Envoi…" : "Envoyer ma demande"}</button>
              <p className="note">Nous vous recontacterons pour préciser les possibilités. Cette demande n'est pas une commande.</p>
            </div>
          </form>
        )}

        <div>
          <h2 className="h2" style={{ fontSize: 30 }}>Et pour la touche finale…</h2>
          <p className="muted" style={{ fontSize: 14, marginTop: 14 }}>Des modèles d'exemple à choisir selon l'occasion. Le soin du détail, sans en faire trop.</p>
          <img className="photo wrap-hero" src={hero} alt="Emballage sélectionné" />
          <WrapPicker value={wrap} onChange={setWrap} />
        </div>
      </div>
    </div>
  );
}
