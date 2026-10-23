import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { formatPrice, Gift, qs } from "../api";
import { Breadcrumb, ErrorBox, Field, GiftCard, GiftGridSkeleton, IllustrativeNote } from "../components";
import { t } from "../i18n";
import { useApi, useStore } from "../store";

const budgets = [10000, 20000, 30000, 40000, 50000, 100000];
const sorts: [string, string][] = [["", "Notre sélection"], ["price_asc", "Prix croissant"], ["price_desc", "Prix décroissant"], ["recent", "Nouveautés"]];

export default function Catalog() {
  const { meta } = useStore();
  const [params, setParams] = useSearchParams();
  const get = (k: string) => params.get(k) ?? "";

  // Brouillon du formulaire, appliqué au clic sur « Appliquer les filtres »
  const [draft, setDraft] = useState({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who") });
  useEffect(() => setDraft({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who") }), [params]); // eslint-disable-line react-hooks/exhaustive-deps

  const query = qs({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who"), occasion: get("occasion"), sort: get("sort") });
  const { data: gifts, error, loading, reload } = useApi<Gift[]>(`/gifts${query}`);

  const apply = (next: Record<string, string>) => {
    const p = new URLSearchParams(params);
    Object.entries(next).forEach(([k, v]) => (v ? p.set(k, v) : p.delete(k)));
    setParams(p);
  };
  const submit = (e: FormEvent) => { e.preventDefault(); apply(draft); };

  const active: [string, string][] = [
    ["city", get("city")],
    ["budget", get("budget") && `≤ ${formatPrice(Number(get("budget")))}`],
    ["for_who", get("for_who") && t(get("for_who"))],
    ["occasion", get("occasion") && t(get("occasion"))],
    ["q", get("q") && `« ${get("q")} »`],
  ].filter(([, v]) => v) as [string, string][];

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Accueil"), "/"], [t("Cadeaux")]]} />
      <h1 className="display page-title" style={{ fontSize: 52 }}>{t("La bonne attention, au bon endroit.")}</h1>
      <p className="lead page-lead">{t("Pour les gens que vous aimez, selon leurs envies et votre budget.")}</p>

      <div className="catalog">
        <form className="panel filters" onSubmit={submit}>
          <h2 className="h2">{t("Affiner mes envies")}</h2>
          <div className="form" style={{ gap: 20 }}>
            <Field label={t("Nom du cadeau")}>
              <input className="input" placeholder={t("Rechercher un cadeau")} value={draft.q} onChange={e => setDraft({ ...draft, q: e.target.value })} />
            </Field>
            <Field label={t("Budget maximum")}>
              <select className="input" value={draft.budget} onChange={e => setDraft({ ...draft, budget: e.target.value })}>
                <option value="">{t("Tous les budgets")}</option>
                {budgets.map(b => <option key={b} value={b}>{formatPrice(b)}</option>)}
              </select>
            </Field>
            <Field label={t("Ville")}>
              <select className="input" value={draft.city} onChange={e => setDraft({ ...draft, city: e.target.value })}>
                <option value="">{t("Toutes les villes")}</option>
                {(meta?.cities ?? []).map(c => <option key={c}>{c}</option>)}
              </select>
            </Field>
            <div className="field">
              <span>{t("Pour qui ?")}</span>
              <div className="radio-list">
                <button type="button" className={!draft.for_who ? "on" : ""} onClick={() => setDraft({ ...draft, for_who: "" })}>{t("Tous les cadeaux")}</button>
                {(meta?.for_who ?? []).map(f => (
                  <button type="button" key={f} className={draft.for_who === f ? "on" : ""} onClick={() => setDraft({ ...draft, for_who: f })}>{t(f)}</button>
                ))}
              </div>
            </div>
            <button className="btn btn-primary btn-block">{t("Appliquer les filtres")}</button>
            <button type="button" className="link-plain" style={{ alignSelf: "center" }} onClick={() => setParams(new URLSearchParams())}>{t("Réinitialiser")}</button>
          </div>
        </form>

        <div>
          <div className="toolbar">
            {active.map(([k, label]) => (
              <button key={k} className="chip on" onClick={() => apply({ [k]: "" })} aria-label={t("Retirer le filtre {label}", { label })}>{label} ×</button>
            ))}
            <select className="sort" value={get("sort")} onChange={e => apply({ sort: e.target.value })} aria-label={t("Trier")}>
              {sorts.map(([v, l]) => <option key={v} value={v}>{t("Trier : {sort}", { sort: t(l) })}</option>)}
            </select>
          </div>
          <div style={{ marginBottom: 26 }}><IllustrativeNote /></div>
          <ErrorBox error={error} onRetry={reload} />
          {loading ? <GiftGridSkeleton /> : gifts && gifts.length > 0 ? (
            <div className="gift-grid">{gifts.map(g => <GiftCard key={g.id} gift={g} />)}</div>
          ) : !error && (
            <div className="empty">{t("Aucun cadeau ne correspond à ces critères.")} <button className="link" onClick={() => setParams(new URLSearchParams())}>{t("Voir tous les cadeaux")}</button></div>
          )}

          <div className="panel rose custom-cta">
            <h2>{t("Vous avez une idée bien précise ?")}</h2>
            <p>{t("Décrivez le cadeau de vos rêves. Nous vous accompagnons pour le personnaliser.")}</p>
            <Link to="/personnalise" className="btn btn-outline btn-block">{t("Demander un cadeau personnalisé")}</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
