import { useState } from 'react'
import { StoreContext } from './context'
import { useStore } from './store'
import { hexColor } from './types'
import { ProgramsView } from './components/ProgramsView'
import { SettingsView } from './components/SettingsView'
import React from 'react'

type Tab = 'programs' | 'settings'

export default function App() {
  const store = useStore()
  const [tab, setTab] = useState<Tab>('programs')
  const accent = hexColor(store.settings.accentColorHex)

  return (
    <StoreContext.Provider value={store}>
      <div style={{ maxWidth: 430, margin: '0 auto', minHeight: '100dvh', background: '#0A0A0A', position: 'relative' }}>
        <div key={tab} className="anim-up" style={{ paddingBottom: 110 }}>
          {tab === 'programs' && <ProgramsView />}
          {tab === 'settings' && <SettingsView />}
        </div>

        {/* Tab bar — full-width fixed, no transform to avoid iOS jitter */}
        <div style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 30,
          background: '#0d0d0d',
          borderTop: '0.5px solid #252525',
        }}>
          <div style={{
            maxWidth: 430,
            margin: '0 auto',
            display: 'flex',
            paddingTop: 10,
            paddingBottom: 'env(safe-area-inset-bottom, 16px)',
          }}>
            <TabItem label="Programs" icon={<DumbbellIcon />} active={tab === 'programs'} onClick={() => setTab('programs')} accent={accent} />
            <TabItem label="Settings" icon={<SlidersIcon />} active={tab === 'settings'} onClick={() => setTab('settings')} accent={accent} />
          </div>
        </div>
      </div>
    </StoreContext.Provider>
  )
}

function TabItem({ label, icon, active, onClick, accent }: {
  label: string; icon: React.ReactNode; active: boolean; onClick: () => void; accent: string
}) {
  return (
    <button onClick={onClick} style={{
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      gap: 5,
      paddingBottom: 6,
      background: 'none',
      border: 'none',
      cursor: 'pointer',
    }}>
      <div style={{ color: active ? accent : '#3a3a3a', transition: 'color 0.15s' }}>
        {icon}
      </div>
      <span style={{
        fontSize: 10,
        fontWeight: 600,
        letterSpacing: 0.5,
        color: active ? accent : '#3a3a3a',
        transition: 'color 0.15s',
        fontFamily: 'inherit',
      }}>{label.toUpperCase()}</span>
    </button>
  )
}

function DumbbellIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
      <rect x="2.5" y="9.5" width="3.5" height="5" rx="1.5" />
      <rect x="18" y="9.5" width="3.5" height="5" rx="1.5" />
      <rect x="6" y="8" width="2" height="8" rx="1" />
      <rect x="16" y="8" width="2" height="8" rx="1" />
      <rect x="8" y="11" width="8" height="2" rx="1" />
    </svg>
  )
}

function SlidersIcon() {
  return (
    <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round">
      <line x1="4" y1="6" x2="20" y2="6" />
      <line x1="4" y1="12" x2="20" y2="12" />
      <line x1="4" y1="18" x2="20" y2="18" />
      <circle cx="8" cy="6" r="2.2" fill="currentColor" stroke="none" />
      <circle cx="16" cy="12" r="2.2" fill="currentColor" stroke="none" />
      <circle cx="10" cy="18" r="2.2" fill="currentColor" stroke="none" />
    </svg>
  )
}
