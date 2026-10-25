import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";
import App from "./App";
import { StoreProvider } from "./store";
import "./styles.css";
import { startDiagnostics } from "./diagnostics";

startDiagnostics(); // temporaire : bug de la page blanche
createRoot(document.getElementById("root")!).render(
  <BrowserRouter><StoreProvider><App /></StoreProvider></BrowserRouter>
);
