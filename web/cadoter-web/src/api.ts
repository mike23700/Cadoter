// Client de l'API Laravel (Sanctum, jeton Bearer).
export const API_URL: string = import.meta.env.VITE_API_URL ?? "http://localhost:8001/api";
const TOKEN_KEY = "cadoter:token";

export type User = { id: number; name: string; email: string; phone: string | null; role: "user" | "admin"; language: string };

export type Gift = {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  price: number;
  currency: string;
  country: string;
  city: string;
  area: string | null;
  shop: string | null;
  category: string | null;
  for_who: string[] | null;
  occasions: string[] | null;
  image_url: string | null;
  stock: number | null;
  is_active: boolean;
  is_featured: boolean;
  available: boolean;
};

export type ItemStatus = "Disponible" | "Réservé" | "Indisponible";

export type ListItem = {
  id: number;
  status: ItemStatus;
  gift_id: number | null;
  gift_slug: string | null;
  name: string;
  price: number | null;
  currency: string;
  city: string | null;
  area: string | null;
  image_url: string | null;
  external_url: string | null;
  reserved_by_name: string | null;
};

export type GiftList = {
  id: number;
  code: string;
  title: string;
  description: string | null;
  occasion: string;
  image_url: string | null;
  event_date: string | null;
  created_at: string;
  is_locked: boolean;
  access_code: string | null;
  owner_name: string | null;
  items: ListItem[];
  counts: { total: number; reserved: number; available: number };
};

export type Wrapping = { id: number; code: string; name: string; detail: string | null; price: number; position: number; is_active: boolean; image_url: string | null };

export type Meta = {
  occasions: string[];
  for_who: string[];
  cities: string[];
  wrappings: Wrapping[];
  payment_methods: { code: string; name: string }[];
};

export type Order = {
  id: number; reference: string; gift_name: string; quantity: number; total: number; currency: string;
  customer_name: string; customer_phone: string; customer_email: string | null; delivery_city: string | null;
  delivery_address: string | null; message: string | null; payment_method: string; status: string;
  created_at: string; wrapping?: { id: number; name: string } | null;
};

export type CustomRequest = {
  id: number; name: string; phone: string; budget: number; description: string; status: string; created_at: string;
  wrapping?: { id: number; name: string } | null;
};

export class ApiError extends Error {
  constructor(message: string, public status: number, public errors: Record<string, string[]> = {}, public data: any = null) {
    super(message);
  }
  field(name: string) { return this.errors[name]?.[0]; }
}

export const token = {
  get: () => { try { return localStorage.getItem(TOKEN_KEY); } catch { return null; } },
  set: (t: string | null) => {
    try { t ? localStorage.setItem(TOKEN_KEY, t) : localStorage.removeItem(TOKEN_KEY); } catch { /* stockage indisponible */ }
  },
};

type Body = Record<string, unknown> | FormData | undefined;

export async function api<T>(path: string, opts: { method?: string; body?: Body; headers?: Record<string, string> } = {}): Promise<T> {
  const headers: Record<string, string> = { Accept: "application/json", ...opts.headers };
  const t = token.get();
  if (t) headers.Authorization = `Bearer ${t}`;
  let body: BodyInit | undefined;
  if (opts.body instanceof FormData) body = opts.body;
  else if (opts.body) { body = JSON.stringify(opts.body); headers["Content-Type"] = "application/json"; }

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, { method: opts.method ?? (body ? "POST" : "GET"), headers, body });
  } catch {
    throw new ApiError("Impossible de joindre le serveur. Vérifiez que l'API est démarrée.", 0);
  }
  if (res.status === 204) return undefined as T;
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    if (res.status === 401) token.set(null);
    throw new ApiError(data?.message ?? "Une erreur est survenue.", res.status, data?.errors ?? {}, data);
  }
  return data as T;
}

export const qs = (params: Record<string, string | number | boolean | undefined | null>) => {
  const p = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => { if (v !== undefined && v !== null && v !== "") p.set(k, String(v)); });
  const s = p.toString();
  return s ? `?${s}` : "";
};

export const formatPrice = (n: number | null | undefined, currency = "FCFA") =>
  n == null ? "Prix à confirmer" : `${n.toLocaleString("fr-FR").replace(/[  ]/g, " ")} ${currency}`;

export const giftPlace = (g: { city: string | null; area: string | null }) => [g.city, g.area].filter(Boolean).join(" · ");

export const formatDate = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString("fr-FR", { day: "numeric", month: "long" }) : "";

/** Prénom pour « Bonjour, Aïcha ». */
export const firstName = (u: User | null) => u?.name.split(" ")[0] ?? "";
