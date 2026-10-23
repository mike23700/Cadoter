// Traduction FR / EN. Le texte français sert de clé : t("Se déconnecter") renvoie
// la version anglaise (i18n.en.ts) quand l'anglais est choisi, sinon le texte tel quel.
import en from "./i18n.en";

export type Lang = "fr" | "en";
export const LANGS: [Lang, string][] = [["fr", "Français"], ["en", "English"]];
const KEY = "cadoter:lang";

let lang: Lang = (() => {
  try { const v = localStorage.getItem(KEY); if (v === "fr" || v === "en") return v; } catch { /* stockage indisponible */ }
  return "fr";
})();
document.documentElement.lang = lang;

export const getLang = () => lang;
export const hasStoredLang = () => { try { return localStorage.getItem(KEY) !== null; } catch { return false; } };
/** Locale pour les nombres et les dates. */
export const locale = () => (lang === "en" ? "en-GB" : "fr-FR");

export function setLang(l: Lang) {
  lang = l;
  try { localStorage.setItem(KEY, l); } catch { /* stockage indisponible */ }
  document.documentElement.lang = l;
}

/** Texte traduit, avec remplacement des {variables}. */
export function t(fr: string, vars?: Record<string, string | number>): string {
  const s = lang === "en" ? en[fr] ?? fr : fr;
  return vars ? s.replace(/\{(\w+)\}/g, (m, k) => (k in vars ? String(vars[k]) : m)) : s;
}

/** Singulier / pluriel selon la langue (« 0 cadeau » en français, « 0 gifts » en anglais). */
export const tn = (n: number, one: string, many: string) => t((lang === "en" ? n === 1 : n <= 1) ? one : many, { n });
