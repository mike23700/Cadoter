import { FormEvent, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api, formatPrice, Gift, GiftList } from "../api";
import { Badge, ErrorBox, Field, fieldError, IllustrativeNote, Loading, Modal, Photo } from "../components";
import { Icon } from "../icons";
import { t } from "../i18n";
import { useApi, useStore } from "../store";

type Suggestion = { gift: Gift; reason: string; card?: string };
type Result = { suggestions: Suggestion[]; external_available?: boolean; disclaimer: string };
type ExternalIdea = { title: string; url: string; image: string | null; price: number | null; currency: string | null; site: string; reason: string; card?: string };
type External = { results: ExternalIdea[]; disclaimer: string };

/** En dessous de ce nombre de suggestions CADOTER, on cherche aussi des idées sur des sites marchands. */
const EXTERNAL_BELOW = 3;

const events = ["Anniversaire", "Mariage", "Naissance", "Dot", "Fête des mères", "Fête des pères", "Noël", "Remerciement", "Décès · Soutenir un proche"];
const genders = ["Femme", "Homme", "Non précisé"];
const relations = ["Amie", "Ami", "Mère", "Père", "Conjointe", "Conjoint", "Sœur", "Frère", "Enfant", "Collègue", "Famille"];

export default function Assistant() {
  const { meta } = useStore();
  const [form, setForm] = useState({ event: "Anniversaire", gender: "Femme", age: "", relation: "Amie", budget: "", city: "", info: "" });
  const [result, setResult] = useState<Result | null>(null);
  const [external, setExternal] = useState<External | "loading" | null>(null);
  const search = useRef(0); // ignore les réponses d'une recherche précédente
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    setExternal(null);
    const id = ++search.current;
    const body = { ...form, age: Number(form.age), budget: Number(form.budget), city: form.city || null };
    let res: Result;
    try {
      res = await api<Result>("/assistant/suggest", { body });
      setResult(res);
    } catch (e) {
      setErr(e);
      return;
    } finally {
      setBusy(false);
    }
    // Catalogue trop court : idées complémentaires sur les sites marchands (affichées à part, après coup)
    if (res.external_available && res.suggestions.length < EXTERNAL_BELOW) {
      setExternal("loading");
      const ext = await api<External>("/assistant/external", { body }).catch(() => null);
      if (id === search.current) setExternal(ext);
    }
  };

  return (
    <div className="wrap">
      <p className="eyebrow" style={{ margin: "40px 0 22px" }}>{t("Votre assistante cadeaux")}</p>
      <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>{t("Une personne unique. Des idées à son image.")}</h1>
      <p className="lead page-lead">{t("Dites-nous ce qui la rend spéciale. On vous aide à trouver le bon point de départ.")}</p>

      <div className="two-col">
        <form className="panel" onSubmit={submit}>
          <div className="panel-title"><Icon name="sparkle" size={24} /><h2 className="h2">{t("Parlons de votre proche.")}</h2></div>
          <div className="form">
            <div className="grid-2">
              <Field label={t("Type d'événement *")}><select className="input" value={form.event} onChange={set("event")}>{events.map(x => <option key={x} value={x}>{t(x)}</option>)}</select></Field>
              <Field label={t("Sexe de la personne *")}><select className="input" value={form.gender} onChange={set("gender")}>{genders.map(x => <option key={x} value={x}>{t(x)}</option>)}</select></Field>
            </div>
            <div className="grid-2">
              <Field label={t("Âge *")} error={fieldError(err, "age")}><input className="input" type="number" inputMode="numeric" min={0} max={120} required value={form.age} onChange={set("age")} placeholder={t("Ex. {n}", { n: 30 })} /></Field>
              <Field label={t("Lien avec la personne *")}><select className="input" value={form.relation} onChange={set("relation")}>{relations.map(x => <option key={x} value={x}>{t(x)}</option>)}</select></Field>
            </div>
            <div className="grid-2">
              <Field label={t("Budget alloué (FCFA) *")} error={fieldError(err, "budget")}>
                <input className="input" type="number" inputMode="numeric" min={1000} step={500} required value={form.budget} onChange={set("budget")} placeholder={t("Ex. {n}", { n: "40 000" })} />
              </Field>
              <Field label={t("Ville")}><select className="input" value={form.city} onChange={set("city")}><option value="">{t("Toutes les villes")}</option>{(meta?.cities ?? []).map(c => <option key={c}>{c}</option>)}</select></Field>
            </div>
            <Field label={t("Autres informations")}>
              <textarea className="input" maxLength={500} value={form.info} onChange={set("info")} placeholder={t("Elle aime le thé, la décoration et les moments calmes.")} />
            </Field>
            <p className="note">{t("* Champs requis. Évitez de partager des informations sensibles.")}</p>
            <ErrorBox error={err instanceof Error ? err : null} />
            <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Recherche…") : t("Trouver mes idées")} <Icon name="sparkle" size={18} /></button>
          </div>
        </form>

        <div>
          <h2 className="h2" style={{ fontSize: 30, marginBottom: 20 }}>{result ? t("Une attention qui lui ressemble.") : t("Ce que l'on pourrait vous proposer")}</h2>
          {result && (
            <div className="chips" style={{ marginBottom: 16 }}>
              <span className="chip">{t(form.event)}</span><span className="chip">{t(form.relation)} · {t("{age} ans", { age: form.age })}</span><span className="chip">≤ {formatPrice(Number(form.budget))}</span>
            </div>
          )}
          <IllustrativeNote />
          <p className="small muted" style={{ margin: "14px 0 24px" }}>{result?.disclaimer ?? t("Remplissez le formulaire : nos suggestions s'appuient sur le catalogue CADOTER. Prix et disponibilité à confirmer auprès du marchand.")}</p>
          {result?.suggestions.length === 0 && external !== "loading" && !(external && external.results.length) && (
            <div className="empty">
              {t("Nous n'avons pas trouvé de cadeau qui corresponde à votre demande. Notre équipe peut le chercher pour vous.")}{" "}
              <Link className="link" to={`/personnalise?${new URLSearchParams({ description: form.info || t(form.event), budget: form.budget })}`}>{t("Demander un cadeau personnalisé →")}</Link>
            </div>
          )}
          {result?.suggestions.map(({ gift, reason, card }) => (
            <article key={gift.id} className="suggestion">
              <Photo src={gift.image_url} alt={gift.name} />
              <div className="body">
                <Badge>{t("Disponible")} · {gift.city}</Badge>
                <h3>{gift.name}</h3>
                <p className="price">{formatPrice(gift.price, gift.currency)}</p>
                <p className="why"><b>{t("Pourquoi ce cadeau ?")}</b> {reason}</p>
                <CardText text={card} />
                <Link to={`/cadeaux/${gift.slug}`} className="link">{t("Voir ce cadeau →")}</Link>
              </div>
            </article>
          ))}
          {external === "loading" && (
            <div className="external-head"><Loading label={t("On cherche d'autres idées chez des boutiques en ligne…")} /></div>
          )}
          {external && external !== "loading" && external.results.length > 0 && (
            <ExternalIdeas ideas={external} budget={Number(form.budget)} />
          )}
          {result && result.suggestions.length > 0 && (
            <button className="btn btn-outline btn-block" onClick={() => window.scrollTo({ top: 0, behavior: "smooth" })}>{t("Affiner mes critères")}</button>
          )}
        </div>
      </div>
    </div>
  );
}

/** Texte de carte de vœux rédigé par l'IA pour ce cadeau, à copier. */
function CardText({ text }: { text?: string }) {
  const { notify } = useStore();
  if (!text) return null;
  const copy = async () => {
    try { await navigator.clipboard.writeText(text); notify(t("Texte copié !")); }
    catch { notify(t("Copie impossible : sélectionnez le texte pour le copier.")); }
  };

  return (
    <div className="card-text">
      <div className="card-text-head">
        <b>{t("Texte pour la carte")}</b>
        <button type="button" className="link" onClick={copy}><Icon name="copy" size={15} />{t("Copier")}</button>
      </div>
      <p>{text}</p>
    </div>
  );
}

/** Idées hors catalogue : vérifiées côté serveur, affichées à part du catalogue CADOTER. */
function ExternalIdeas({ ideas, budget }: { ideas: External; budget: number }) {
  const nav = useNavigate();
  const [adding, setAdding] = useState<ExternalIdea | null>(null);
  const [shown, setShown] = useState(3); // « Voir plus » en affiche 3 de plus

  // « Le commander via CADOTER » : demande de cadeau personnalisé pré-remplie
  const order = (idea: ExternalIdea) => {
    const description = t("Je souhaite offrir ce produit vu sur {site} : {title} — {url}", { site: idea.site, title: idea.title, url: idea.url });
    const params = new URLSearchParams({ description, budget: String(idea.price && idea.currency === "FCFA" ? idea.price : budget) });
    nav(`/personnalise?${params}`);
  };

  return (
    <section className="external-ideas">
      <div className="external-head">
        <h3 className="h2">{t("Idées trouvées ailleurs")}</h3>
        <p className="small muted">{ideas.disclaimer}</p>
      </div>
      {ideas.results.slice(0, shown).map(idea => (
        <article key={idea.url} className="suggestion">
          <Photo src={idea.image} alt={idea.title} />
          <div className="body">
            <Badge>{t("Sur {site}", { site: idea.site })}</Badge>
            <h3>{idea.title}</h3>
            <p className="price">{idea.price == null ? t("Prix sur le site") : idea.currency === "FCFA" ? formatPrice(idea.price) : `${idea.price} ${idea.currency ?? ""}`}</p>
            <p className="why"><b>{t("Pourquoi ce cadeau ?")}</b> {idea.reason}</p>
            <CardText text={idea.card} />
            <div className="external-actions">
              <a href={idea.url} target="_blank" rel="noopener noreferrer nofollow" className="link">{t("Voir sur {site} ↗", { site: idea.site })}</a>
              <button type="button" className="btn btn-outline" onClick={() => setAdding(idea)}><Icon name="list" size={16} />{t("Ajouter à ma liste")}</button>
              <button type="button" className="btn btn-primary" onClick={() => order(idea)}><Icon name="gift" size={16} />{t("Le commander via CADOTER")}</button>
            </div>
          </div>
        </article>
      ))}
      {shown < ideas.results.length && (
        <button type="button" className="link see-more" onClick={() => setShown(n => n + 3)}>
          {t("Voir plus ({n})", { n: ideas.results.length - shown })} ↓
        </button>
      )}
      {adding && <AddToList idea={adding} onClose={() => setAdding(null)} />}
    </section>
  );
}

function AddToList({ idea, onClose }: { idea: ExternalIdea; onClose: () => void }) {
  const { user, notify } = useStore();
  const nav = useNavigate();
  const { data: lists, loading } = useApi<GiftList[]>(user ? "/lists" : null, [user?.id]);
  const [listId, setListId] = useState("");
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const chosen = listId || String(lists?.[0]?.id ?? "");

  const add = async () => {
    setBusy(true);
    setErr(null);
    try {
      await api(`/lists/${chosen}/items`, { body: { url: idea.url, name: idea.title, price: idea.currency === "FCFA" ? idea.price : null } });
      notify(t("Ajouté à votre liste."));
      onClose();
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <Modal title={t("Ajouter à ma liste")} onClose={onClose}>
      {!user ? (
        <div className="form">
          <p className="muted">{t("Connectez-vous pour ajouter cette idée à l'une de vos listes.")}</p>
          <button className="btn btn-primary btn-block" onClick={() => nav("/connexion?next=%2Fassistante")}>{t("Se connecter")}</button>
        </div>
      ) : loading && !lists ? <Loading /> : !lists?.length ? (
        <div className="form">
          <p className="muted">{t("Vous n'avez pas encore de liste.")}</p>
          <Link to="/listes" className="btn btn-primary btn-block">{t("Créer ma liste")}</Link>
        </div>
      ) : (
        <div className="form">
          <p className="small"><b>{idea.title}</b> · {idea.site}</p>
          <Field label={t("Liste")}>
            <select className="input" value={chosen} onChange={e => setListId(e.target.value)}>
              {lists.map(l => <option key={l.id} value={l.id}>{l.title}</option>)}
            </select>
          </Field>
          <ErrorBox error={err instanceof Error ? err : null} />
          <button className="btn btn-primary btn-block" disabled={busy || !chosen} onClick={add}>{busy ? t("Ajout…") : t("Ajouter")}</button>
        </div>
      )}
    </Modal>
  );
}
