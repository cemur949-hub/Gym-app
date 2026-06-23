import { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, PRESET_COLORS } from '../types'

export function SettingsView() {
  const { programs, settings, updateSettings, exportJSON, importJSON, clearAll } = useAppStore()
  const [showClear, setShowClear] = useState(false)
  const [showExport, setShowExport] = useState(false)
  const [exportText, setExportText] = useState('')
  const [importText, setImportText] = useState('')
  const [showImport, setShowImport] = useState(false)
  const [importMsg, setImportMsg] = useState('')
  const totalWorkouts = programs.reduce((sum, p) => sum + p.workouts.length, 0)

  const doExport = () => {
    setExportText(exportJSON())
    setShowExport(true)
  }

  const doImport = () => {
    try {
      importJSON(importText)
      setImportMsg('Imported successfully!')
      setShowImport(false)
      setImportText('')
    } catch {
      setImportMsg('Invalid JSON format.')
    }
  }

  return (
    <div className="flex flex-col min-h-dvh" style={{ background: '#0A0A0A' }}>
      <div className="px-4 pt-4 safe-top">
        <h1 className="text-2xl font-bold text-white mb-4">Settings</h1>
      </div>

      <div className="flex-1 overflow-y-auto px-4 pb-10 space-y-5">
        {/* Header card */}
        <div className="card flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl flex items-center justify-center"
            style={{ background: hexColor(settings.accentColorHex) }}>
            <span className="text-white text-2xl">🏋️</span>
          </div>
          <div>
            <p className="font-bold text-white text-base">GymTracker</p>
            <p className="text-xs text-textSecondary">Your personal workout companion</p>
            <p className="text-xs text-textSecondary">{programs.length} programs · {totalWorkouts} workouts</p>
          </div>
        </div>

        {/* Appearance */}
        <Section title="Appearance">
          <div className="p-4 space-y-4">
            <div>
              <p className="text-sm text-white mb-2">Accent Color</p>
              <div className="grid grid-cols-5 gap-2">
                {PRESET_COLORS.map(c => (
                  <button key={c.hex} onClick={() => updateSettings({ accentColorHex: c.hex })}
                    className="w-10 h-10 rounded-full flex items-center justify-center"
                    style={{ background: `#${c.hex}` }}>
                    {settings.accentColorHex === c.hex && <span className="text-white text-xs font-bold">✓</span>}
                  </button>
                ))}
              </div>
            </div>
            <SettingsDivider />
            <SettingsRow icon="⏱" label="Show Rest Times">
              <Toggle value={settings.showRestTimes} onChange={v => updateSettings({ showRestTimes: v })} accent={hexColor(settings.accentColorHex)} />
            </SettingsRow>
          </div>
        </Section>

        {/* Units */}
        <Section title="Units">
          <div className="p-4">
            <SettingsRow icon="⚖️" label="Weight Unit">
              <div className="flex rounded-lg overflow-hidden border border-divider">
                {(['lbs', 'kg'] as const).map(u => (
                  <button key={u} onClick={() => updateSettings({ weightUnit: u })}
                    className="px-4 py-1.5 text-sm font-semibold"
                    style={{ background: settings.weightUnit === u ? hexColor(settings.accentColorHex) : '#222', color: '#fff' }}>
                    {u.toUpperCase()}
                  </button>
                ))}
              </div>
            </SettingsRow>
          </div>
        </Section>

        {/* Data */}
        <Section title="Data">
          <div className="p-4 space-y-1">
            <button onClick={doExport} className="w-full">
              <SettingsRow icon="📤" label="Export Workouts" chevron />
            </button>
            <SettingsDivider />
            <button onClick={() => setShowImport(true)} className="w-full">
              <SettingsRow icon="📥" label="Import Workouts" chevron />
            </button>
            <SettingsDivider />
            <button onClick={() => setShowClear(true)} className="w-full">
              <SettingsRow icon="🗑" label="Clear All Data" labelColor="#ff3b30" />
            </button>
          </div>
        </Section>

        {/* About */}
        <Section title="About">
          <div className="p-4 space-y-1">
            <SettingsRow icon="ℹ️" label="Version 1.0.0" />
            <SettingsDivider />
            <SettingsRow icon="⚡" label="Built with React + Vite" />
          </div>
        </Section>

        {importMsg && (
          <p className="text-center text-sm" style={{ color: importMsg.includes('success') ? '#30D158' : '#FF3B30' }}>
            {importMsg}
          </p>
        )}
      </div>

      {/* Clear confirm */}
      {showClear && (
        <ConfirmModal
          title="Clear All Data?"
          message="This will permanently delete all programs and workouts."
          onConfirm={() => { clearAll(); setShowClear(false) }}
          onCancel={() => setShowClear(false)}
          destructive
        />
      )}

      {/* Export sheet */}
      {showExport && (
        <div className="fixed inset-0 z-50 flex flex-col" style={{ background: '#0A0A0A' }}>
          <div className="flex items-center justify-between px-4 py-3 border-b border-divider safe-top">
            <button onClick={() => setShowExport(false)} className="text-textSecondary text-sm">Done</button>
            <span className="font-semibold text-white text-sm">Export JSON</span>
            <button onClick={() => {
              const blob = new Blob([exportText], { type: 'application/json' })
              const a = document.createElement('a')
              a.href = URL.createObjectURL(blob)
              a.download = 'gymtracker-export.json'
              a.click()
            }} className="text-sm font-bold" style={{ color: hexColor(settings.accentColorHex) }}>Save File</button>
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            <pre className="text-xs text-textSecondary font-mono break-all whitespace-pre-wrap p-3 rounded-xl" style={{ background: '#171717' }}>
              {exportText}
            </pre>
          </div>
        </div>
      )}

      {/* Import sheet */}
      {showImport && (
        <div className="fixed inset-0 z-50 flex flex-col" style={{ background: '#0A0A0A' }}>
          <div className="flex items-center justify-between px-4 py-3 border-b border-divider safe-top">
            <button onClick={() => setShowImport(false)} className="text-textSecondary text-sm">Cancel</button>
            <span className="font-semibold text-white text-sm">Import Workouts</span>
            <button onClick={doImport} disabled={!importText.trim()}
              className="text-sm font-bold"
              style={{ color: importText.trim() ? hexColor(settings.accentColorHex) : '#8E8E93' }}>
              Import
            </button>
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            <p className="text-sm text-textSecondary mb-3">Paste exported GymTracker JSON below:</p>
            <textarea
              value={importText}
              onChange={e => setImportText(e.target.value)}
              placeholder="Paste JSON here..."
              rows={12}
              className="w-full text-sm font-mono p-3 rounded-xl resize-none"
              style={{ background: '#171717', color: '#fff', border: 'none', outline: 'none' }}
            />
          </div>
        </div>
      )}
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <p className="text-xs font-bold uppercase tracking-widest text-textSecondary px-1 mb-2">{title}</p>
      <div className="rounded-2xl overflow-hidden" style={{ background: '#171717' }}>
        {children}
      </div>
    </div>
  )
}

function SettingsRow({ icon, label, labelColor, children, chevron }: {
  icon: string; label: string; labelColor?: string; children?: React.ReactNode; chevron?: boolean
}) {
  return (
    <div className="flex items-center gap-3 py-1">
      <span className="text-base w-7 text-center">{icon}</span>
      <span className="flex-1 text-sm font-medium" style={{ color: labelColor ?? '#fff' }}>{label}</span>
      {children}
      {chevron && <span className="text-textSecondary text-xs">›</span>}
    </div>
  )
}

function SettingsDivider() {
  return <div className="h-px ml-10" style={{ background: '#2a2a2a' }} />
}

function Toggle({ value, onChange, accent }: { value: boolean; onChange: (v: boolean) => void; accent: string }) {
  return (
    <button onClick={() => onChange(!value)}
      className="w-11 h-6 rounded-full relative transition-colors"
      style={{ background: value ? accent : '#3a3a3c' }}>
      <div className="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform"
        style={{ left: value ? 'calc(100% - 22px)' : '2px' }} />
    </button>
  )
}

function ConfirmModal({ title, message, onConfirm, onCancel, destructive }: {
  title: string; message: string; onConfirm: () => void; onCancel: () => void; destructive?: boolean
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6"
      style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div className="rounded-2xl p-5 w-full max-w-xs" style={{ background: '#1c1c1e' }}>
        <h3 className="font-bold text-white text-center mb-1">{title}</h3>
        <p className="text-textSecondary text-sm text-center mb-4">{message}</p>
        <div className="flex flex-col gap-2">
          <button onClick={onConfirm}
            className="py-3 rounded-xl font-semibold text-sm"
            style={{ background: '#2c2c2e', color: destructive ? '#ff3b30' : '#fff' }}>
            Confirm
          </button>
          <button onClick={onCancel}
            className="py-3 rounded-xl font-semibold text-sm"
            style={{ background: '#2c2c2e', color: '#8E8E93' }}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}
