import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Article, formatPrice, Gift } from "../api";
import { ErrorBox, GiftCard, GiftGridSkeleton, IllustrativeNote, Photo } from "../components";
import { occasionsHome as occasions } from "../data";
import { t } from "../i18n";
import { Icon, IconName } from "../icons";
import { useApi, useStore } from "../store";

const budgets = [10000, 20000, 30000, 40000, 50000, 100000];

const occasionIcons: IconName[] = ["cake", "rings", "baby", "gift"];

export default function Home() {
  const nav = useNavigate();
  const { meta, user } = useStore();
  const { data: gifts, error, loading, reload } = useApi<Gift[]>("/gifts?featured=1&limit=6");
  const { data: articles } = useApi<Article[]>("/inspirations");
  const cities = meta?.cities ?? ["Abidjan"];
  const forWho = meta?.for_who ?? ["Enfants", "Parents", "Couple", "Ami(e)s", "Collègue", "Famille"];
  const [q, setQ] = useState("");
  const [budget, setBudget] = useState("");
  const [city, setCity] = useState("Abidjan");

  const search = (e: FormEvent) => {
    e.preventDefault();
    const p = new URLSearchParams();
    if (q) p.set("q", q);
    if (budget) p.set("budget", budget);
    if (city) p.set("city", city);
    nav(`/cadeaux?${p}`);
  };

  return (
    <>
      <section className="hero">
        <div className="wrap">
          <div className="hero-grid">
            <div className="hero-copy">
              <p className="eyebrow">{t("Le bonheur d'offrir, tout simplement")}</p>
              <h1 className="display">{t("De petites attentions.")}<br />{t("De grands liens.")}</h1>
              <p className="lead">{t("Un anniversaire, une naissance ou juste l'envie de dire merci. Trouvez le cadeau qui raconte votre lien.")}</p>
              <div className="actions">
                <Link to="/cadeaux" className="btn btn-primary">{t("Explorer les cadeaux")} <Icon name="arrow" size={18} /></Link>
                <Link to={user ? "/listes" : "/inscription?next=%2Flistes"} className="btn btn-outline">{t("Créer ma liste")}</Link>
              </div>
              <p className="small muted">{t("Des idées choisies avec cœur, à partager à votre façon.")}</p>
            </div>
            <img className="photo" src="/img/hero-home.jpg" alt={t("Une jeune femme offre un cadeau à son père")} />
          </div>
          <form className="searchbar" onSubmit={search}>
            <Icon name="search" size={22} className="price" />
            <label><b>{t("Je cherche")}</b><input value={q} onChange={e => setQ(e.target.value)} placeholder={t("Un cadeau, une idée, une envie…")} /></label>
            <label><b>{t("Mon budget")}</b>
              <select value={budget} onChange={e => setBudget(e.target.value)}>
                <option value="">{t("Tous les budgets")}</option>
                {budgets.map(b => <option key={b} value={b}>≤ {formatPrice(b)}</option>)}
              </select>
            </label>
            <label><b>{t("Ma ville")}</b>
              <select value={city} onChange={e => setCity(e.target.value)}>
                {cities.map(c => <option key={c}>{c}</option>)}
              </select>
            </label>
            <button className="btn btn-primary">{t("Trouver un cadeau")}</button>
          </form>
        </div>
      </section>

      <section className="section wrap">
        <h2 className="h2" style={{ marginBottom: 32 }}>{t("Chaque moment mérite son attention.")}</h2>
        <div className="occasions">
          {occasions.map((o, i) => (
            <Link key={o} to={`/cadeaux?occasion=${o}`} className="occasion"><Icon name={occasionIcons[i]} size={22} />{t(o)}</Link>
          ))}
        </div>
        <div className="support">
          <span>{t("Accompagner un proche après un décès : des attentions sobres et respectueuses.")}</span>
          <Link to="/inspirations/soutenir-un-proche">{t("Découvrir les idées de soutien →")}</Link>
        </div>
        <div className="forwho">
          <b>{t("Pour qui ?")}</b>
          <div className="chips">{forWho.map(f => <Link key={f} className="chip" to={`/cadeaux?for_who=${encodeURIComponent(f)}`}>{t(f)}</Link>)}</div>
        </div>
      </section>

      <section className="section wrap">
        <div className="section-head">
          <h2 className="h2">{t("Des cadeaux qui ont quelque chose à dire.")}</h2>
          <Link to="/cadeaux" className="link">{t("Explorer le catalogue →")}</Link>
        </div>
        <div style={{ marginBottom: 32 }}><IllustrativeNote /></div>
        <ErrorBox error={error} onRetry={reload} />
        {loading ? <GiftGridSkeleton /> : (
          gifts && gifts.length > 0
            ? <div className="gift-grid">{gifts.slice(0, 6).map(g => <GiftCard key={g.id} gift={g} />)}</div>
            : !error && <div className="empty">{t("Les premiers cadeaux arrivent bientôt.")}</div>
        )}
      </section>

      <section className="section wrap">
        <div className="list-promo">
          <img className="photo" src="/img/the.jpg" alt="" />
          <div>
            <p className="eyebrow" style={{ marginBottom: 18 }}>{t("Vos envies, réunies")}</p>
            <h2 className="h1" style={{ fontSize: 40 }}>{t("Une liste. Tous vos sites favoris.")}</h2>
            <p className="muted" style={{ marginTop: 18, fontSize: 14 }}>{t("Sans limite de produits, sans doublons : vos proches réservent le cadeau qu'ils souhaitent vous offrir.")}</p>
            <div className="steps">
              <div><strong>01</strong><span>{t("Je crée ma liste")}</span></div>
              <div><strong>02</strong><span>{t("J'ajoute des produits")}</span></div>
              <div><strong>03</strong><span>{t("Je partage ma liste")}</span></div>
            </div>
            <Link to={user ? "/listes" : "/inscription?next=%2Flistes"} className="btn btn-primary btn-block">{t("Créer ma première liste")}</Link>
          </div>
        </div>
      </section>

      <section className="section wrap">
        <div className="duo">
          <div className="panel rose">
            <Icon name="sparkle" size={34} className="price" />
            <h2 className="h1">{t("Les bonnes idées commencent par une conversation.")}</h2>
            <p className="muted" style={{ fontSize: 14 }}>{t("Une personne, une occasion, un budget : l'assistante IA vous propose des pistes personnelles.")}</p>
            <Link to="/assistante" className="btn btn-primary btn-block">{t("Trouver une idée avec l'IA")}</Link>
          </div>
          <div className="panel wrap-promo">
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <h2>{t("Le soin du dernier détail.")}</h2>
              <p className="muted small" style={{ fontSize: 13 }}>{t("Rosé, kraft ou bleu ciel : trouvez l'écrin qui lui ressemble.")}</p>
              <Link to="/personnalise" className="link">{t("Voir les emballages →")}</Link>
            </div>
            <img className="photo" src="/img/emballage-rose.jpg" alt={t("Cadeau emballé de papier rosé et ruban magenta")} />
          </div>
        </div>
      </section>

      <section className="section wrap">
        <div className="section-head">
          <h2 className="h2">{t("CADOTER pour vous inspirer")}</h2>
          <Link to="/inspirations" className="link">{t("Tous les articles →")}</Link>
        </div>
        <div className="articles" style={{ marginTop: 32 }}>
          {(articles ?? []).slice(0, 3).map(a => (
            <Link key={a.slug} to={`/inspirations/${a.slug}`} className="article">
              <Photo src={a.image_url} />
              <p className="eyebrow">{a.tag}</p>
              <h3>{a.title}</h3>
              <span className="link-plain">{t("Lire l'article →")}</span>
            </Link>
          ))}
        </div>
      </section>
    </>
  );
}
