import { useState } from 'react'
import { StoreContext } from './context'
import { useStore } from './store'
import { hexColor } from './types'
import { ProgramsView } from './components/ProgramsView'
import { SettingsView } from './components/SettingsView'

type Tab = 'programs' | 'settings'

export default function App() {
  const store = useStore()
  const [tab, setTab] = useState<Tab>('programs')
  const accent = hexColor(store.settings.accentColorHex)

  return (
    <StoreContext.Provider value={store}>
      <div className="relative" style={{ maxWidth: 430, margin: '0 auto', minHeight: '100dvh', background: '#0A0A0A' }}>
        <div key={tab} className="anim-up" style={{ paddingBottom: 110 }}>
          {tab === 'programs' && <ProgramsView />}
          {tab === 'settings' && <SettingsView />}
        </div>

        {/* Tab bar */}
        <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px]"
          style={{ background: 'rgba(12,12,12,0.97)', backdropFilter: 'blur(24px)', borderTop: '0.5px solid #232323', zIndex: 30 }}>
          <div className="flex safe-bottom" style={{ paddingTop: 8 }}>
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
    <button onClick={onClick} className="flex-1 flex flex-col items-center gap-1.5 py-2">
      <div style={{ color: active ? accent : '#3e3e3e', transition: 'color 0.18s' }}>
        {icon}
      </div>
      <span style={{
        fontSize: 10,
        fontWeight: 600,
        letterSpacing: 0.4,
        color: active ? accent : '#3e3e3e',
        transition: 'color 0.18s',
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

// needed for JSX in App
import React from 'react'
