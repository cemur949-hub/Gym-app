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
        <div style={{ paddingBottom: 64 }}>
          {tab === 'programs' && <ProgramsView />}
          {tab === 'settings' && <SettingsView />}
        </div>

        {/* Tab bar */}
        <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] border-t"
          style={{ background: 'rgba(10,10,10,0.95)', backdropFilter: 'blur(20px)', borderColor: '#222' }}>
          <div className="flex safe-bottom">
            <TabItem label="Programs" icon="⬛" active={tab === 'programs'} onClick={() => setTab('programs')} accent={accent} />
            <TabItem label="Settings" icon="⬛" active={tab === 'settings'} onClick={() => setTab('settings')} accent={accent} />
          </div>
        </div>
      </div>
    </StoreContext.Provider>
  )
}

function TabItem({ label, icon: _icon, active, onClick, accent }: {
  label: string; icon: string; active: boolean; onClick: () => void; accent: string
}) {
  return (
    <button onClick={onClick} className="flex-1 flex flex-col items-center gap-1 py-3">
      <div className="w-5 h-0.5 rounded-full" style={{ background: active ? accent : 'transparent' }} />
      <span className="text-xs font-semibold tracking-wide" style={{ color: active ? accent : '#555' }}>{label}</span>
    </button>
  )
}
