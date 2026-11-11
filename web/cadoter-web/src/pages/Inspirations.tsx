import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Article } from "../api";
import { Breadcrumb, ErrorBox, Loading, Photo } from "../components";
import { t } from "../i18n";
import { useApi } from "../store";

export default function Inspirations() {
  const { data: articles, error, loading, reload } = useApi<Article[]>("/inspirations");
  const all = t("Tout lire");
  const [tag, setTag] = useState(all);
  const tags = [all, ...Array.from(new Set((articles ?? []).map(a => a.tag)))];
  const shown = tag === all ? articles ?? [] : (articles ?? []).filter(a => a.tag === tag);
  const [feature, ...rest] = shown;

  return (
    <div className="wrap">
      <p className="eyebrow" style={{ margin: "40px 0 20px" }}>{t("Le journal des belles attentions")}</p>
      <h1 className="display" style={{ fontSize: 52, lineHeight: 1.2 }}>{t("CADOTER pour vous inspirer.")}</h1>
      <p className="lead" style={{ margin: "18px 0 26px" }}>{t("Des idées à lire, des liens à cultiver, des attentions à inventer.")}</p>
      <ErrorBox error={error} onRetry={reload} />
      {loading && !articles ? <Loading /> : articles?.length === 0 ? (
        <div className="empty">{t("Aucun article pour le moment.")}</div>
      ) : (
        <>
          <div className="chips" style={{ marginBottom: 28 }}>
            {tags.map(tg => <button key={tg} className={`chip ${tg === tag ? "on" : ""}`} onClick={() => setTag(tg)}>{tg}</button>)}
          </div>

          {feature && (
            <Link to={`/inspirations/${feature.slug}`} className="feature" style={{ display: "block" }}>
              <Photo src={feature.image_url} />
              <p className="eyebrow">{feature.tag} · {t("{n} min de lecture", { n: feature.minutes })}</p>
              <h2>{feature.title}</h2>
              {feature.excerpt && <p className="lead" style={{ fontSize: 15, marginBottom: 18 }}>{feature.excerpt}</p>}
              <span className="link">{t("Lire l'article →")}</span>
            </Link>
          )}
          <div className="articles" style={{ marginTop: 40, gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))" }}>
            {rest.map(a => (
              <Link key={a.slug} to={`/inspirations/${a.slug}`} className="article">
                <Photo src={a.image_url} />
                <p className="eyebrow">{a.tag} · {a.minutes} min</p>
                <h3>{a.title}</h3>
                <span className="link-plain">{t("Lire l'article →")}</span>
              </Link>
            ))}
          </div>
        </>
      )}
    </div>
  );
}

export function ArticlePage() {
  const { slug = "" } = useParams();
  const { data: a, error, loading } = useApi<Article>(`/inspirations/${encodeURIComponent(slug)}`);
  if (loading && !a) return <div className="wrap"><Loading /></div>;
  if (!a) {
    if (error && error.status !== 404) return <div className="wrap"><ErrorBox error={error} /></div>;
    return <div className="wrap"><div className="empty" style={{ marginTop: 60 }}>{t("Article introuvable.")} <Link className="link" to="/inspirations">{t("Tous les articles")}</Link></div></div>;
  }
  return (
    <div className="wrap">
      <article className="article-page">
        <Breadcrumb items={[[t("Inspirations"), "/inspirations"], [a.tag]]} />
        <p className="eyebrow">{a.tag} · {t("{n} min de lecture", { n: a.minutes })}</p>
        <h1 className="display" style={{ fontSize: 48, lineHeight: 1.2, marginTop: 14 }}>{a.title}</h1>
        <Photo src={a.image_url} />
        {(a.body ?? []).map((p, i) => <p key={i}>{p}</p>)}
        <div className="btn-row" style={{ marginTop: 34 }}>
          <Link to="/cadeaux" className="btn btn-primary">{t("Explorer les cadeaux")}</Link>
          <Link to="/assistante" className="btn btn-outline">{t("Trouver une idée avec l'IA")}</Link>
        </div>
      </article>
    </div>
  );
}
