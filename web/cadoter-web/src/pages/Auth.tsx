import { FormEvent, useState } from "react";
import { Link, Navigate, useNavigate, useSearchParams } from "react-router-dom";
import { ApiError } from "../api";
import { ErrorBox, Field, fieldError } from "../components";
import { Icon } from "../icons";
import { t } from "../i18n";
import { useStore } from "../store";

/** Redirection sûre après connexion (chemins internes uniquement). */
const useNext = (fallback = "/") => {
  const [params] = useSearchParams();
  const next = params.get("next") ?? "";
  return next.startsWith("/") && !next.startsWith("//") ? next : fallback;
};

export function Login({ admin = false }: { admin?: boolean }) {
  const { login, user } = useStore();
  const nav = useNavigate();
  const next = useNext(admin ? "/admin" : "/");
  const [form, setForm] = useState({ login: "", password: "" });
  const [show, setShow] = useState(false);
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  if (user && (!admin || ["admin", "partner"].includes(user.role))) return <Navigate to={next} replace />;

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setErr(null);
    try {
      const u = await login(form.login, form.password);
      if (admin && !["admin", "partner"].includes(u.role)) throw new ApiError(t("Ce compte n'a pas accès à cet espace."), 403);
      nav(next, { replace: true });
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className={`wrap auth ${admin ? "auth-admin" : ""}`}>
      {!admin && <img className="photo auth-photo" src="/img/emballage-rose.jpg" alt="" />}
      <form className="auth-card" onSubmit={submit}>
        {admin && <p className="eyebrow">{t("Administration CADOTER")}</p>}
        <h1 className="display">{admin ? t("Espace administrateur.") : t("Heureux de vous retrouver.")}</h1>
        <p className="muted">{admin ? t("Gérez le catalogue CADOTER ou votre boutique partenaire.") : t("Vos envies et vos prochaines attentions vous attendent.")}</p>
        <Field label={t("Email / Téléphone")} error={fieldError(err, "login")}>
          <input className="input" autoComplete="username" required value={form.login} onChange={e => setForm({ ...form, login: e.target.value })} placeholder={t("aicha@exemple.com")} />
        </Field>
        <Field label={t("Mot de passe")} error={fieldError(err, "password")}>
          <div className="input-wrap">
            <input className="input" type={show ? "text" : "password"} autoComplete="current-password" required value={form.password} onChange={e => setForm({ ...form, password: e.target.value })} placeholder="••••••••••" />
            <button type="button" className="input-action" onClick={() => setShow(s => !s)}>{show ? t("Masquer") : t("Afficher")}</button>
          </div>
        </Field>
        {!admin && <a className="link" style={{ fontWeight: 400 }} href={`mailto:contact@cadoter.com?subject=${encodeURIComponent(t("Mot de passe oublié"))}`}>{t("Mot de passe oublié ?")}</a>}
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Connexion…") : t("Me connecter")}</button>
        {!admin && <Link to={`/inscription${next !== "/" ? `?next=${encodeURIComponent(next)}` : ""}`} className="btn btn-outline btn-block">{t("Créer un compte")}</Link>}
      </form>
    </div>
  );
}

export function Signup() {
  const { register, user } = useStore();
  const nav = useNavigate();
  const next = useNext();
  const [form, setForm] = useState({ name: "", phone: "", email: "", password: "", password_confirmation: "", terms: false });
  const [err, setErr] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);

  if (user) return <Navigate to={next} replace />;
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (form.password !== form.password_confirmation) {
      return setErr(new ApiError("", 422, { password_confirmation: [t("Les mots de passe ne correspondent pas.")] }));
    }
    setBusy(true);
    setErr(null);
    try {
      await register(form);
      nav(next, { replace: true });
    } catch (e) {
      setErr(e);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="wrap auth">
      <img className="photo auth-photo" src="/img/hero-home.jpg" alt="" />
      <form className="auth-card" onSubmit={submit}>
        <h1 className="display">{t("Bienvenue dans les belles attentions.")}</h1>
        <Field label={t("Nom *")} error={fieldError(err, "name")}><input className="input" autoComplete="name" required value={form.name} onChange={set("name")} placeholder="Aïcha Koné" /></Field>
        <Field label={t("Téléphone *")} error={fieldError(err, "phone")}><input className="input" type="tel" autoComplete="tel" required value={form.phone} onChange={set("phone")} placeholder="+225 07 00 00 00 00" /></Field>
        <Field label={t("Email *")} error={fieldError(err, "email")}><input className="input" type="email" autoComplete="email" required value={form.email} onChange={set("email")} placeholder={t("aicha@exemple.com")} /></Field>
        <Field label={t("Mot de passe *")} error={fieldError(err, "password")}><input className="input" type="password" autoComplete="new-password" minLength={8} required value={form.password} onChange={set("password")} placeholder="••••••••••" /></Field>
        <Field label={t("Confirmer le mot de passe *")} error={fieldError(err, "password_confirmation")}><input className="input" type="password" autoComplete="new-password" required value={form.password_confirmation} onChange={set("password_confirmation")} placeholder="••••••••••" /></Field>
        <p className="note">{t("8 caractères minimum. * Champs obligatoires.")}</p>
        <label className="check">
          <input type="checkbox" checked={form.terms} onChange={e => setForm({ ...form, terms: e.target.checked })} required />
          <span className="box"><Icon name="check" size={14} /></span>
          <span>{t("J'accepte les conditions d'utilisation et la politique de confidentialité.")}</span>
        </label>
        {fieldError(err, "terms") && <em className="field-error">{fieldError(err, "terms")}</em>}
        <ErrorBox error={err instanceof ApiError && !Object.keys(err.errors).length ? err : null} />
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? t("Création…") : t("Créer mon compte")}</button>
        <p className="small" style={{ textAlign: "center" }}>{t("Déjà inscrit·e ?")} <Link to={`/connexion${next !== "/" ? `?next=${encodeURIComponent(next)}` : ""}`} className="price">{t("Se connecter")}</Link></p>
      </form>
    </div>
  );
}
