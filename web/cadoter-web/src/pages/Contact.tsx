import { FormEvent, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Breadcrumb, Field } from "../components";
import { t } from "../i18n";
import { Icon } from "../icons";
import { useStore } from "../store";

const SUBJECTS = ["Question sur une commande", "Liste de cadeaux", "Devenir boutique partenaire", "Autre"];

/** Formulaire de contact : ouvre WhatsApp avec le message pré-rempli (numéro réglé dans l'administration). */
export default function Contact() {
  const { user, meta } = useStore();
  const [form, setForm] = useState({ name: "", subject: SUBJECTS[0], message: "" });
  const number = meta?.contact?.whatsapp?.replace(/\D/g, "") ?? "";

  useEffect(() => { if (user) setForm(f => ({ ...f, name: f.name || user.name })); }, [user]);
  const set = (k: keyof typeof form) => (e: { target: { value: string } }) => setForm({ ...form, [k]: e.target.value });

  const submit = (e: FormEvent) => {
    e.preventDefault();
    const text = `${t("Bonjour CADOTER, je suis {name}.", { name: form.name.trim() })}\n${t("Sujet : {subject}", { subject: t(form.subject) })}\n\n${form.message.trim()}`;
    window.open(`https://wa.me/${number}?text=${encodeURIComponent(text)}`, "_blank", "noopener");
  };

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Accueil"), "/"], [t("Nous contacter")]]} />
      <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>{t("Parlons-en.")}</h1>
      <p className="lead page-lead">{t("Une question, une idée, un souci ? Écrivez-nous : votre message s'ouvre dans WhatsApp, prêt à être envoyé.")}</p>

      <div className="two-col custom">
        <form className="panel" onSubmit={submit}>
          <div className="form">
            <Field label={t("Nom *")}><input className="input" required maxLength={120} value={form.name} onChange={set("name")} placeholder="Aïcha Koné" /></Field>
            <Field label={t("Sujet")}>
              <select className="input" value={form.subject} onChange={set("subject")}>
                {SUBJECTS.map(s => <option key={s} value={s}>{t(s)}</option>)}
              </select>
            </Field>
            <Field label={t("Message *")}>
              <textarea className="input" required maxLength={2000} rows={6} value={form.message} onChange={set("message")} placeholder={t("Bonjour, je voudrais savoir…")} />
            </Field>
            {meta && !number && <div className="alert" role="alert">{t("Le contact WhatsApp n'est pas encore configuré.")}</div>}
            <button className="btn btn-primary btn-block" disabled={!number}>{t("Envoyer sur WhatsApp")} <Icon name="share" size={18} /></button>
            <p className="note">{t("WhatsApp s'ouvre avec votre message : il ne reste plus qu'à appuyer sur « Envoyer ».")}</p>
          </div>
        </form>

        <div className="panel rose">
          <h2 className="h2">{t("Avant d'écrire")}</h2>
          <p className="muted small" style={{ margin: "10px 0 16px" }}>{t("La réponse se trouve peut-être déjà dans notre FAQ.")}</p>
          <Link to="/faq" className="btn btn-outline">{t("Voir la FAQ")}</Link>
        </div>
      </div>
    </div>
  );
}
