import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { Breadcrumb } from "../components";
import { articles } from "../data";

export default function Inspirations() {
  const tags = ["Tout lire", ...Array.from(new Set(articles.map(a => a.tag)))];
  const [tag, setTag] = useState("Tout lire");
  const shown = tag === "Tout lire" ? articles : articles.filter(a => a.tag === tag);
  const [feature, ...rest] = shown;

  return (
    <div className="wrap">
      <p className="eyebrow" style={{ margin: "40px 0 20px" }}>Le journal des belles attentions</p>
      <h1 className="display" style={{ fontSize: 52, lineHeight: 1.2 }}>CADOTER pour vous inspirer.</h1>
      <p className="lead" style={{ margin: "18px 0 26px" }}>Des idées à lire, des liens à cultiver, des attentions à inventer.</p>
      <div className="chips" style={{ marginBottom: 28 }}>
        {tags.map(t => <button key={t} className={`chip ${t === tag ? "on" : ""}`} onClick={() => setTag(t)}>{t}</button>)}
      </div>

      {feature && (
        <Link to={`/inspirations/${feature.slug}`} className="feature" style={{ display: "block" }}>
          <img className="photo" src={feature.image} alt="" />
          <p className="eyebrow">{feature.tag} · {feature.minutes} min de lecture</p>
          <h2>{feature.title}</h2>
          <p className="lead" style={{ fontSize: 15, marginBottom: 18 }}>{feature.excerpt}</p>
          <span className="link">Lire l'article →</span>
        </Link>
      )}
      <div className="articles" style={{ marginTop: 40, gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))" }}>
        {rest.map(a => (
          <Link key={a.slug} to={`/inspirations/${a.slug}`} className="article">
            <img className="photo" src={a.image} alt="" loading="lazy" />
            <p className="eyebrow">{a.tag} · {a.minutes} min</p>
            <h3>{a.title}</h3>
            <span className="link-plain">Lire l'article →</span>
          </Link>
        ))}
      </div>
    </div>
  );
}

export function ArticlePage() {
  const { slug } = useParams();
  const a = articles.find(x => x.slug === slug);
  if (!a) return <div className="wrap"><div className="empty" style={{ marginTop: 60 }}>Article introuvable. <Link className="link" to="/inspirations">Tous les articles</Link></div></div>;
  return (
    <div className="wrap">
      <article className="article-page">
        <Breadcrumb items={[["Inspirations", "/inspirations"], [a.tag]]} />
        <p className="eyebrow">{a.tag} · {a.minutes} min de lecture</p>
        <h1 className="display" style={{ fontSize: 48, lineHeight: 1.2, marginTop: 14 }}>{a.title}</h1>
        <img className="photo" src={a.image} alt="" />
        {a.body.map((p, i) => <p key={i}>{p}</p>)}
        <div className="btn-row" style={{ marginTop: 34 }}>
          <Link to="/cadeaux" className="btn btn-primary">Explorer les cadeaux</Link>
          <Link to="/assistante" className="btn btn-outline">Trouver une idée avec l'IA</Link>
        </div>
      </article>
    </div>
  );
}
