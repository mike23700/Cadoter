import { createContext, useContext, useState } from "react";
import type { ReactNode } from "react";
type S = { reserved: string[]; reserve: (id: string) => void; release: (id: string) => void };
const Ctx = createContext<S>({ reserved: [], reserve: () => {}, release: () => {} });
export const useStore = () => useContext(Ctx);
export function StoreProvider({ children }: { children: ReactNode }) {
  const [reserved, setReserved] = useState<string[]>([]);
  const reserve = (id: string) => setReserved(r => (r.includes(id) ? r : [...r, id]));
  const release = (id: string) => setReserved(r => r.filter(x => x !== id));
  return <Ctx.Provider value={{ reserved, reserve, release }}>{children}</Ctx.Provider>;
}
