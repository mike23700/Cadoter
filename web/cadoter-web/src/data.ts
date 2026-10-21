// Contenus éditoriaux (blog). Les cadeaux, listes et emballages viennent de l'API.

export type Article = {
  slug: string;
  tag: string;
  minutes: number;
  title: string;
  excerpt: string;
  image: string;
  body: string[];
};

export const occasionsHome = ["Anniversaire", "Mariage", "Naissance", "Dot"];

export const articles: Article[] = [
  {
    slug: "pour-papa",
    tag: "Fête des pères",
    minutes: 4,
    title: "Pour papa, une attention qui compte.",
    excerpt: "Un moment partagé, un objet qui lui ressemble : nos pistes pour lui dire ce qu'il représente pour vous.",
    image: "/img/article-papa.jpg",
    body: [
      "Les pères ont souvent du mal à dire ce qui leur ferait plaisir. Plutôt que de chercher l'objet parfait, pensez à ce qu'il aime faire : lire le journal au calme, écouter ses vieux disques, recevoir la famille le dimanche.",
      "Un rituel du thé, une enceinte pour sa musique ou un simple déjeuner partagé : l'important est que le cadeau raconte quelque chose de votre lien.",
      "Et si vous hésitez, créez une liste avec vos frères et sœurs : chacun choisit, personne n'offre deux fois la même chose.",
    ],
  },
  {
    slug: "merci-maman",
    tag: "Fête des mères",
    minutes: 5,
    title: "Lui dire merci, tout simplement.",
    excerpt: "Des fleurs, un mot, un moment : les petites attentions qui touchent le plus.",
    image: "/img/article-maman.jpg",
    body: [
      "Un bouquet de fleurs séchées dure des mois et rappelle votre attention à chaque regard. Ajoutez un petit mot manuscrit : c'est souvent ce qu'elle gardera le plus longtemps.",
      "Pour aller plus loin, demandez un cadeau personnalisé : nous vous accompagnons pour composer une attention qui lui ressemble, jusqu'au choix de l'emballage.",
    ],
  },
  {
    slug: "noel",
    tag: "Noël",
    minutes: 4,
    title: "Un Noël plein de petites attentions.",
    excerpt: "Organiser les cadeaux en famille sans doublon, c'est possible.",
    image: "/img/article-noel.jpg",
    body: [
      "À Noël, les cadeaux se multiplient et les doublons aussi. Une liste partagée permet à chacun de réserver ce qu'il offre, sans gâcher la surprise.",
      "Choisissez un emballage pour chaque cadeau : rosé, kraft ou bleu ciel, le soin du dernier détail fait toute la différence au pied du sapin.",
    ],
  },
  {
    slug: "soutenir-un-proche",
    tag: "Soutien",
    minutes: 3,
    title: "Soutenir un proche en deuil.",
    excerpt: "Des attentions sobres et respectueuses, à son rythme.",
    image: "/img/bouquet.jpg",
    body: [
      "Dans les moments difficiles, les gestes simples comptent : un repas apporté, des fleurs sobres, une présence. Évitez les cadeaux trop festifs.",
      "Une liste de soutien permet à l'entourage de proposer une aide concrète sans doublon, en respectant le rythme de la famille.",
    ],
  },
];
