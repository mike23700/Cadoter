import { Link, NavLink, Route, Routes } from "react-router-dom";
import * as P from "./pages";
const WA = "https://wa.me/237600000000?text=Bonjour%20CADOTER"; // numéro à remplacer
const links: [string, string][] = [["/cadeaux", "Cadeaux"], ["/listes", "Mes listes"], ["/assistante", "Assistante"], ["/inspirations", "Inspirations"], ["/compte", "Compte"]];
export default function App() {
  return (<>
    <header className="top"><Link to="/" className="logo">cadoter</Link>
      <nav>{links.map(([to, l]) => <NavLink key={to} to={to}>{l}</NavLink>)}</nav></header>
    <main>
      <Routes>
        <Route path="/" element={<P.Home />} />
        <Route path="/cadeaux" element={<P.Catalog />} />
        <Route path="/cadeaux/:id" element={<P.GiftPage />} />
        <Route path="/listes" element={<P.Lists />} />
        <Route path="/l/:code" element={<P.Shared />} />
        <Route path="/assistante" element={<P.Assistant />} />
        <Route path="/personnalise" element={<P.Custom />} />
        <Route path="/inspirations" element={<P.Inspirations />} />
        <Route path="/compte" element={<P.Account />} />
      </Routes>
    </main>
    <footer>© CADOTER · <Link to="/personnalise">Cadeau personnalisé</Link></footer>
    <a className="wa" href={WA} target="_blank" rel="noreferrer" aria-label="Écrire sur WhatsApp">WhatsApp</a>
  </>);
}
