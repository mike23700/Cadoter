import { ReactNode, useEffect } from "react";
import { Link } from "react-router-dom";
import { ApiError, formatPrice, Gift, giftPlace, ItemStatus } from "./api";
import { LANGS, t } from "./i18n";
import { Icon } from "./icons";
import { useStore } from "./store";

export function Badge({ status, children }: { status?: ItemStatus; children?: ReactNode }) {
  const ok = !status || status === "Disponible";
  const label = children ?? t(status === "Réservé" ? "Réservé par un proche" : status ?? "Disponible");
  return <span className={`badge ${ok ? "ok" : "off"}`}>{label}</span>;
}

export function GiftCard({ gift }: { gift: Gift }) {
  return (
    <Link to={`/cadeaux/${gift.slug}`} className="gift-card">
      <Photo src={gift.image_url} alt={gift.name} />
      <Badge status={gift.available ? "Disponible" : "Indisponible"} />
      <h3>{gift.name}</h3>
      <p className="seller-name">Vendu par <strong>{gift.seller_name}</strong></p>
      <p className="muted">{giftPlace(gift)}</p>
      <p className="price">{formatPrice(gift.price, gift.currency)}</p>
    </Link>
  );
}

export function Photo({ src, alt = "", className = "" }: { src: string | null | undefined; alt?: string; className?: string }) {
  return src
    ? <img className={`photo ${className}`} src={src} alt={alt} loading="lazy" />
    : <div className={`photo photo-empty ${className}`} aria-hidden="true"><Icon name="gift" size={32} /></div>;
}

export function Field({ label, error, children }: { label: string; error?: string; children: ReactNode }) {
  return (
    <label className={`field ${error ? "has-error" : ""}`}>
      <span>{label}</span>
      {children}
      {error && <em className="field-error">{error}</em>}
    </label>
  );
}

export function Breadcrumb({ items }: { items: [string, string?][] }) {
  return (
    <nav className="breadcrumb" aria-label={t("Fil d'Ariane")}>
      {items.map(([label, to], i) => (
        <span key={label}>
          {i > 0 && " / "}
          {to ? <Link to={to}>{label}</Link> : label}
        </span>
      ))}
    </nav>
  );
}

export const IllustrativeNote = () => <p className="note">{t("Exemples de cadeaux · Prix et lieux illustratifs")}</p>;

export function Loading({ label }: { label?: string }) {
  return <p className="loading">{label ?? t("Chargement…")}</p>;
}

export function ErrorBox({ error, onRetry }: { error: ApiError | Error | string | null; onRetry?: () => void }) {
  if (!error) return null;
  const msg = typeof error === "string" ? error : error.message;
  return (
    <div className="alert" role="alert">
      <span>{msg}</span>
      {onRetry && <button className="link" onClick={onRetry}>{t("Réessayer")}</button>}
    </div>
  );
}

export function GiftGridSkeleton({ n = 3 }: { n?: number }) {
  return (
    <div className="gift-grid">
      {Array.from({ length: n }, (_, i) => (
        <div key={i} className="gift-card skeleton"><div className="photo" /><span /><span /></div>
      ))}
    </div>
  );
}

export function Modal({ title, onClose, children }: { title: string; onClose: () => void; children: ReactNode }) {
  useEffect(() => {
    const esc = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    document.addEventListener("keydown", esc);
    document.body.style.overflow = "hidden";
    return () => { document.removeEventListener("keydown", esc); document.body.style.overflow = ""; };
  }, [onClose]);
  return (
    <div className="modal-backdrop" onMouseDown={e => e.target === e.currentTarget && onClose()}>
      <div className="modal" role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-head">
          <h2 className="h2">{title}</h2>
          <button className="icon-btn" onClick={onClose} aria-label={t("Fermer")}><Icon name="close" /></button>
        </div>
        {children}
      </div>
    </div>
  );
}

/** Message d'erreur lisible d'un champ renvoyé par Laravel. */
export const fieldError = (e: unknown, name: string) => (e instanceof ApiError ? e.field(name) : undefined);

/** Choix de la langue : « FR | EN ». */
export function LangSwitch({ className = "" }: { className?: string }) {
  const { lang, setLanguage } = useStore();
  return (
    <span className={`lang-switch ${className}`} role="group" aria-label={t("Langue")}>
      {LANGS.map(([code, name]) => (
        <button key={code} type="button" className={code === lang ? "on" : ""} aria-pressed={code === lang} title={name} onClick={() => setLanguage(code)}>{code.toUpperCase()}</button>
      ))}
    </span>
  );
}
