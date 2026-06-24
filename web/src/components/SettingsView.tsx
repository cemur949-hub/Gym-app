import { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, PRESET_COLORS } from '../types'

export function SettingsView() {
  const { programs, settings, updateSettings, exportJSON, importJSON, clearAll } = useAppStore()
  const [showClear, setShowClear] = useState(false)
  const [importText, setImportText] = useState('')
  const [showImport, setShowImport] = useState(false)
  const [importMsg, setImportMsg] = useState('')
  const totalWorkouts = programs.reduce((sum, p) => sum + p.workouts.length, 0)

  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)

  const doExport = () => {
    const blob = new Blob([exportJSON()], { type: 'application/json' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = 'gymtracker-backup.json'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(a.href)
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
    <div style={{ background: '#0A0A0A' }}>
      <div className="px-4 safe-top">
        <h1 className="text-2xl font-bold text-white py-4">Settings</h1>
      </div>

      <div className="px-4 space-y-5 pb-6">
        {/* Header card */}
        <div className="card flex items-center gap-4">
          <img src={`${import.meta.env.BASE_URL}icon-192.png`} className="w-14 h-14 rounded-2xl" alt="GymTracker" />
          <div>
            <p className="font-bold text-white text-base">GymTracker</p>
            <p className="text-xs text-textSecondary">Your personal workout companion</p>
            <p className="text-xs text-textSecondary mt-0.5">{programs.length} programs · {totalWorkouts} workouts</p>
          </div>
        </div>

        {/* Appearance */}
        <Section title="Appearance">
          <div className="p-4 space-y-4">
            <div>
              <p className="text-sm text-white mb-3">Accent Color</p>
              <div className="grid grid-cols-5 gap-3">
                {PRESET_COLORS.map(c => (
                  <button key={c.hex} onClick={() => updateSettings({ accentColorHex: c.hex })}
                    className="w-11 h-11 rounded-full flex items-center justify-center"
                    style={{
                      background: `#${c.hex}`,
                      boxShadow: settings.accentColorHex === c.hex ? `0 0 0 2px #0A0A0A, 0 0 0 4px #${c.hex}` : 'none',
                    }}>
                    {settings.accentColorHex === c.hex && (
                      <span style={{ color: accentTextColor(c.hex), fontSize: 13, fontWeight: 700 }}>✓</span>
                    )}
                  </button>
                ))}
              </div>
            </div>
            <SettingsDivider />
            <SettingsRow icon="⏱" label="Show Rest Times">
              <Toggle value={settings.showRestTimes} onChange={v => updateSettings({ showRestTimes: v })} accent={accent} accentFg={accentFg} />
            </SettingsRow>
          </div>
        </Section>

        {/* Units */}
        <Section title="Units">
          <div className="p-4">
            <SettingsRow icon="⚖️" label="Weight Unit">
              <div className="flex rounded-xl overflow-hidden" style={{ border: '1px solid #2e2e2e' }}>
                {(['lbs', 'kg'] as const).map(u => (
                  <button key={u} onClick={() => updateSettings({ weightUnit: u })}
                    className="px-5 py-2 text-sm font-semibold"
                    style={{
                      background: settings.weightUnit === u ? accent : 'transparent',
                      color: settings.weightUnit === u ? accentFg : '#666',
                    }}>
                    {u.toUpperCase()}
                  </button>
                ))}
              </div>
            </SettingsRow>
          </div>
        </Section>

        {/* AI Features */}
        <Section title="AI Features">
          <div className="p-4 space-y-3">
            <p className="text-xs text-textSecondary leading-relaxed">
              Scan a photo of paper notes to auto-fill workouts using Claude AI. Requires an Anthropic API key.
            </p>
            <input
              type="password"
              placeholder="sk-ant-..."
              value={settings.anthropicApiKey}
              onChange={e => updateSettings({ anthropicApiKey: e.target.value })}
              style={{ background: '#222', color: '#fff', borderRadius: 10, padding: '10px 12px', width: '100%', border: 'none', outline: 'none', fontSize: 16, fontFamily: 'monospace' }}
            />
            {settings.anthropicApiKey
              ? <p className="text-xs" style={{ color: '#30D158' }}>✓ API key saved</p>
              : <p className="text-xs text-textSecondary">Get a key at console.anthropic.com</p>
            }
          </div>
        </Section>

        {/* Data */}
        <Section title="Data">
          <div className="p-4 space-y-1">
            <button onClick={doExport} className="w-full text-left">
              <SettingsRow icon="📤" label="Export Workouts" chevron />
            </button>
            <SettingsDivider />
            <button onClick={() => setShowImport(true)} className="w-full text-left">
              <SettingsRow icon="📥" label="Import Workouts" chevron />
            </button>
            <SettingsDivider />
            <button onClick={() => setShowClear(true)} className="w-full text-left">
              <SettingsRow icon="🗑" label="Clear All Data" labelColor="#ff3b30" />
            </button>
          </div>
        </Section>

        {/* About */}
        <Section title="About">
          <div className="p-4 space-y-1">
            <SettingsRow icon="ℹ️" label="Version 1.4.0" />
            <SettingsDivider />
            <SettingsRow icon="⚡" label="Built with React + Vite" />
          </div>
        </Section>

        {importMsg && (
          <p className="text-center text-sm py-1" style={{ color: importMsg.includes('success') ? '#30D158' : '#FF3B30' }}>
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

      {/* Import sheet */}
      {showImport && (
        <div className="fixed inset-0 z-50 flex flex-col anim-right" style={{ background: '#0A0A0A' }}>
          <div className="flex items-center justify-between px-4 py-3 border-b safe-top" style={{ borderColor: '#222' }}>
            <button onClick={() => setShowImport(false)} className="text-textSecondary text-sm">Cancel</button>
            <span className="font-semibold text-white text-sm">Import Workouts</span>
            <button onClick={doImport} disabled={!importText.trim()}
              className="text-sm font-bold"
              style={{ color: importText.trim() ? accent : '#555' }}>
              Import
            </button>
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            <p className="text-sm text-textSecondary mb-3">Paste a GymTracker export JSON below:</p>
            <textarea
              value={importText}
              onChange={e => setImportText(e.target.value)}
              placeholder="Paste JSON here..."
              rows={14}
              className="w-full font-mono p-3 rounded-xl resize-none"
              style={{ background: '#171717', color: '#fff', border: 'none', outline: 'none', fontSize: 14 }}
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
    <div className="flex items-center gap-3 py-1.5">
      <span className="text-base w-6 text-center">{icon}</span>
      <span className="flex-1 text-sm font-medium" style={{ color: labelColor ?? '#fff' }}>{label}</span>
      {children}
      {chevron && <span style={{ color: '#444', fontSize: 16 }}>›</span>}
    </div>
  )
}

function SettingsDivider() {
  return <div className="h-px ml-9" style={{ background: '#242424' }} />
}

function Toggle({ value, onChange, accent, accentFg }: {
  value: boolean; onChange: (v: boolean) => void; accent: string; accentFg: string
}) {
  return (
    <button onClick={() => onChange(!value)}
      className="w-12 h-7 rounded-full relative transition-colors shrink-0"
      style={{ background: value ? accent : '#2e2e2e' }}>
      <div className="absolute top-1 w-5 h-5 rounded-full shadow-md transition-transform duration-200"
        style={{
          left: value ? 'calc(100% - 22px)' : '4px',
          background: value ? accentFg : '#666',
          transform: 'translateZ(0)',
        }} />
    </button>
  )
}

function ConfirmModal({ title, message, onConfirm, onCancel, destructive }: {
  title: string; message: string; onConfirm: () => void; onCancel: () => void; destructive?: boolean
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6 anim-backdrop"
      style={{ background: 'rgba(0,0,0,0.65)' }}>
      <div className="rounded-2xl p-5 w-full max-w-xs anim-modal" style={{ background: '#1c1c1e' }}>
        <h3 className="font-bold text-white text-center mb-1">{title}</h3>
        <p className="text-textSecondary text-sm text-center mb-5">{message}</p>
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

import React from 'react'
