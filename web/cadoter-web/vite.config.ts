import { defineConfig, ProxyOptions } from "vite";
import react from "@vitejs/plugin-react";

// L'API Laravel (docker, port 8001) est relayée par Vite : un seul port (5173)
// à exposer, par exemple via ngrok pour tester à distance.
const backend = "http://localhost:8001";

// Robots qui génèrent l'aperçu d'un lien (WhatsApp, Facebook, Telegram…) : ils
// n'exécutent pas React, on leur sert la page Open Graph de l'API à la place.
const PREVIEW_BOTS = /whatsapp|facebookexternalhit|facebot|meta-externalagent|twitterbot|telegrambot|slackbot|discordbot|linkedinbot|skypeuripreview|pinterest|googlebot|bingbot|embedly|vkshare|snapchat/i;

const proxy: Record<string, string | ProxyOptions> = {
  "/api": backend,
  "/storage": backend,
  // Lien partagé d'une liste (/l/CODE) : aperçu pour les robots, application pour les visiteurs
  "^/l/[^/?]+": {
    target: backend,
    changeOrigin: false, // garde le domaine public (ngrok) pour les liens de l'aperçu
    rewrite: path => path.replace(/^\/l\//, "/apercu/l/"),
    bypass: req => (PREVIEW_BOTS.test(req.headers["user-agent"] ?? "") ? undefined : "/index.html"),
  },
};

export default defineConfig({
  plugins: [react()],
  server: { host: true, proxy },
  preview: { host: true, proxy },
});
