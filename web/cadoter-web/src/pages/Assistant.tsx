import { FormEvent, useState } from "react";
import { Link } from "react-router-dom";
import { api, formatPrice, Gift } from "../api";
import { Badge, ErrorBox, Field, fieldError, IllustrativeNote, Photo } from "../components";
import { Icon } from "../icons";
import { useStore } from "../store";

type Suggestion = { gift: Gift; reason: string };
type Result = { suggestions: Suggestion[]; disclaimer: string };

const events = ["Anniversaire", "Mariage", "Naissance", "Dot", "Fête des mères", "Fête des pères", "Noël", "Remerciement", "Décès · Soutenir un proche"];
const genders = ["Femme", "Homme", "Non précisé"];
const relations = ["Amie", "Ami", "Mère", "Père", "Conjointe", "Conjoint", "Sœur", "Frère", "Enfant", "Collègue", "Famille"];
const budgets = [10000, 20000, 30000, 40000, 50000, 75000, 100000, 200000];

export default function Assistant() {
  const { meta } = useStore();
  const [form, setForm] = useState({ event: "Anniversaire", gender: "Femme", age: "30", relation: "Amie", budget: "40000", city: "", info: "" });
  const [result, setResult] = useState<Result | null>(null);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      setResult(await api<Result>("/assistant/suggest", { body: { ...form, age: Number(form.age), budget: Number(form.budget), city: form.city || null } }));
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="wrap">
      <p className="eyebrow" style={{ margin: "40px 0 22px" }}>Votre assistante cadeaux</p>
      <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>Une personne unique. Des idées à son image.</h1>
      <p className="lead page-lead">Dites-nous ce qui la rend spéciale. On vous aide à trouver le bon point de départ.</p>

      <div className="two-col">
        <form className="panel" onSubmit={submit}>
          <div className="panel-title"><Icon name="sparkle" size={24} /><h2 className="h2">Parlons de votre proche.</h2></div>
          <div className="form">
            <div className="grid-2">
              <Field label="Type d'événement *"><select className="input" value={form.event} onChange={set("event")}>{events.map(x => <option key={x}>{x}</option>)}</select></Field>
              <Field label="Sexe de la personne *"><select className="input" value={form.gender} onChange={set("gender")}>{genders.map(x => <option key={x}>{x}</option>)}</select></Field>
            </div>
            <div className="grid-2">
              <Field label="Âge *" error={fieldError(err, "age")}><input className="input" type="number" min={0} max={120} required value={form.age} onChange={set("age")} /></Field>
              <Field label="Lien avec la personne *"><select className="input" value={form.relation} onChange={set("relation")}>{relations.map(x => <option key={x}>{x}</option>)}</select></Field>
            </div>
            <div className="grid-2">
              <Field label="Budget alloué *"><select className="input" value={form.budget} onChange={set("budget")}>{budgets.map(b => <option key={b} value={b}>{formatPrice(b)} maximum</option>)}</select></Field>
              <Field label="Ville"><select className="input" value={form.city} onChange={set("city")}><option value="">Toutes les villes</option>{(meta?.cities ?? []).map(c => <option key={c}>{c}</option>)}</select></Field>
            </div>
            <Field label="Autres informations">
              <textarea className="input" maxLength={500} value={form.info} onChange={set("info")} placeholder="Elle aime le thé, la décoration et les moments calmes." />
            </Field>
            <p className="note">* Champs requis. Évitez de partager des informations sensibles.</p>
            <ErrorBox error={err instanceof Error ? err : null} />
            <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Recherche…" : "Trouver mes idées"} <Icon name="sparkle" size={18} /></button>
          </div>
        </form>

        <div>
          <h2 className="h2" style={{ fontSize: 30, marginBottom: 20 }}>{result ? "Une attention qui lui ressemble." : "Ce que l'on pourrait vous proposer"}</h2>
          {result && (
            <div className="chips" style={{ marginBottom: 16 }}>
              <span className="chip">{form.event}</span><span className="chip">{form.relation} · {form.age} ans</span><span className="chip">≤ {formatPrice(Number(form.budget))}</span>
            </div>
          )}
          <IllustrativeNote />
          <p className="small muted" style={{ margin: "14px 0 24px" }}>{result?.disclaimer ?? "Remplissez le formulaire : nos suggestions s'appuient sur le catalogue CADOTER. Prix et disponibilité à confirmer auprès du marchand."}</p>
          {result?.suggestions.length === 0 && (
            <div className="empty">Aucune idée dans ce budget pour l'instant. <Link className="link" to="/personnalise">Demander un cadeau personnalisé →</Link></div>
          )}
          {result?.suggestions.map(({ gift, reason }) => (
            <article key={gift.id} className="suggestion">
              <Photo src={gift.image_url} alt={gift.name} />
              <div className="body">
                <Badge>Disponible · {gift.city}</Badge>
                <h3>{gift.name}</h3>
                <p className="price">{formatPrice(gift.price, gift.currency)}</p>
                <p className="why"><b>Pourquoi ce cadeau ?</b> {reason}</p>
                <Link to={`/cadeaux/${gift.slug}`} className="link">Voir ce cadeau →</Link>
              </div>
            </article>
          ))}
          {result && result.suggestions.length > 0 && (
            <button className="btn btn-outline btn-block" onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>Affiner mes critères</button>
          )}
        </div>
      </div>
    </div>
  );
}
