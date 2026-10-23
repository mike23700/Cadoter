import { FormEvent, useState } from "react";
import { ApiError } from "../api";
import { Breadcrumb, ErrorBox, Field, fieldError } from "../components";
import { Icon } from "../icons";
import { useStore } from "../store";

export default function Profile() {
  const { user, updateUser, updatePassword, notify } = useStore();
  const [form, setForm] = useState({
    name: user?.name ?? "",
    email: user?.email ?? "",
    phone: user?.phone ?? "",
    language: user?.language ?? "fr",
  });
  const [error, setError] = useState<unknown>(null);
  const [busy, setBusy] = useState(false);
  const [passwordForm, setPasswordForm] = useState({ current_password: "", password: "", password_confirmation: "" });
  const [passwordError, setPasswordError] = useState<unknown>(null);
  const [passwordBusy, setPasswordBusy] = useState(false);

  if (!user) return null;

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);

    try {
      const updatedUser = await updateUser({
        name: form.name.trim(),
        email: form.email.trim(),
        phone: form.phone.trim() || null,
        language: form.language,
      });
      setForm({
        name: updatedUser.name,
        email: updatedUser.email,
        phone: updatedUser.phone ?? "",
        language: updatedUser.language,
      });
      notify("Votre profil a été mis à jour.");
    } catch (err) {
      setError(err);
    } finally {
      setBusy(false);
    }
  };

  const submitPassword = async (event: FormEvent) => {
    event.preventDefault();
    setPasswordBusy(true);
    setPasswordError(null);

    try {
      await updatePassword(passwordForm);
      setPasswordForm({ current_password: "", password: "", password_confirmation: "" });
      notify("Votre mot de passe a été modifié.");
    } catch (err) {
      setPasswordError(err);
    } finally {
      setPasswordBusy(false);
    }
  };

  const initials = user.name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map(part => part[0])
    .join("")
    .toLocaleUpperCase("fr-FR");

  return (
    <div className="wrap profile-page">
      <Breadcrumb items={[["Accueil", "/"], ["Mon profil"]]} />
      <div className="profile-heading">
        <div>
          <p className="eyebrow">Votre compte</p>
          <h1 className="display page-title">Mon profil.</h1>
          <p className="lead">Consultez et mettez à jour vos informations personnelles.</p>
        </div>
      </div>

      <div className="profile-layout">
        <aside className="profile-summary">
          <div className="profile-summary-cover">
            <span className="profile-summary-mark"><Icon name="user" size={22} /></span>
            <span className="profile-summary-cover-label">Mon espace</span>
          </div>
          <div className="profile-summary-body">
            <div className="profile-avatar" aria-hidden="true">{initials}</div>
            <span className="badge ok profile-status"><span className="profile-status-dot" />Compte actif</span>
            <h2>{user.name}</h2>
            <p className="profile-summary-email">{user.email}</p>
            <div className="profile-summary-divider" />
            <div className="profile-summary-detail">
              <span>Téléphone</span>
              <strong>{user.phone || "Non renseigné"}</strong>
            </div>
            <div className="profile-summary-detail">
              <span>Langue</span>
              <strong>{user.language === "en" ? "English" : "Français"}</strong>
            </div>
          </div>
        </aside>

        <div className="profile-panels">
          <section className="panel profile-card">
            <div className="profile-card-head">
              <span className="profile-card-icon"><Icon name="user" size={20} /></span>
              <div className="profile-card-copy">
                <p className="eyebrow">Coordonnées</p>
                <h2>Informations personnelles</h2>
                <p>Ces informations servent à gérer votre compte et vos commandes.</p>
              </div>
            </div>

            <ErrorBox error={error instanceof ApiError && !Object.keys(error.errors).length ? error : null} />
            <form className="form" onSubmit={submit}>
              <div className="grid-2">
                <Field label="Nom complet *" error={fieldError(error, "name")}>
                  <input
                    className="input"
                    autoComplete="name"
                    maxLength={120}
                    required
                    value={form.name}
                    onChange={event => setForm({ ...form, name: event.target.value })}
                  />
                </Field>
                <Field label="Adresse email *" error={fieldError(error, "email")}>
                  <input
                    className="input"
                    type="email"
                    autoComplete="email"
                    maxLength={190}
                    required
                    value={form.email}
                    onChange={event => setForm({ ...form, email: event.target.value })}
                  />
                </Field>
                <Field label="Téléphone" error={fieldError(error, "phone")}>
                  <input
                    className="input"
                    type="tel"
                    autoComplete="tel"
                    maxLength={30}
                    value={form.phone}
                    onChange={event => setForm({ ...form, phone: event.target.value })}
                    placeholder="+225 07 00 00 00 00"
                  />
                </Field>
                <Field label="Langue" error={fieldError(error, "language")}>
                  <select
                    className="input"
                    value={form.language}
                    onChange={event => setForm({ ...form, language: event.target.value })}
                  >
                    <option value="fr">Français</option>
                    <option value="en">English</option>
                  </select>
                </Field>
              </div>
              <div className="profile-form-footer">
                <p className="note">Les champs marqués d’un * sont obligatoires.</p>
                <button className="btn btn-primary" disabled={busy}>
                  {busy ? "Enregistrement…" : "Enregistrer les modifications"}
                </button>
              </div>
            </form>
          </section>

          <section className="panel profile-card">
            <div className="profile-card-head">
              <span className="profile-card-icon"><Icon name="lock" size={20} /></span>
              <div className="profile-card-copy">
                <p className="eyebrow">Sécurité du compte</p>
                <h2>Mot de passe</h2>
                <p>Confirmez votre mot de passe actuel pour en choisir un nouveau.</p>
              </div>
            </div>

            <ErrorBox error={passwordError instanceof ApiError && !Object.keys(passwordError.errors).length ? passwordError : null} />
            <form className="form" onSubmit={submitPassword}>
              <div className="profile-password-fields">
                <Field label="Mot de passe actuel" error={fieldError(passwordError, "current_password")}>
                  <input
                    className="input"
                    type="password"
                    autoComplete="current-password"
                    required
                    value={passwordForm.current_password}
                    onChange={event => setPasswordForm({ ...passwordForm, current_password: event.target.value })}
                  />
                </Field>
                <div className="grid-2">
                  <Field label="Nouveau mot de passe" error={fieldError(passwordError, "password")}>
                    <input
                      className="input"
                      type="password"
                      autoComplete="new-password"
                      minLength={8}
                      required
                      value={passwordForm.password}
                      onChange={event => setPasswordForm({ ...passwordForm, password: event.target.value })}
                    />
                  </Field>
                  <Field label="Confirmer le nouveau mot de passe" error={fieldError(passwordError, "password_confirmation")}>
                    <input
                      className="input"
                      type="password"
                      autoComplete="new-password"
                      minLength={8}
                      required
                      value={passwordForm.password_confirmation}
                      onChange={event => setPasswordForm({ ...passwordForm, password_confirmation: event.target.value })}
                    />
                  </Field>
                </div>
              </div>
              <div className="profile-form-footer">
                <p className="note">8 caractères minimum.</p>
                <button className="btn btn-primary" disabled={passwordBusy}>
                  {passwordBusy ? "Modification…" : "Modifier le mot de passe"}
                </button>
              </div>
            </form>
          </section>
        </div>
      </div>
    </div>
  );
}
