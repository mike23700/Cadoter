import { FormEvent, useEffect, useState } from "react";
import { api, ApiError, ImportantDate } from "../api";
import { Breadcrumb, ErrorBox, Field, fieldError } from "../components";
import { Icon } from "../icons";
import { locale, t } from "../i18n";
import { useStore } from "../store";

type ImportantDateForm = Pick<ImportantDate, "person_name" | "title" | "event_date">;

const emptyImportantDateForm = (): ImportantDateForm => ({ person_name: "", title: "", event_date: "" });

const sortImportantDates = (dates: ImportantDate[]) =>
  [...dates].sort((a, b) => a.next_occurrence.localeCompare(b.next_occurrence));

const formatImportantDate = (value: string) => {
  const [year, month, day] = value.split("-").map(Number);
  return new Intl.DateTimeFormat(locale(), { day: "numeric", month: "long", year: "numeric" })
    .format(new Date(year, month - 1, day));
};

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
  const [importantDates, setImportantDates] = useState<ImportantDate[]>([]);
  const [importantDatesLoading, setImportantDatesLoading] = useState(true);
  const [importantDatesError, setImportantDatesError] = useState<unknown>(null);
  const [importantDateError, setImportantDateError] = useState<unknown>(null);
  const [importantDateForm, setImportantDateForm] = useState<ImportantDateForm>(emptyImportantDateForm);
  const [editingImportantDateId, setEditingImportantDateId] = useState<number | null>(null);
  const [importantDateBusy, setImportantDateBusy] = useState(false);
  const [deletingImportantDateId, setDeletingImportantDateId] = useState<number | null>(null);
  const [importantDatesReload, setImportantDatesReload] = useState(0);

  useEffect(() => {
    let active = true;
    setImportantDatesLoading(true);
    setImportantDatesError(null);

    api<ImportantDate[]>("/important-dates")
      .then(dates => { if (active) setImportantDates(sortImportantDates(dates)); })
      .catch(err => { if (active) setImportantDatesError(err); })
      .finally(() => { if (active) setImportantDatesLoading(false); });

    return () => { active = false; };
  }, [importantDatesReload]);

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

  const submitImportantDate = async (event: FormEvent) => {
    event.preventDefault();
    setImportantDateBusy(true);
    setImportantDateError(null);

    const payload = {
      person_name: importantDateForm.person_name.trim(),
      title: importantDateForm.title.trim(),
      event_date: importantDateForm.event_date,
    };

    try {
      const savedDate = editingImportantDateId
        ? await api<ImportantDate>("/important-dates/" + editingImportantDateId, { method: "PUT", body: payload })
        : await api<ImportantDate>("/important-dates", { body: payload });
      setImportantDates(current => sortImportantDates([...current.filter(date => date.id !== savedDate.id), savedDate]));
      setImportantDateForm(emptyImportantDateForm());
      setEditingImportantDateId(null);
      notify(t(editingImportantDateId ? "Date modifiée." : "Date ajoutée."));
    } catch (err) {
      setImportantDateError(err);
    } finally {
      setImportantDateBusy(false);
    }
  };

  const editImportantDate = (date: ImportantDate) => {
    setImportantDateError(null);
    setEditingImportantDateId(date.id);
    setImportantDateForm({ person_name: date.person_name, title: date.title, event_date: date.event_date });
  };

  const cancelImportantDateEdit = () => {
    setEditingImportantDateId(null);
    setImportantDateForm(emptyImportantDateForm());
    setImportantDateError(null);
  };

  const deleteImportantDate = async (date: ImportantDate) => {
    if (!window.confirm(t("Supprimer cette date ?"))) return;
    setDeletingImportantDateId(date.id);
    setImportantDateError(null);

    try {
      await api<void>("/important-dates/" + date.id, { method: "DELETE" });
      setImportantDates(current => current.filter(item => item.id !== date.id));
      if (editingImportantDateId === date.id) cancelImportantDateEdit();
      notify(t("Date supprimée."));
    } catch (err) {
      setImportantDateError(err);
    } finally {
      setDeletingImportantDateId(null);
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
              <span className="profile-card-icon"><Icon name="cake" size={20} /></span>
              <div className="profile-card-copy">
                <p className="eyebrow">{t("Vos dates à célébrer")}</p>
                <h2>{t("Les moments qui comptent")}</h2>
                <p>{t("Enregistrez les anniversaires et autres événements de vos proches. Chaque date revient automatiquement chaque année.")}</p>
              </div>
            </div>

            <ErrorBox
              error={importantDateError instanceof Error && !(importantDateError instanceof ApiError && Object.keys(importantDateError.errors).length) ? importantDateError : null}
            />
            <form className="form" onSubmit={submitImportantDate}>
              <div className="grid-2">
                <Field label={t("Personne *")} error={fieldError(importantDateError, "person_name")}>
                  <input
                    className="input"
                    autoComplete="off"
                    maxLength={120}
                    required
                    value={importantDateForm.person_name}
                    onChange={event => setImportantDateForm({ ...importantDateForm, person_name: event.target.value })}
                    placeholder={t("Ex. Aïcha et Karim")}
                  />
                </Field>
                <Field label={t("Titre de l’événement *")} error={fieldError(importantDateError, "title")}>
                  <input
                    className="input"
                    maxLength={160}
                    required
                    value={importantDateForm.title}
                    onChange={event => setImportantDateForm({ ...importantDateForm, title: event.target.value })}
                    placeholder={t("Ex. Anniversaire de mariage")}
                  />
                </Field>
                <Field label={t("Date de l’événement *")} error={fieldError(importantDateError, "event_date")}>
                  <input
                    className="input"
                    type="date"
                    required
                    value={importantDateForm.event_date}
                    onChange={event => setImportantDateForm({ ...importantDateForm, event_date: event.target.value })}
                  />
                </Field>
              </div>
              <div className="profile-form-footer important-date-form-footer">
                <p className="note">{t("Un e-mail sera envoyé à {email} une semaine avant, 3 jours avant et le jour même.", { email: user.email })}</p>
                <div className="important-date-form-actions">
                  {editingImportantDateId && <button type="button" className="btn btn-outline" onClick={cancelImportantDateEdit}>{t("Annuler")}</button>}
                  <button className="btn btn-primary" disabled={importantDateBusy}>
                    {importantDateBusy ? t("Enregistrement…") : t(editingImportantDateId ? "Mettre à jour la date" : "Ajouter cette date")}
                  </button>
                </div>
              </div>
            </form>

            <ErrorBox
              error={importantDatesError instanceof Error ? importantDatesError : null}
              onRetry={() => setImportantDatesReload(value => value + 1)}
            />
            {importantDatesLoading ? (
              <p className="note important-date-loading">{t("Chargement des dates…")}</p>
            ) : importantDates.length ? (
              <div className="important-date-list">
                {importantDates.map(date => (
                  <article className="important-date-item" key={date.id}>
                    <div className="important-date-copy">
                      <span className="important-date-next">{t("Prochaine date : {date}", { date: formatImportantDate(date.next_occurrence) })}</span>
                      <h3>{date.title}</h3>
                      <p>{t("Pour {person}", { person: date.person_name })}</p>
                      <span className="note">{t("Rappels par e-mail : J-7, J-3 et le jour J")}</span>
                    </div>
                    <div className="important-date-actions">
                      <button type="button" className="btn btn-outline" onClick={() => editImportantDate(date)}>{t("Modifier")}</button>
                      <button type="button" className="link" disabled={deletingImportantDateId === date.id} onClick={() => deleteImportantDate(date)}>
                        {deletingImportantDateId === date.id ? t("Suppression…") : t("Supprimer")}
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            ) : (
              <p className="empty important-date-empty">{t("Aucune date enregistrée pour le moment.")}</p>
            )}
          </section>

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
