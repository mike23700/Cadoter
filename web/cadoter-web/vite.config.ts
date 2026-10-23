import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// L'API Laravel (docker, port 8001) est relayée par Vite : un seul port (5173)
// à exposer, par exemple via ngrok pour tester à distance.
const backend = "http://localhost:8001";

export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    proxy: {
      "/api": backend,
      "/storage": backend,
    },
  },
});
