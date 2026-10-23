import { createContext, DependencyList, Fragment, ReactNode, useCallback, useContext, useEffect, useRef, useState } from "react";
import { Navigate, useLocation } from "react-router-dom";
import { api, ApiError, Gift, Meta, token, User } from "./api";
import { getLang, hasStoredLang, Lang, setLang, t } from "./i18n";

type Store = {
  user: User | null;
  ready: boolean; // session vérifiée au démarrage
  login: (login: string, password: string) => Promise<User>;
  register: (data: { name: string; phone: string; email: string; password: string; password_confirmation: string; terms: boolean }) => Promise<User>;
  updateUser: (data: Pick<User, "name" | "email" | "language"> & { phone: string | null }) => Promise<User>;
  updatePassword: (data: { current_password: string; password: string; password_confirmation: string }) => Promise<void>;
  logout: () => Promise<void>;
  meta: Meta | null;
  favorites: number[];
  toggleFavorite: (gift: Gift) => Promise<void>;
  toast: string | null;
  notify: (msg: string) => void;
  lang: Lang;
  setLanguage: (l: Lang) => void;
};

const Ctx = createContext<Store | null>(null);

export function StoreProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);
  const [meta, setMeta] = useState<Meta | null>(null);
  const [favorites, setFavorites] = useState<number[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const [lang, setLangState] = useState<Lang>(getLang);
  const timer = useRef<number>();

  const notify = useCallback((msg: string) => {
    setToast(msg);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setToast(null), 3000);
  }, []);

  const loadFavorites = useCallback(() => {
    api<Gift[]>("/favorites").then(g => setFavorites(g.map(x => x.id))).catch(() => setFavorites([]));
  }, []);

  useEffect(() => {
    api<Meta>("/meta").then(setMeta).catch(() => setMeta(null));
    if (!token.get()) { setReady(true); return; }
    api<User>("/me")
      .then(u => {
        // Sans choix enregistré sur cet appareil, on reprend la langue du compte
        if (!hasStoredLang() && (u.language === "fr" || u.language === "en") && u.language !== getLang()) { setLang(u.language); setLangState(u.language); }
        setUser(u);
        loadFavorites();
      })
      .catch(() => token.set(null))
      .finally(() => setReady(true));
  }, [loadFavorites]);

  const startSession = (res: { token: string; user: User }) => {
    token.set(res.token);
    // La langue affichée à la connexion devient celle du compte
    if (res.user.language !== getLang()) {
      api<User>("/me", { method: "PUT", body: { language: getLang() } }).catch(() => undefined);
      res.user = { ...res.user, language: getLang() };
    }
    setUser(res.user);
    loadFavorites();
    return res.user;
  };

  const store: Store = {
    user, ready, meta, favorites, toast, notify, lang,
    setLanguage: l => {
      if (l === lang) return;
      setLang(l);
      setLangState(l);
      if (user) {
        setUser({ ...user, language: l });
        api("/me", { method: "PUT", body: { language: l } }).catch(() => undefined);
      }
    },
    login: async (login, password) => startSession(await api("/login", { body: { login, password } })),
    register: async data => startSession(await api("/register", { body: { ...data, language: getLang() } })),
    updateUser: async data => {
      const updatedUser = await api<User>("/me", { method: "PUT", body: data });
      setUser(updatedUser);
      if (updatedUser.language === "fr" || updatedUser.language === "en") {
        setLang(updatedUser.language);
        setLangState(updatedUser.language);
      }
      return updatedUser;
    },
    updatePassword: async data => {
      await api<{ message: string }>("/me/password", { method: "PUT", body: data });
    },
    logout: async () => {
      await api("/logout", { method: "POST" }).catch(() => undefined);
      token.set(null);
      setUser(null);
      setFavorites([]);
    },
    toggleFavorite: async gift => {
      if (!user) { notify(t("Connectez-vous pour enregistrer vos favoris.")); return; }
      const { favorite } = await api<{ favorite: boolean }>(`/favorites/${gift.id}`, { method: "POST" });
      setFavorites(f => (favorite ? [...f, gift.id] : f.filter(id => id !== gift.id)));
      notify(favorite ? t("Ajouté à vos favoris.") : t("Retiré de vos favoris."));
    },
  };

  // key : changer de langue réaffiche toute l'application dans la nouvelle langue
  return <Ctx.Provider value={store}><Fragment key={lang}>{children}</Fragment></Ctx.Provider>;
}

export function useStore() {
  const s = useContext(Ctx);
  if (!s) throw new Error("useStore doit être utilisé dans <StoreProvider>");
  return s;
}

/** Chargement d'une ressource de l'API avec états de chargement / erreur. */
export function useApi<T>(path: string | null, deps: DependencyList = []) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<ApiError | null>(null);
  const [loading, setLoading] = useState(!!path);
  const [n, setN] = useState(0);

  useEffect(() => {
    if (!path) { setLoading(false); return; }
    let alive = true;
    setLoading(true);
    setError(null);
    api<T>(path)
      .then(d => alive && setData(d))
      .catch(e => alive && setError(e instanceof ApiError ? e : new ApiError(String(e), 0)))
      .finally(() => alive && setLoading(false));
    return () => { alive = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [path, n, ...deps]);

  return { data, setData, error, loading, reload: () => setN(x => x + 1) };
}

/** Redirige vers /connexion si l'utilisateur n'est pas connecté (ou pas admin). */
export function RequireAuth({ children, admin = false }: { children: ReactNode; admin?: boolean }) {
  const { user, ready } = useStore();
  const loc = useLocation();
  if (!ready) return <div className="wrap"><p className="loading">{t("Chargement…")}</p></div>;
  if (!user) return <Navigate to={`${admin ? "/admin/connexion" : "/connexion"}?next=${encodeURIComponent(loc.pathname + loc.search)}`} replace />;
  if (admin && !["admin", "partner"].includes(user.role)) return <div className="wrap"><div className="empty" style={{ marginTop: 60 }}>{t("Accès réservé aux administrateurs et boutiques partenaires.")}</div></div>;
  return <>{children}</>;
}
