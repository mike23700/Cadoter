import { useState, FormEvent } from "react";
import { Link, useParams, useNavigate } from "react-router-dom";
import { articles, cities, forWho, gifts, occasions, price } from "./data";
import type { Gift } from "./data";
import { useStore } from "./store";

function Card({ g }: { g: Gift }) {
  const { reserved } = useStore();
  const taken = reserved.includes(g.id);
  return (
    <Link to={`/cadeaux/${g.id}`} className="card">
      <div className="pic">{g.emoji}</div>
      <h3>{g.name}</h3>
      <p>{price(g)} · {g.city}</p>
      <span className={taken ? "tag off" : "tag"}>{taken ? "Réservé" : "Disponible"}</span>
    </Link>
  );
}

function navigateTo(path: string) {
  window.location.href = path;
}

/* ---------- Accueil ---------- */
export function Home() {
  const navigate = useNavigate();
  return (
    <>
      <section className="hero flex flex-col items-start gap-28 px-64 py-35">
        <div className="content-inner flex items-center gap-60 flex-wrap" style={{ width: "100%" }}>
          <div className="flex-col" style={{ width: 632, minWidth: 280 }}>
            <p className="kicker serif text-magenta">À qui faire plaisir</p>
            <h1 className="serif-title text-dark" style={{ fontSize: 67, lineHeight: "135%", width: "100%" }}>
              Offrez le cadeau qui fait vraiment plaisir
            </h1>
            <p className="text-gray" style={{ fontSize: 18, lineHeight: "135%", width: "100%", marginTop: 12 }}>
              Créez une liste, partagez le lien, et laissez vos proches choisir sans jamais offrir deux fois la même chose.
            </p>
            <div className="flex gap-14" style={{ marginTop: 28, flexWrap: "wrap" }}>
              <Link className="btn btn-primary" to="/listes">Créer ma liste</Link>
              <Link className="btn btn-outline" to="/cadeaux">Voir le catalogue</Link>
            </div>
            <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%", width: "100%", marginTop: 16 }}>
              Le bonheur d'offrir, tout simplement.
            </p>
          </div>
          <div className="photo" style={{ width: 620, height: 470 }} />
        </div>
      </section>

      <section className="py-30 px-64">
        <div className="container">
          <div className="content-inner">
            <div style={{ width: "100%", background: "#fff", borderRadius: 16, display: "flex", alignItems: "center", padding: 18, gap: 24, flexWrap: "wrap" }}>
              <div style={{ width: 22, height: 22, border: "1.7px solid #C90091", borderRadius: "50%" }} />
              <div className="flex-col" style={{ width: 360, gap: 4, minWidth: 200 }}>
                <label className="field-label">Nom du cadeau</label>
                <input type="text" placeholder="Ex. bouquet de fleurs séchées" style={{ fontSize: 14, color: "#786C74", border: "none", outline: "none", background: "transparent", width: "100%" }} />
              </div>
              <div className="flex-col" style={{ width: 220, gap: 4, minWidth: 160 }}>
                <label className="field-label">Budget</label>
                <input type="text" placeholder="Ex. 15 000 FCFA" style={{ fontSize: 14, color: "#786C74", border: "none", outline: "none", background: "transparent", width: "100%" }} />
              </div>
              <div className="flex-col" style={{ width: 220, gap: 4, minWidth: 160 }}>
                <label className="field-label">Localisation</label>
                <input type="text" placeholder="Ville, pays" style={{ fontSize: 14, color: "#786C74", border: "none", outline: "none", background: "transparent", width: "100%" }} />
              </div>
              <a className="btn btn-primary" onClick={(e) => { e.preventDefault(); navigate("/cadeaux"); }}>Rechercher</a>
            </div>
          </div>
        </div>
      </section>

      <section className="py-60 px-64">
        <div className="container">
          <div className="content-inner">
            <div className="flex items-center justify-between gap-12" style={{ width: "100%", marginBottom: 12 }}>
              <h2 className="serif-title text-dark" style={{ fontSize: 23 }}>Occasions</h2>
            </div>
            <div className="flex-row gap-16" style={{ width: "100%", flexWrap: "wrap", marginBottom: 36 }}>
              {occasions.map((o) => (
                <div key={o} className="occasion" style={{ width: 316, height: 72, background: "#FAF7F2", borderRadius: 18, display: "flex", alignItems: "center", padding: 25, gap: 15, minWidth: 240 }}>
                  <div style={{ width: 22, height: 22, border: "1.7px solid #C90091", borderRadius: "50%" }} />
                  <span style={{ width: 229, fontWeight: 600, fontSize: 14, color: "#30232C" }}>{o}</span>
                </div>
              ))}
            </div>
            <div className="flex items-center gap-12" style={{ width: "100%" }}>
              <p className="text-gray" style={{ fontSize: 13, flex: 1 }}>Besoin d'aide pour choisir ? Découvrez l'assistante IA.</p>
              <span style={{ fontSize: 13, color: "#30232C", cursor: "pointer" }} onClick={() => navigate("/assistante")}>En savoir plus →</span>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div className="container">
          <div className="content-inner">
            <div className="flex items-center gap-12" style={{ width: "100%", marginTop: 36 }}>
              <p className="serif-title text-dark" style={{ fontSize: 14, fontWeight: 600 }}>Catégories</p>
            </div>
            <div className="flex-row gap-12" style={{ width: "100%", flexWrap: "wrap" }}>
              {forWho.map((c) => (
                <div key={c} className="filtre filtre-default" onClick={() => navigateTo("/cadeaux")}>{c}</div>
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="py-28">
        <div className="container">
          <div className="content-inner">
            <div className="flex items-center gap-12" style={{ width: "100%", marginTop: 36 }}>
              <h2 className="serif-title text-dark" style={{ fontSize: 23 }}>Sélection pour vous</h2>
              <a href="/catalogue" className="text-magenta" style={{ fontSize: 12, fontWeight: 600 }} onClick={(e) => { e.preventDefault(); navigate("/cadeaux"); }}>Voir tout →</a>
            </div>
            <div className="flex-row gap-28" style={{ width: "100%", overflowX: "auto", paddingBottom: 20 }}>
              {gifts.slice(0, 3).map((g) => (
                <Card key={g.id} g={g} />
              ))}
            </div>
          </div>
        </div>
      </section>

      <section className="py-20 px-64" style={{ paddingBottom: 70 }}>
        <div className="container">
          <div className="content-inner" style={{ display: "flex", flexDirection: "column", gap: 60 }}>
            <div style={{ width: "100%", height: 440, background: "#FAF7F2", borderRadius: 24, display: "flex", alignItems: "center", padding: 40, gap: 65, flexWrap: "wrap" }}>
              <div className="photo" style={{ width: 440, height: 360 }} />
              <div className="flex-col" style={{ width: 727, gap: 21, minWidth: 280 }}>
                <p className="text-magenta" style={{ fontWeight: 600, fontSize: 13 }}>Créer et partager</p>
                <h2 className="serif-title text-dark" style={{ fontSize: 40, lineHeight: "135%" }}>Une liste pour chaque moment de vie</h2>
                <p className="text-gray" style={{ fontSize: 14, lineHeight: "135%" }}>Anniversaire, mariage, naissance, dot ou soutien : créez votre liste en quelques clics et partagez le lien avec vos proches.</p>
                <div className="flex-row gap-20" style={{ display: "flex", gap: 20, flexWrap: "wrap" }}>
                  {["1", "2", "3"].map((n) => (
                    <div key={n} className="etape flex-col gap-10" style={{ width: 229 }}>
                      <span className="serif-title text-magenta" style={{ fontSize: 24 }}>{n}</span>
                      <p style={{ fontWeight: 600, fontSize: 13, color: "#30232C" }}>{n === "1" ? "Créez votre liste" : n === "2" ? "Ajoutez vos cadeaux" : "Partagez le lien"}</p>
                    </div>
                  ))}
                </div>
                <a className="btn btn-primary btn-full" onClick={(e) => { e.preventDefault(); navigate("/listes"); }}>Commencer ma liste</a>
              </div>
            </div>

            <div className="flex items-center gap-12" style={{ width: "100%" }}>
              <h2 className="serif-title text-dark" style={{ fontSize: 23 }}>Journal & inspirations</h2>
              <a href="/inspirations" className="text-magenta" style={{ fontSize: 12, fontWeight: 600 }} onClick={(e) => { e.preventDefault(); navigate("/inspirations"); }}>Tous les articles →</a>
            </div>
            <div className="flex-row gap-28" style={{ width: "100%", overflowX: "auto", paddingBottom: 20 }}>
              {articles.map((a) => (
                <article key={a} className="article flex-col gap-13" style={{ width: 418.67 }}>
                  <div className="photo" style={{ width: 418.67, height: 235 }} />
                  <p className="text-magenta" style={{ fontWeight: 600, fontSize: 11, lineHeight: "135%" }}>Article</p>
                  <h3 className="serif-title text-dark" style={{ fontSize: 27, lineHeight: "135%" }}>{a}</h3>
                  <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>Découvrez cette inspiration.</p>
                  <p className="text-magenta" style={{ fontWeight: 600, fontSize: 13, lineHeight: "135%" }}>Lire l'article →</p>
                </article>
              ))}
            </div>
          </div>
        </div>
      </section>
    </>
  );
}

/* ---------- Catalogue ---------- */
export function Catalog() {
  const [q, setQ] = useState("");
  const [who, setWho] = useState("");
  const [city, setCity] = useState("");
  const [max, setMax] = useState(30000);
  const list = gifts.filter((g) => g.name.toLowerCase().includes(q.toLowerCase()) && (!who || g.forWho === who) && (!city || g.city === city) && g.price <= max);

  return (
    <>
      <section className="py-35 px-64">
        <div className="container">
          <div className="content-inner">
            <p className="text-gray" style={{ fontSize: 12 }}>Trouvez le cadeau idéal</p>
            <h1 className="serif-title text-dark" style={{ fontSize: 52, lineHeight: "135%", width: "100%" }}>Notre catalogue de cadeaux</h1>
            <p className="text-gray" style={{ fontSize: 17, lineHeight: "135%", width: "100%" }}>Découvrez notre sélection de cadeaux disponibles et réservez celui qui fera plaisir.</p>
          </div>
        </div>
      </section>

      <section style={{ padding: "0 64px" }}>
        <div className="container">
          <div className="content-inner" style={{ display: "flex", gap: 40, width: "100%", flexWrap: "wrap" }}>
            <aside className="flex-col gap-22" style={{ width: 265, background: "#FAF7F2", borderRadius: 20, padding: 22, minWidth: 220 }}>
              <h2 className="serif-title text-dark" style={{ fontSize: 21, lineHeight: "135%" }}>Filtrer</h2>
              <label className="field-label">Recherche</label>
              <div className="input-field"><input type="text" placeholder="Nom du cadeau..." value={q} onChange={(e) => setQ(e.target.value)} /></div>
              <label className="field-label">Budget max</label>
              <div className="input-field"><input type="text" placeholder="Ex. 50 000 FCFA" value="" onChange={() => {}} /></div>
              <label className="field-label">Ville</label>
              <div className="input-field"><input type="text" placeholder="Ville" value="" onChange={() => {}} /></div>
              <p style={{ fontSize: 12, fontWeight: 600, color: "#30232C", marginTop: 16 }}>Disponibilité</p>
              {["Tous", "Disponible", "Réservés", "Indisponibles", "En rupture", "À vérifier", "En stock", "En commande", "Précommande", "Épuisé"].map((d) => (
                <div key={d} style={{ marginBottom: 8 }}>
                  <div className="filtre filtre-default">{d}</div>
                </div>
              ))}
              <a className="btn btn-primary btn-full" href="#">Appliquer les filtres</a>
              <a className="btn btn-outline btn-full" href="#" style={{ marginTop: 8 }}>Afficher 12 produits</a>
            </aside>

            <main className="flex-1" style={{ minWidth: 280 }}>
              <div className="flex items-center gap-10" style={{ width: "100%", marginBottom: 8 }}>
                <div className="filtre filtre-active">Anniversaire</div>
                <div className="filtre filtre-default">Disponible</div>
                <span style={{ flex: 1, fontSize: 12, color: "#786C74" }}>{list.length} produits trouvés</span>
              </div>
              <p className="text-gray" style={{ fontSize: 11, width: "100%" }}>Trier par : Pertinence</p>
              <div className="flex-row gap-24" style={{ width: "100%", flexWrap: "wrap", marginTop: 16 }}>
                {list.map((g) => <Card key={g.id} g={g} />)}
              </div>
              <div className="flex-col gap-14" style={{ width: "100%", background: "#FCECF6", borderRadius: 20, padding: 26, marginTop: 24 }}>
                <h2 className="serif-title text-dark" style={{ fontSize: 27, lineHeight: "135%" }}>Cadeau sur mesure</h2>
                <p className="text-gray" style={{ fontSize: 14, lineHeight: "135%" }}>Vous ne trouvez pas ? Décrivez le cadeau idéal, notre équipe vous recontacte.</p>
                <a className="btn btn-outline btn-full" href="/personnalise">Je veux un cadeau personnalisé</a>
              </div>
            </main>
          </div>
        </div>
      </section>
    </>
  );
}

/* ---------- Fiche cadeau ---------- */
export function GiftPage() {
  const { id } = useParams<{ id: string }>();
  const g = gifts.find((x) => x.id === id);
  const { reserved, reserve } = useStore();
  if (!g) return <p>Cadeau introuvable. <Link to="/cadeaux">Retour au catalogue</Link></p>;
  const taken = reserved.includes(g.id);

  return (
    <section className="py-30 px-64">
      <div className="container">
        <div className="content-inner">
          <p className="text-gray" style={{ fontSize: 12 }}>Vous allez adorer</p>
          <div style={{ display: "flex", gap: 64, width: "100%", flexWrap: "wrap" }}>
            <div className="flex-col gap-16" style={{ width: 640, minWidth: 280 }}>
              <div className="photo" style={{ width: 640, height: 520 }} />
              <div className="flex-row gap-14" style={{ width: "100%", flexWrap: "wrap" }}>
                <div className="photo" style={{ width: 120, height: 100 }} />
                <div className="photo" style={{ width: 120, height: 100 }} />
              </div>
              <p className="text-gray" style={{ fontSize: 11, width: "100%" }}>3 photos disponibles</p>
            </div>

            <div className="flex-col gap-23" style={{ width: 608, minWidth: 280 }}>
              <div className={`dispo ${taken ? "dispo-reserved" : "dispo-available"}`}>{taken ? "Réservé" : "Disponible"}</div>
              <h1 className="serif-title text-dark" style={{ fontSize: 51, lineHeight: "135%", width: "100%" }}>{g.name}</h1>
              <p style={{ fontWeight: 600, fontSize: 28, color: "#C90091", lineHeight: "135%", width: "100%" }}>{price(g)}</p>
              <div className="flex items-center gap-9" style={{ width: "100%", height: 22 }}>
                <div style={{ width: 22, height: 22, border: "1.7px solid #786C74", borderRadius: "50%" }} />
                <span style={{ fontSize: 14, color: "#786C74", flex: 1 }}>{g.city}, {g.country} — {g.shop}</span>
              </div>
              <p className="text-gray" style={{ fontSize: 16, lineHeight: "135%", width: "100%" }}>{g.desc}</p>
              <p className="text-dark" style={{ fontSize: 13, lineHeight: "135%", width: "100%" }}>À vérifier auprès du marchand : disponibilité, retrait et livraison.</p>
              <label className="field-label">Quantité</label>
              <div className="input-field"><input type="text" value="1" /></div>

              <div className="flex items-start gap-12" style={{ width: "100%", flexWrap: "wrap" }}>
                <a className="btn btn-primary" href="#" style={{ width: 298 }} onClick={(e) => { e.preventDefault(); reserve(g.id); }}>Réserver ce cadeau</a>
                <a className="btn btn-outline" href="#" style={{ width: 298 }}>
                  <div style={{ width: 18, height: 18, border: "1.7px solid #C90091", borderRadius: "50%", marginRight: 8, display: "inline-block" }} />Favoris
                </a>
              </div>

              <div className="flex-col gap-14" style={{ width: "100%", background: "#FAF7F2", borderRadius: 20, padding: 20 }}>
                <div className="flex-row gap-18" style={{ width: "100%", flexWrap: "wrap" }}>
                  <div className="photo" style={{ width: 115, height: 120 }} />
                  <div className="flex-col gap-10" style={{ width: 435, minWidth: 200 }}>
                    <h3 className="serif-title text-dark" style={{ fontSize: 22, lineHeight: "135%" }}>Emballage Rosé signature</h3>
                    <p className="text-gray" style={{ fontSize: 13, lineHeight: "135%" }}>Papier mat rose poudré, ruban satin magenta.</p>
                    <p className="text-magenta" style={{ fontWeight: 600, fontSize: 13, lineHeight: "135%" }}>+ 3 000 FCFA</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------- Mes listes ---------- */
export function Lists() {
  const { reserved, reserve, release } = useStore();
  const [url, setUrl] = useState("");
  const [ext, setExt] = useState<string[]>([]);
  const add = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try { setExt([...ext, new URL(url).hostname]); setUrl(""); } catch { alert("Lien invalide"); }
  };

  return (
    <section className="py-35 px-64" style={{ paddingBottom: 65 }}>
      <div className="container">
        <div className="content-inner">
          <p className="text-gray" style={{ fontSize: 12 }}>Vos listes de cadeaux</p>
          <h1 className="serif-title text-dark" style={{ fontSize: 48, lineHeight: "135%" }}>Mes listes</h1>
          <div className="flex-row gap-34" style={{ width: "100%", flexWrap: "wrap", marginTop: 30 }}>
            <aside className="flex-col gap-23" style={{ width: 310, height: 682, minWidth: 260 }}>
              <div className="flex-col gap-10" style={{ width: "100%", height: 127, background: "#FCECF6", borderRadius: 18, padding: 22 }}>
                <p className="text-magenta" style={{ fontWeight: 600, fontSize: 12, lineHeight: "135%" }}>Liste sélectionnée</p>
                <h2 className="serif-title text-dark" style={{ fontSize: 23, lineHeight: "135%" }}>Anniversaire Aïcha</h2>
                <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>4 cadeaux • 2 réservés</p>
              </div>
              <div className="flex-col gap-17" style={{ width: "100%", height: 532, background: "#FAF7F2", borderRadius: 18, padding: 22 }}>
                <h2 className="serif-title text-dark" style={{ fontSize: 24, lineHeight: "135%" }}>Créer une liste</h2>
                <label className="field-label">Titre de la liste</label>
                <div className="input-field"><input type="text" placeholder="Nom de la liste" value="" onChange={() => {}} /></div>
                <label className="field-label">Description</label>
                <div className="input-field" style={{ minHeight: 82, height: 82 }}><textarea value="" onChange={() => {}} style={{ border: "none", outline: "none", background: "transparent", flex: 1, fontSize: 13, color: "#786C74", resize: "none" }} /></div>
                <label className="field-label">Occasion</label>
                <div className="input-field"><input type="text" placeholder="Anniversaire" value="" onChange={() => {}} /></div>
                <a className="btn btn-outline btn-full" href="#">Créer la liste</a>
                <p className="text-gray" style={{ fontSize: 11, lineHeight: "135%", width: "100%" }}>Une liste par événement.</p>
                <a className="btn btn-primary btn-full" href="#">+ Nouvelle liste</a>
              </div>
            </aside>

            <main className="flex-1 flex-col gap-23" style={{ width: 968, minWidth: 280 }}>
              <div className="flex-row gap-26" style={{ width: "100%", height: 190 }}>
                <div className="photo" style={{ width: 250, height: 190 }} />
                <div className="flex-col gap-14" style={{ width: 692, flex: 1 }}>
                  <h1 className="serif-title text-dark" style={{ fontSize: 37, lineHeight: "135%" }}>Anniversaire Aïcha</h1>
                  <p className="text-gray" style={{ fontSize: 14, lineHeight: "135%" }}>Cadeaux pour célébrer Aïcha.</p>
                  <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>Créée le 12 juin 2026</p>
                  <p className="text-magenta" style={{ fontWeight: 600, fontSize: 12, lineHeight: "135%" }} onClick={() => { }}>Partager la liste →</p>
                </div>
              </div>

              <div className="flex-col gap-13" style={{ width: "100%", height: 180, background: "#FAF7F2", borderRadius: 18, padding: 22 }}>
                <p style={{ fontWeight: 600, fontSize: 19, color: "#30232C", lineHeight: "135%" }}>Ajouter un produit</p>
                <div className="flex items-end gap-14" style={{ width: "100%", flexWrap: "wrap" }}>
                  <div className="flex-col gap-7" style={{ width: 740, flex: 1, minWidth: 200 }}>
                    <label className="field-label">URL marchand</label>
                    <div className="input-field"><input type="text" placeholder="https://exemple.com/produit" style={{ border: "none", outline: "none", background: "transparent", flex: 1, fontSize: 13, color: "#786C74" }} /></div>
                  </div>
                  <a className="btn btn-primary btn-full" style={{ width: 170, height: 48 }} href="#">Ajouter</a>
                </div>
                <p className="text-gray" style={{ fontSize: 11, lineHeight: "135%", width: "100%" }}>Collez un lien (site marchand...) pour ajouter un cadeau externe.</p>
              </div>

              <p className="text-gray" style={{ fontSize: 11, lineHeight: "135%", width: "100%" }}>5 cadeaux dans cette liste</p>
              <p className="text-gray" style={{ fontSize: 11, lineHeight: "135%", width: "100%" }}>Dernière mise à jour : il y a 2 jours</p>

              <div className="flex items-start justify-between" style={{ width: "100%", height: 19 }}>
                <p style={{ fontWeight: 600, fontSize: 14, color: "#30232C" }}>Cadeaux</p>
                <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>Statut</p>
              </div>

              {gifts.slice(0, 4).map((g) => {
                const t = reserved.includes(g.id);
                return (
                  <div key={g.id} className="flex items-start gap-20" style={{ width: "100%", height: 111, borderBottom: "1px solid #E9E1E5", padding: "13px 0", flexWrap: "wrap" }}>
                    <div className="photo" style={{ width: 90, height: 85 }} />
                    <div className="flex-col gap-7" style={{ width: 721, flex: 1, minWidth: 200 }}>
                      <p style={{ fontWeight: 600, fontSize: 14, color: "#30232C" }}>{g.name}</p>
                      <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>{g.shop} — {g.city}</p>
                    </div>
                    <div className={`dispo ${t ? "dispo-reserved" : "dispo-available"}`}>{t ? "Réservé" : "Disponible"}</div>
                    <div style={{ width: 22, height: 22, border: "1.7px solid #30232C", borderRadius: "50%" }} />
                  </div>
                );
              })}

              <div className="flex-col gap-14" style={{ width: "100%", height: 193, background: "#FCECF6", borderRadius: 18, padding: 23 }}>
                <h2 className="serif-title text-dark" style={{ fontSize: 24, lineHeight: "135%" }}>Partager la liste</h2>
                <p style={{ fontSize: 13, color: "#30232C" }}>Envoyez le lien à vos proches pour qu'ils réservent un cadeau.</p>
                <div className="flex items-end gap-14" style={{ width: "100%", flexWrap: "wrap" }}>
                  <div className="flex-col gap-7" style={{ width: 728, flex: 1, minWidth: 200 }}>
                    <label className="field-label">Lien à partager</label>
                    <div className="input-field"><input type="text" value="cadoter.com/l/aicha-anniversaire" readOnly style={{ border: "none", outline: "none", background: "transparent", flex: 1, fontSize: 13, color: "#786C74" }} /></div>
                  </div>
                  <a className="btn btn-primary btn-full" style={{ width: 180, height: 48 }} href="#">Copier</a>
                </div>
              </div>
            </main>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ---------- Liste partagée (invité) ---------- */
export function Shared() {
  const [ok, setOk] = useState(false);
  const [c, setC] = useState("");
  const { reserved } = useStore();
  if (!ok) return (
    <form className="box" onSubmit={(e) => { e.preventDefault(); c === "1234" ? setOk(true) : alert("Code incorrect"); }}>
      <h1>Cette liste est protégée</h1>
      <input placeholder="Code d'accès" value={c} onChange={(e) => setC(e.target.value)} />
      <button className="btn">Continuer</button>
    </form>
  );
  return (
    <>
      <h1>La liste d'Aïcha</h1>
      <p>Choisissez un cadeau à réserver. Un cadeau par personne.</p>
      <div className="grid">{gifts.slice(0, 4).map((g) => <Card key={g.id} g={g} />)}</div>
      {reserved.length > 0 && <p>{reserved.length} cadeau(x) déjà réservé(s).</p>}
    </>
  );
}

/* ---------- Assistante IA ---------- */
export function Assistant() {
  const [f, setF] = useState({ event: occasions[0], sex: "Femme", age: 30, rel: "Ami(e)", budget: 15000 });
  const [res, setRes] = useState<Gift[] | null>(null);
  const go = (e: FormEvent) => { e.preventDefault(); setRes(gifts.filter((g) => g.price <= f.budget).slice(0, 3)); };

  return (
    <section className="py-38 px-64" style={{ paddingBottom: 65 }}>
      <div className="container">
        <div className="content-inner">
          <p className="text-gray" style={{ fontSize: 12, fontWeight: 600, color: "#C90091" }}>Critères du cadeau</p>
          <h1 className="serif-title text-dark" style={{ fontSize: 51, lineHeight: "135%", width: "100%" }}>Votre recherche personnalisée</h1>
          <p className="text-gray" style={{ fontSize: 17, lineHeight: "135%", width: "100%" }}>Décrivez la personne, l'événement et le budget. L'assistante vous propose des cadeaux avec un « Pourquoi ce cadeau ? ».</p>

          <div className="flex-col gap-16" style={{ width: "100%", marginTop: 38 }}>
            <label className="field-label">Type d'événement *</label>
            <div className="input-field"><select value={f.event} onChange={(e) => setF({ ...f, event: e.target.value })}>{occasions.map((o) => <option key={o}>{o}</option>)}</select></div>
            <label className="field-label">Sexe *</label>
            <div className="input-field"><select value={f.sex} onChange={(e) => setF({ ...f, sex: e.target.value })}><option>Femme</option><option>Homme</option></select></div>
            <label className="field-label">Âge *</label>
            <div className="input-field"><input type="number" min={0} value={f.age} onChange={(e) => setF({ ...f, age: +e.target.value })} /></div>
            <label className="field-label">Lien avec la personne *</label>
            <div className="input-field"><input value={f.rel} onChange={(e) => setF({ ...f, rel: e.target.value })} /></div>
            <label className="field-label">Budget max *</label>
            <div className="input-field"><input type="number" value={f.budget} onChange={(e) => setF({ ...f, budget: +e.target.value })} /></div>
            <label className="field-label">Infos libres</label>
            <div className="input-field" style={{ minHeight: 82, height: 82 }}><textarea value="" onChange={() => {}} style={{ border: "none", outline: "none", background: "transparent", flex: 1, fontSize: 13, color: "#786C74", resize: "none" }} /></div>
            <a className="btn btn-primary btn-full" href="#">Obtenir des suggestions</a>
          </div>

          <div style={{ width: "100%", marginTop: 30 }}>
            <p className="text-gray" style={{ fontSize: 11, lineHeight: "135%" }}>Avertissement : ne saisissez pas d'informations personnelles sensibles dans l'IA.</p>
          </div>

          {res && (
            res.length ? (
              <>
                <h2 className="serif-title text-dark" style={{ fontSize: 28, marginTop: 24 }}>Nos idées</h2>
                <div className="grid">{res.map((g) => (
                  <div key={g.id}>
                    <Card g={g} />
                    <p className="note" style={{ marginTop: 8 }}>Pourquoi ce cadeau ? Il correspond à votre budget et convient pour : {f.event.toLowerCase()}.</p>
                  </div>
                ))}</div>
              </>
            ) : (
              <p>Aucune idée à ce budget. Augmentez-le.</p>
            )
          )}
        </div>
      </div>
    </section>
  );
}

/* ---------- Cadeau personnalisé ---------- */
export function Custom() {
  const [sent, setSent] = useState(false);
  if (sent) return <p className="box">Demande envoyée. L'équipe vous recontacte par téléphone.</p>;
  return (
    <>
      <h1>Une personne unique. Des idées à son image.</h1>
      <form className="box form" onSubmit={(e) => { e.preventDefault(); setSent(true); }}>
        <label>Nom<input required /></label>
        <label>Téléphone<input type="tel" required /></label>
        <label>Budget<input type="number" required /></label>
        <label>Décrivez la personne et l'occasion<textarea required /></label>
        <label>
          Emballage<select>
            <option>Rosé signature</option>
            <option>Naturel délicat</option>
            <option>Ciel de douceur</option>
            <option>Sans emballage</option>
          </select>
        </label>
        <button className="btn">Envoyer ma demande</button>
      </form>
    </>
  );
}

/* ---------- Inspirations ---------- */
export const Inspirations = () => (
  <>
    <section className="py-35 px-64">
      <div className="container">
        <div className="content-inner">
          <p className="text-gray" style={{ fontSize: 12 }}>Vous allez adorer</p>
          <h1 className="serif-title text-dark" style={{ fontSize: 52, lineHeight: "135%", width: "1093px" }}>Journal & inspirations</h1>
          <p className="text-gray" style={{ fontSize: 17, lineHeight: "135%", width: "1093px" }}>Trouvez l'inspiration pour chaque moment de vie.</p>
        </div>
      </div>
    </section>

    <section style={{ padding: "0 64px" }}>
      <div className="container">
        <div className="content-inner" style={{ width: "100%", marginTop: 28 }}>
          <div className="flex-row gap-10" style={{ width: "100%", flexWrap: "wrap", marginBottom: 28 }}>
            {["Tous", "Inspirations", "Conseils", "Fêtes"].map((c) => (
              <div key={c} className="filtre filtre-default">{c}</div>
            ))}
          </div>
          <div className="flex-row gap-38" style={{ width: "100%", flexWrap: "wrap" }}>
            {articles.map((a) => (
              <article key={a} className="flex-col gap-12" style={{ width: 469, height: 317, minWidth: 300 }}>
                <div className="photo" style={{ width: 469, height: 215 }} />
                <p className="text-magenta" style={{ fontWeight: 600, fontSize: 10, lineHeight: "135%" }}>Article</p>
                <h3 className="serif-title text-dark" style={{ fontSize: 27, lineHeight: "135%" }}>{a}</h3>
                <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>Découvrez cette inspiration.</p>
                <p className="text-magenta" style={{ fontWeight: 600, fontSize: 13, lineHeight: "135%" }}>Lire l'article →</p>
              </article>
            ))}
          </div>
        </div>
      </div>
    </section>
  </>
);

/* ---------- Compte ---------- */
export function Account() {
  const [lang, setLang] = useState("FR");
  return (
    <section className="py-35 px-64" style={{ paddingBottom: 65 }}>
      <div className="container">
        <div className="content-inner" style={{ width: "100%", height: "1236px" }}>
          <div className="flex-row gap-40" style={{ width: "1312px", height: 143 }}>
            <div className="flex-col gap-17" style={{ width: "1093px", flex: 1 }}>
              <p className="kicker serif text-magenta">Votre espace personnel</p>
              <h1 className="serif-title text-dark" style={{ fontSize: 52, lineHeight: "135%", width: "1093px" }}>Gérez vos listes et vos cadeaux</h1>
              <p className="text-gray" style={{ fontSize: 17, lineHeight: "135%", width: "1093px" }}>Créez, modifiez et partagez vos listes de cadeaux. Suivez les réservations et recevez vos dépôts Mobile Money.</p>
            </div>
            <div className="filtre filtre-active" style={{ width: 179, height: 34 }}>Mon compte</div>
          </div>

          <div className="flex-row gap-38" style={{ width: "1312px" }}>
            <div className="articles flex-col gap-28" style={{ width: "964px", flex: 1 }}>
              <div className="categories flex-row gap-10" style={{ width: "964px", height: 34 }}>
                <div className="filtre filtre-active">Tous</div>
                <div className="filtre filtre-default">Inspirations</div>
                <div className="filtre filtre-default">Conseils</div>
                <div className="filtre filtre-default">Fêtes</div>
              </div>
              <div className="photo" style={{ width: "964px", height: 345 }} />
              <p className="text-magenta" style={{ fontWeight: 600, fontSize: 11, lineHeight: "135%", width: "964px" }}>Fête des pères</p>
              <h2 className="serif-title text-dark" style={{ fontSize: 36, lineHeight: "135%", width: "964px" }}>Un moment rien qu'à lui</h2>
              <p className="text-gray" style={{ fontSize: 14, lineHeight: "135%", width: "964px" }}>Des idées pour célébrer votre père avec attention.</p>
              <p className="text-magenta" style={{ fontWeight: 600, fontSize: 13, lineHeight: "135%", width: "964px" }}>Lire l'article →</p>
              <div className="alire flex-row gap-26" style={{ width: "964px", height: 317 }}>
                {articles.slice(0, 2).map((a) => (
                  <article key={a} className="flex-col gap-12" style={{ width: 469, height: 317 }}>
                    <div className="photo" style={{ width: 469, height: 215 }} />
                    <p className="text-magenta" style={{ fontWeight: 600, fontSize: 10, lineHeight: "135%" }}>Catégorie</p>
                    <h3 className="serif-title text-dark" style={{ fontSize: 27, lineHeight: "135%" }}>{a}</h3>
                    <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%" }}>Découvrez cette inspiration.</p>
                  </article>
                ))}
              </div>
            </div>

            <aside className="flex-col gap-18" style={{ width: 310, background: "#FCECF6", borderRadius: 20, padding: 23 }}>
              <h2 className="serif-title text-dark" style={{ fontSize: 25, lineHeight: "135%", width: "264px" }}>Mon compte</h2>
              <p className="text-gray" style={{ fontSize: 12, lineHeight: "135%", width: "264px" }}>Gérez votre profil, vos listes et vos préférences.</p>
              <nav className="flex-col" style={{ width: "264px", height: 470 }}>
                {[
                  { label: "Mon profil", icon: "👤" },
                  { label: "Mes listes", icon: "📋" },
                  { label: "Historique", icon: "🕒" },
                  { label: "Favoris", icon: "❤️" },
                  { label: "Aide / FAQ", icon: "❓" },
                  { label: "Contact", icon: "✉️" },
                  { label: "Langue : Français", icon: "🌐" },
                  { label: "Confidentialité", icon: "🛡️" },
                  { label: "Déconnexion", icon: "🚪", magenta: true },
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-10" style={{ width: "264px", height: 47, borderBottom: "1px solid #E9E1E5" }}>
                    <div style={{ width: 17, height: 17, border: `1.7px solid ${item.magenta ? "#C90091" : "#786C74"}`, borderRadius: "50%" }} />
                    <span style={{ width: "214px", fontSize: 12, lineHeight: "135%", color: item.magenta ? "#C90091" : "#30232C", flex: 1 }}>{item.label}</span>
                    <div style={{ width: 13, height: 13, border: "1.7px solid #30232C" }} />
                  </div>
                ))}
              </nav>
              <p style={{ width: "264px", fontSize: 11, lineHeight: "135%", color: "#786C74" }}>CADOTER — Vos belles attentions, simplement.</p>
            </aside>
          </div>
        </div>
      </div>
    </section>
  );
}
