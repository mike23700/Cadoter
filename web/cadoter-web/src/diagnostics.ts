// Diagnostic TEMPORAIRE de la « page blanche » : à chaque changement de page, on envoie
// au serveur ce que voit le navigateur (storage/logs/client.log côté API). À retirer une fois le bug résolu.
import { API_URL } from "./api";

const session = Math.random().toString(36).slice(2, 8);
const started = Date.now();

function send(type: string, data: Record<string, unknown> = {}) {
  try {
    fetch(`${API_URL}/client-log`, {
      method: "POST",
      keepalive: true,
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ type, session, data: { ...data, t: Date.now() - started } }),
    }).catch(() => undefined);
  } catch { /* le diagnostic ne doit jamais gêner le site */ }
}

const describe = (el: Element | null) =>
  el ? `${el.tagName.toLowerCase()}${el.id ? `#${el.id}` : ""}${typeof el.className === "string" && el.className ? `.${el.className.trim().split(/\s+/).join(".")}` : ""}` : null;

/** Le navigateur dessine-t-il encore ? (délai avant la prochaine image, null si rien après 3 s) */
const frameDelay = () => new Promise<number | null>(resolve => {
  const t = performance.now();
  const timer = setTimeout(() => resolve(null), 3000);
  requestAnimationFrame(() => { clearTimeout(timer); resolve(Math.round(performance.now() - t)); });
});

async function snapshot(path: string, since: number) {
  const root = document.getElementById("root");
  const header = document.querySelector("header");
  const main = document.querySelector("main");
  const center = document.elementFromPoint(innerWidth / 2, innerHeight / 2);
  const top = document.elementFromPoint(innerWidth / 2, 40);
  const body = getComputedStyle(document.body);
  return {
    path, expected: location.pathname, since,
    rootChildren: root?.childElementCount ?? -1,
    rootLen: root?.innerHTML.length ?? -1,
    headerHeight: header ? Math.round(header.getBoundingClientRect().height) : null,
    headerTop: header ? Math.round(header.getBoundingClientRect().top) : null,
    mainText: main?.innerText.length ?? null,
    center: describe(center), top: describe(top),
    centerBg: center ? getComputedStyle(center).backgroundColor : null,
    bodyOpacity: body.opacity, bodyVisibility: body.visibility, bodyOverflow: document.body.style.overflow,
    scrollY: Math.round(scrollY), innerHeight, docHeight: document.documentElement.scrollHeight,
    readyState: document.readyState, visibility: document.visibilityState,
    frameDelay: await frameDelay(),
    slowResources: performance.getEntriesByType("resource")
      .filter(r => (r as PerformanceResourceTiming).duration > 2000).slice(-6)
      .map(r => `${Math.round(r.duration)}ms ${r.name.replace(location.origin, "").slice(0, 80)}`),
  };
}

const looksBlank = (s: Awaited<ReturnType<typeof snapshot>>) =>
  !s.headerHeight || (s.mainText ?? 0) < 30 || s.frameDelay === null || s.center === "html" || s.center === "body";

let navId = 0;

/** À appeler à chaque changement de page. */
export function watchNavigation(path: string) {
  const id = ++navId;
  const t0 = performance.now();
  let reportedBlank = false;
  const check = async (i: number) => {
    if (id !== navId) return; // l'utilisateur est déjà ailleurs
    const s = await snapshot(path, Math.round(performance.now() - t0));
    const blank = looksBlank(s);
    if (i === 1 || (blank && !reportedBlank) || (!blank && reportedBlank)) {
      send(blank ? "blank" : reportedBlank ? "recovered" : "nav", s);
    }
    if (blank) reportedBlank = true;
    else if (reportedBlank) return;
    if (i < 12) setTimeout(() => check(i + 1), i < 4 ? 1000 : 5000);
  };
  setTimeout(() => check(0), 300);
}

export const reportError = (error: Error, where: string) =>
  send("render-error", { message: error.message, stack: error.stack?.slice(0, 800), where, path: location.pathname });

export function startDiagnostics() {
  send("boot", { path: location.pathname, w: innerWidth, h: innerHeight, dpr: devicePixelRatio, mem: (navigator as { deviceMemory?: number }).deviceMemory });
  addEventListener("error", e => send("error", { message: e.message, source: `${e.filename}:${e.lineno}:${e.colno}`, path: location.pathname }));
  addEventListener("unhandledrejection", e => send("rejection", { reason: String(e.reason).slice(0, 300), path: location.pathname }));
  // Fil principal bloqué (calcul trop long) : l'écran ne peut plus se mettre à jour
  try {
    new PerformanceObserver(list => list.getEntries().forEach(e => e.duration > 700 && send("longtask", { ms: Math.round(e.duration), path: location.pathname })))
      .observe({ type: "longtask", buffered: true });
  } catch { /* non supporté */ }
  addEventListener("pagehide", () => send("pagehide", { path: location.pathname }));
}
