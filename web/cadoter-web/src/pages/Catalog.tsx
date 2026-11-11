import { FormEvent, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { cachedApi, formatPrice, Gift, Paginated, qs } from "../api";
import { Breadcrumb, ErrorBox, Field, GiftCard, GiftGridSkeleton, IllustrativeNote, Pagination } from "../components";
import { t, tn } from "../i18n";
import { useApi, useStore } from "../store";

const sorts: [string, string][] = [["", "Notre sélection"], ["price_asc", "Prix croissant"], ["price_desc", "Prix décroissant"], ["recent", "Nouveautés"]];

export default function Catalog() {
  const { meta } = useStore();
  const [params, setParams] = useSearchParams();
  const get = (k: string) => params.get(k) ?? "";

  // Brouillon du formulaire, appliqué au clic sur « Appliquer les filtres »
  const [draft, setDraft] = useState({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who"), occasion: get("occasion") });
  useEffect(() => setDraft({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who"), occasion: get("occasion") }), [params]); // eslint-disable-line react-hooks/exhaustive-deps

  const page = Math.max(1, Number(get("page")) || 1);
  const giftsPath = (n: number) => `/gifts${qs({ q: get("q"), budget: get("budget"), city: get("city"), for_who: get("for_who"), occasion: get("occasion"), sort: get("sort"), page: n })}`;
  const { data: result, error, loading, reload } = useApi<Paginated<Gift>>(giftsPath(page));
  const gifts = result?.data;

  // Page suivante préchargée : elle s'affiche immédiatement au clic
  useEffect(() => {
    if (result && result.current_page < result.last_page) cachedApi(giftsPath(result.current_page + 1)).catch(() => undefined);
  }, [result]); // eslint-disable-line react-hooks/exhaustive-deps

  // Tout changement de filtre ou de tri repart de la première page
  const apply = (next: Record<string, string>) => {
    const p = new URLSearchParams(params);
    Object.entries(next).forEach(([k, v]) => (v ? p.set(k, v) : p.delete(k)));
    if (!("page" in next)) p.delete("page");
    setParams(p);
  };
  const goTo = (n: number) => {
    apply({ page: n > 1 ? String(n) : "" });
    window.scrollTo({ top: 0, behavior: "smooth" });
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
            <Field label={t("Budget maximum (FCFA)")}>
              <input className="input" type="number" inputMode="numeric" min={0} step={500} value={draft.budget} onChange={e => setDraft({ ...draft, budget: e.target.value })} placeholder={t("Ex. {n}", { n: "40 000" })} />
            </Field>
            <Field label={t("Type d’événement")}>
              <select className="input" value={draft.occasion} onChange={e => setDraft({ ...draft, occasion: e.target.value })}>
                <option value="">{t("Tous les événements")}</option>
                {(meta?.occasions ?? []).map(occasion => <option key={occasion} value={occasion}>{t(occasion)}</option>)}
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
          <div style={{ marginBottom: 26 }}>
            {result && <p className="note" style={{ marginBottom: 4 }}>{tn(result.total, "{n} cadeau", "{n} cadeaux")}</p>}
            <IllustrativeNote />
          </div>
          <ErrorBox error={error} onRetry={reload} />
          {loading ? <GiftGridSkeleton /> : gifts && gifts.length > 0 ? (
            <>
              <div className="gift-grid">{gifts.map(g => <GiftCard key={g.id} gift={g} />)}</div>
              {result && <Pagination page={result.current_page} last={result.last_page} onChange={goTo} />}
            </>
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
