import { Link } from "react-router-dom";
import { Faq as FaqT } from "../api";
import { Breadcrumb, ErrorBox, Loading } from "../components";
import { t } from "../i18n";
import { Icon } from "../icons";
import { useApi } from "../store";

/** Questions fréquentes, gérées depuis l'administration. */
export default function Faq() {
  const { data, error, loading, reload } = useApi<FaqT[]>("/faqs");

  return (
    <div className="wrap">
      <Breadcrumb items={[[t("Accueil"), "/"], [t("FAQ")]]} />
      <h1 className="display page-title" style={{ fontSize: 52, lineHeight: 1.2 }}>{t("Questions fréquentes")}</h1>
      <p className="lead page-lead">{t("Les réponses aux questions que l'on nous pose le plus souvent.")}</p>

      <ErrorBox error={error} onRetry={reload} />
      {loading && !data ? <Loading /> : data && (
        data.length === 0
          ? <div className="empty">{t("Aucune question pour le moment.")}</div>
          : <div className="faq">
              {data.map(f => (
                <details key={f.id}>
                  <summary>{f.question}<Icon name="plus" size={18} /></summary>
                  <p>{f.answer}</p>
                </details>
              ))}
            </div>
      )}

      <div className="panel rose faq-contact">
        <h2 className="h2">{t("Vous ne trouvez pas votre réponse ?")}</h2>
        <p className="muted small">{t("Écrivez-nous, nous vous répondons sur WhatsApp.")}</p>
        <Link to="/contact" className="btn btn-primary">{t("Nous contacter")}</Link>
      </div>
    </div>
  );
}
