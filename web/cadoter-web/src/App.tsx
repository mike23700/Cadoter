import { useEffect, useRef, useState } from "react";
import { Link, NavLink, Route, Routes, useLocation, useNavigate } from "react-router-dom";
import { firstName } from "./api";
import { Icon, IconName } from "./icons";
import { RequireAuth, useStore } from "./store";
import Home from "./pages/Home";
import Catalog from "./pages/Catalog";
import GiftPage from "./pages/GiftPage";
import Lists from "./pages/Lists";
import Shared from "./pages/Shared";
import Assistant from "./pages/Assistant";
import Custom from "./pages/Custom";
import Inspirations, { ArticlePage } from "./pages/Inspirations";
import Favorites from "./pages/Favorites";
import MyOrders from "./pages/MyOrders";
import Order from "./pages/Order";
import Admin from "./pages/Admin";
import { Login, Signup } from "./pages/Auth";

const nav: [string, string][] = [
  ["/", "Découvrir"],
  ["/cadeaux", "Cadeaux"],
  ["/listes", "Mes listes"],
  ["/assistante", "Assistante IA"],
  ["/inspirations", "Inspirations"],
];

const accountLinks: [IconName, string, string, string?][] = [
  ["list", "Mes listes", "/listes"],
  ["clock", "Mon historique", "/commandes"],
  ["heart", "Mes favoris", "/favoris"],
  ["help", "FAQ", "/inspirations"],
  ["mail", "Nous contacter", "/personnalise"],
  ["share", "Nos réseaux sociaux", "/inspirations"],
  ["globe", "Langue", "/", "Français"],
  ["shield", "Politique", "/"],
];

function AccountMenu({ onClose }: { onClose: () => void }) {
  const { user, logout, notify } = useStore();
  const nav = useNavigate();
  if (!user) return null;
  return (
    <div className="account-menu" role="menu">
      <h3>Bonjour, {firstName(user)}.</h3>
      <p className="mail">{user.email}</p>
      <div className="menu-list">
        {user.role === "admin" && (
          <Link to="/admin" onClick={onClose} role="menuitem"><Icon name="shield" size={17} /><span className="grow">Administration</span><Icon name="chevron" size={14} /></Link>
        )}
        {accountLinks.map(([icon, label, to, extra]) => (
          <Link key={label} to={to} onClick={onClose} role="menuitem">
            <Icon name={icon} size={17} />
            <span className="grow">{label}</span>
            {extra && <span className="extra">{extra}</span>}
            <Icon name="chevron" size={14} />
          </Link>
        ))}
        <button onClick={async () => { onClose(); await logout(); notify("À bientôt !"); nav("/"); }} role="menuitem" className="danger">
          <Icon name="logout" size={17} />
          <span className="grow">Se déconnecter</span>
          <Icon name="chevron" size={14} />
        </button>
      </div>
      <p className="foot">Un espace pour retrouver vos envies et préparer les prochaines attentions.</p>
    </div>
  );
}

function Header() {
  const { favorites, user } = useStore();
  const [menu, setMenu] = useState(false);
  const [mobileNav, setMobileNav] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const { pathname } = useLocation();

  useEffect(() => { setMenu(false); setMobileNav(false); }, [pathname]);
  useEffect(() => {
    if (!menu) return;
    const close = (e: MouseEvent) => { if (!ref.current?.contains(e.target as Node)) setMenu(false); };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setMenu(false);
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", esc);
    return () => { document.removeEventListener("mousedown", close); document.removeEventListener("keydown", esc); };
  }, [menu]);

  return (
    <header className="header">
      <div className="wrap">
        <Link to="/" className="logo" aria-label="CADOTER, accueil"><img src="/img/logo.png" alt="cadoter.com" /></Link>
        <nav className={`nav ${mobileNav ? "open" : ""}`}>
          {nav.map(([to, label]) => <NavLink key={to} to={to} end={to === "/"}>{label}</NavLink>)}
        </nav>
        <div className="header-actions" ref={ref}>
          <Link to="/favoris" className="icon-btn" aria-label="Mes favoris">
            <Icon name="heart" size={22} />
            {favorites.length > 0 && <span className="count">{favorites.length}</span>}
          </Link>
          {user ? (
            <>
              <button className="hello" aria-expanded={menu} onClick={() => setMenu(m => !m)}>Bonjour, {firstName(user)}</button>
              <button className="icon-btn account-icon" aria-label="Mon compte" onClick={() => setMenu(m => !m)}><Icon name="user" /></button>
            </>
          ) : (
            <>
              <Link to="/connexion" className="hello">Se connecter</Link>
              <Link to="/connexion" className="icon-btn account-icon" aria-label="Se connecter"><Icon name="user" /></Link>
            </>
          )}
          <button className="icon-btn burger" aria-label="Menu" onClick={() => setMobileNav(o => !o)}>
            <Icon name={mobileNav ? "close" : "menu"} />
          </button>
          {menu && <AccountMenu onClose={() => setMenu(false)} />}
        </div>
      </div>
    </header>
  );
}

function Footer() {
  const { pathname } = useLocation();
  const bottom = (
    <div className="footer-bar">
      <div className="wrap">
        <span>© CADOTER · Maquette de démonstration · Produits, prix et lieux présentés à titre illustratif.</span>
        {pathname !== "/" && (
          <nav>
            <Link to="/inspirations">FAQ</Link><Link to="/personnalise">Nous contacter</Link><Link to="/">Politique</Link><span>Français</span>
          </nav>
        )}
      </div>
    </div>
  );
  if (pathname !== "/") return <footer className="footer">{bottom}</footer>;
  return (
    <footer className="footer">
      <div className="footer-big">
        <div className="wrap">
          <div className="brand"><img src="/img/logo.png" alt="cadoter.com" /><p>De petites attentions, de grands liens.</p></div>
          <div><h4>Explorer</h4><ul><li><Link to="/cadeaux">Cadeaux</Link></li><li><Link to="/listes">Mes listes</Link></li><li><Link to="/inspirations">Inspirations</Link></li></ul></div>
          <div><h4>À vos côtés</h4><ul><li><Link to="/inspirations">FAQ</Link></li><li><Link to="/personnalise">Nous contacter</Link></li><li><Link to="/inspirations">Nos réseaux sociaux</Link></li></ul></div>
          <div><h4>Votre espace</h4><ul><li><Link to="/listes">Mon espace</Link></li><li>Langue : Français</li><li><Link to="/">Politique de confidentialité</Link></li></ul></div>
        </div>
      </div>
      {bottom}
    </footer>
  );
}

export default function App() {
  const { pathname } = useLocation();
  const { toast } = useStore();
  useEffect(() => window.scrollTo(0, 0), [pathname]);

  if (pathname.startsWith("/admin")) {
    return (
      <>
        <Routes>
          <Route path="/admin/connexion" element={<Login admin />} />
          <Route path="/admin/*" element={<RequireAuth admin><Admin /></RequireAuth>} />
        </Routes>
        {toast && <div className="toast" role="status">{toast}</div>}
      </>
    );
  }

  return (
    <>
      <Header />
      <main>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/cadeaux" element={<Catalog />} />
          <Route path="/cadeaux/:id" element={<GiftPage />} />
          <Route path="/listes" element={<RequireAuth><Lists /></RequireAuth>} />
          <Route path="/commander/:slug" element={<Order />} />
          <Route path="/connexion" element={<Login />} />
          <Route path="/inscription" element={<Signup />} />
          <Route path="/commandes" element={<RequireAuth><MyOrders /></RequireAuth>} />
          <Route path="/l/:code" element={<Shared />} />
          <Route path="/assistante" element={<Assistant />} />
          <Route path="/personnalise" element={<Custom />} />
          <Route path="/inspirations" element={<Inspirations />} />
          <Route path="/inspirations/:slug" element={<ArticlePage />} />
          <Route path="/favoris" element={<RequireAuth><Favorites /></RequireAuth>} />
          <Route path="*" element={<div className="wrap"><div className="empty" style={{ marginTop: 60 }}>Page introuvable. <Link className="link" to="/">Retour à l'accueil</Link></div></div>} />
        </Routes>
      </main>
      <Footer />
      {toast && <div className="toast" role="status">{toast}</div>}
    </>
  );
}
