import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { formatPrice, Gift } from "../api";
import { ErrorBox, GiftCard, GiftGridSkeleton, IllustrativeNote } from "../components";
import { articles, occasionsHome as occasions } from "../data";
import { Icon, IconName } from "../icons";
import { useApi, useStore } from "../store";

const budgets = [10000, 20000, 30000, 40000, 50000, 100000];

const occasionIcons: IconName[] = ["cake", "rings", "baby", "gift"];

export default function Home() {
  const nav = useNavigate();
  const { meta, user } = useStore();
  const { data: gifts, error, loading, reload } = useApi<Gift[]>("/gifts?featured=1&limit=6");
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
              <p className="eyebrow">Le bonheur d'offrir, tout simplement</p>
              <h1 className="display">De petites attentions.<br />De grands liens.</h1>
              <p className="lead">Un anniversaire, une naissance ou juste l'envie de dire merci. Trouvez le cadeau qui raconte votre lien.</p>
              <div className="actions">
                <Link to="/cadeaux" className="btn btn-primary">Explorer les cadeaux <Icon name="arrow" size={18} /></Link>
                <Link to={user ? "/listes" : "/inscription"} className="btn btn-outline">Créer ma liste</Link>
              </div>
              <p className="small muted">Des idées choisies avec cœur, à partager à votre façon.</p>
            </div>
            <img className="photo" src="/img/hero-home.jpg" alt="Une jeune femme offre un cadeau à son père" />
          </div>
          <form className="searchbar" onSubmit={search}>
            <Icon name="search" size={22} className="price" />
            <label><b>Je cherche</b><input value={q} onChange={e => setQ(e.target.value)} placeholder="Un cadeau, une idée, une envie…" /></label>
            <label><b>Mon budget</b>
              <select value={budget} onChange={e => setBudget(e.target.value)}>
                <option value="">Tous les budgets</option>
                {budgets.map(b => <option key={b} value={b}>≤ {formatPrice(b)}</option>)}
              </select>
            </label>
            <label><b>Ma ville</b>
              <select value={city} onChange={e => setCity(e.target.value)}>
                {cities.map(c => <option key={c}>{c}</option>)}
              </select>
            </label>
            <button className="btn btn-primary">Trouver un cadeau</button>
          </form>
        </div>
      </section>

      <section className="section wrap">
        <h2 className="h2" style={{ marginBottom: 32 }}>Chaque moment mérite son attention.</h2>
        <div className="occasions">
          {occasions.map((o, i) => (
            <Link key={o} to={`/cadeaux?occasion=${o}`} className="occasion"><Icon name={occasionIcons[i]} size={22} />{o}</Link>
          ))}
        </div>
        <div className="support">
          <span>Accompagner un proche après un décès : des attentions sobres et respectueuses.</span>
          <Link to="/inspirations/soutenir-un-proche">Découvrir les idées de soutien →</Link>
        </div>
        <div className="forwho">
          <b>Pour qui ?</b>
          <div className="chips">{forWho.map(f => <Link key={f} className="chip" to={`/cadeaux?for_who=${encodeURIComponent(f)}`}>{f}</Link>)}</div>
        </div>
      </section>

      <section className="section wrap">
        <div className="section-head">
          <h2 className="h2">Des cadeaux qui ont quelque chose à dire.</h2>
          <Link to="/cadeaux" className="link">Explorer le catalogue →</Link>
        </div>
        <div style={{ marginBottom: 32 }}><IllustrativeNote /></div>
        <ErrorBox error={error} onRetry={reload} />
        {loading ? <GiftGridSkeleton /> : (
          gifts && gifts.length > 0
            ? <div className="gift-grid">{gifts.slice(0, 6).map(g => <GiftCard key={g.id} gift={g} />)}</div>
            : !error && <div className="empty">Les premiers cadeaux arrivent bientôt.</div>
        )}
      </section>

      <section className="section wrap">
        <div className="list-promo">
          <img className="photo" src="/img/the.jpg" alt="" />
          <div>
            <p className="eyebrow" style={{ marginBottom: 18 }}>Vos envies, réunies</p>
            <h2 className="h1" style={{ fontSize: 40 }}>Une liste. Tous vos sites favoris.</h2>
            <p className="muted" style={{ marginTop: 18, fontSize: 14 }}>Sans limite de produits, sans doublons : vos proches réservent le cadeau qu'ils souhaitent vous offrir.</p>
            <div className="steps">
              <div><strong>01</strong><span>Je crée ma liste</span></div>
              <div><strong>02</strong><span>J'ajoute des produits</span></div>
              <div><strong>03</strong><span>Je partage ma liste</span></div>
            </div>
            <Link to={user ? "/listes" : "/inscription"} className="btn btn-primary btn-block">Créer ma première liste</Link>
          </div>
        </div>
      </section>

      <section className="section wrap">
        <div className="duo">
          <div className="panel rose">
            <Icon name="sparkle" size={34} className="price" />
            <h2 className="h1">Les bonnes idées commencent par une conversation.</h2>
            <p className="muted" style={{ fontSize: 14 }}>Une personne, une occasion, un budget : l'assistante IA vous propose des pistes personnelles.</p>
            <Link to="/assistante" className="btn btn-primary btn-block">Trouver une idée avec l'IA</Link>
          </div>
          <div className="panel wrap-promo">
            <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
              <h2>Le soin du dernier détail.</h2>
              <p className="muted small" style={{ fontSize: 13 }}>Rosé, kraft ou bleu ciel : trouvez l'écrin qui lui ressemble.</p>
              <Link to="/personnalise" className="link">Voir les emballages →</Link>
            </div>
            <img className="photo" src="/img/emballage-rose.jpg" alt="Cadeau emballé de papier rosé et ruban magenta" />
          </div>
        </div>
      </section>

      <section className="section wrap">
        <div className="section-head">
          <h2 className="h2">CADOTER pour vous inspirer</h2>
          <Link to="/inspirations" className="link">Tous les articles →</Link>
        </div>
        <div className="articles" style={{ marginTop: 32 }}>
          {articles.slice(0, 3).map(a => (
            <Link key={a.slug} to={`/inspirations/${a.slug}`} className="article">
              <img className="photo" src={a.image} alt="" loading="lazy" />
              <p className="eyebrow">{a.tag}</p>
              <h3>{a.title}</h3>
              <span className="link-plain">Lire l'article →</span>
            </Link>
          ))}
        </div>
      </section>
    </>
  );
}
