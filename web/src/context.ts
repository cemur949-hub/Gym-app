import { createContext, useContext } from 'react'
import type { Store } from './store'

export const StoreContext = createContext<Store | null>(null)

export function useAppStore() {
  const ctx = useContext(StoreContext)
  if (!ctx) throw new Error('StoreContext missing')
  return ctx
}
