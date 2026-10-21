export type Gift = { id: string; name: string; price: number; currency: string; city: string; country: string; shop: string; forWho: string; desc: string; emoji: string };
export const forWho = ["Enfants", "Parents", "Couple", "Ami(e)s", "Collègue", "Famille"];
export const occasions = ["Anniversaire", "Mariage", "Naissance", "Dot", "Soutien"];
// Base pays / villes (à remplacer par le JSON complet)
export const countries = [
  { country: "Cameroun", currency: "FCFA", cities: ["Yaoundé", "Douala"] },
  { country: "Côte d'Ivoire", currency: "FCFA", cities: ["Abidjan", "Bouaké"] },
];
export const cities = countries.flatMap(c => c.cities);
export const gifts: Gift[] = [
  { id: "1", name: "Le rituel du thé", price: 20000, currency: "FCFA", city: "Abidjan", country: "Côte d'Ivoire", shop: "Maison Thé", forWho: "Parents", desc: "Théière, deux tasses et un assortiment de thés.", emoji: "🫖" },
  { id: "2", name: "Bougie parfumée", price: 8000, currency: "FCFA", city: "Yaoundé", country: "Cameroun", shop: "Lumina", forWho: "Ami(e)s", desc: "Bougie artisanale, 40 h de combustion.", emoji: "🕯️" },
  { id: "3", name: "Panier gourmand", price: 25000, currency: "FCFA", city: "Douala", country: "Cameroun", shop: "Délices", forWho: "Famille", desc: "Confitures, chocolats et biscuits locaux.", emoji: "🧺" },
  { id: "4", name: "Plaid en coton", price: 15000, currency: "FCFA", city: "Abidjan", country: "Côte d'Ivoire", shop: "Douceur", forWho: "Couple", desc: "Plaid doux, 130 x 170 cm.", emoji: "🛋️" },
  { id: "5", name: "Peluche et livre d'éveil", price: 12000, currency: "FCFA", city: "Yaoundé", country: "Cameroun", shop: "P'tits Rêves", forWho: "Enfants", desc: "Coffret naissance.", emoji: "🧸" },
  { id: "6", name: "Carnet et stylo gravés", price: 10000, currency: "FCFA", city: "Douala", country: "Cameroun", shop: "Plume", forWho: "Collègue", desc: "Gravure du prénom incluse.", emoji: "📓" },
];
export const price = (g: Gift) => `${g.price.toLocaleString("fr-FR")} ${g.currency}`;
export const articles = ["Pour papa, une attention qui compte", "Un petit mot, tout simplement", "Le Noël plein de petites attentions", "Comment soutenir un proche en deuil"];
