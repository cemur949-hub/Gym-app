import React from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor } from '../types'

export function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <p className="text-xs font-bold uppercase tracking-widest text-textSecondary pb-2">
      {children}
    </p>
  )
}

export function DarkTextField({
  placeholder, value, onChange, multiline, rows,
}: {
  placeholder: string
  value: string
  onChange: (v: string) => void
  multiline?: boolean
  rows?: number
}) {
  if (multiline) {
    return (
      <textarea
        placeholder={placeholder}
        value={value}
        onChange={e => onChange(e.target.value)}
        rows={rows ?? 3}
        className="w-full bg-surface rounded-xl px-3 py-2.5 text-white resize-none"
        style={{ background: '#222', fontSize: 16 }}
      />
    )
  }
  return (
    <input
      type="text"
      placeholder={placeholder}
      value={value}
      onChange={e => onChange(e.target.value)}
      className="w-full bg-surface rounded-xl px-3 py-2.5 text-white"
      style={{ background: '#222', fontSize: 16 }}
    />
  )
}

export function AccentButton({
  children, onClick, disabled, className,
}: {
  children: React.ReactNode
  onClick?: () => void
  disabled?: boolean
  className?: string
}) {
  const { settings } = useAppStore()
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`accent-btn font-semibold ${className ?? ''}`}
      style={{
        background: disabled ? '#333' : hexColor(settings.accentColorHex),
        color: disabled ? '#888' : accentTextColor(settings.accentColorHex),
        opacity: disabled ? 0.5 : 1,
      }}
    >
      {children}
    </button>
  )
}

export function Sheet({
  isOpen, onClose, title, children,
}: {
  isOpen: boolean
  onClose: () => void
  title: string
  children: React.ReactNode
}) {
  if (!isOpen) return null
  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end" style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div
        className="absolute inset-0"
        onClick={onClose}
      />
      <div className="relative rounded-t-2xl overflow-hidden flex flex-col anim-sheet"
        style={{ background: '#171717', maxHeight: '92dvh' }}>
        <div className="flex items-center justify-between px-4 py-3 border-b border-divider shrink-0">
          <button onClick={onClose} className="text-textSecondary text-sm">Cancel</button>
          <span className="font-semibold text-white text-sm">{title}</span>
          <div className="w-12" />
        </div>
        <div className="overflow-y-auto">
          {children}
        </div>
      </div>
    </div>
  )
}

export function Modal({
  isOpen, onClose, title, message, actions,
}: {
  isOpen: boolean
  onClose: () => void
  title: string
  message: string
  actions: { label: string; destructive?: boolean; onClick: () => void }[]
}) {
  if (!isOpen) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center px-6"
      style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div className="rounded-2xl p-5 w-full max-w-xs anim-modal" style={{ background: '#1c1c1e' }}>
        <h3 className="font-bold text-white text-center mb-1">{title}</h3>
        <p className="text-textSecondary text-sm text-center mb-4">{message}</p>
        <div className="flex flex-col gap-2">
          {actions.map(a => (
            <button key={a.label} onClick={a.onClick}
              className="py-3 rounded-xl font-semibold text-sm"
              style={{ background: '#2c2c2e', color: a.destructive ? '#ff3b30' : '#fff' }}>
              {a.label}
            </button>
          ))}
          <button onClick={onClose}
            className="py-3 rounded-xl font-semibold text-sm"
            style={{ background: '#2c2c2e', color: '#8E8E93' }}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}

export function SplitPill({ name, colorHex }: { name: string; colorHex: string; icon?: string }) {
  return (
    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold"
      style={{ background: `#${colorHex}33`, color: `#${colorHex}` }}>
      {name}
    </span>
  )
}

export function ColorPicker({
  value, onChange,
}: {
  value: string
  onChange: (hex: string) => void
}) {
  const COLORS = [
    'FFFFFF', '0A84FF', '30D158', '4ECDC4', 'BF5AF2',
    'FF2D55', 'FF3B30', 'FFD60A', '5E5CE6', '32ADE6',
  ]
  return (
    <div className="grid grid-cols-5 gap-2">
      {COLORS.map(hex => (
        <button key={hex} onClick={() => onChange(hex)}
          className="w-10 h-10 rounded-full flex items-center justify-center"
          style={{ background: `#${hex}` }}>
          {value === hex && <span className="text-white text-xs font-bold">✓</span>}
        </button>
      ))}
    </div>
  )
}

export function EmojiPicker({ value, onChange }: { value: string; onChange: (e: string) => void }) {
  const EMOJIS = ['💪', '🏋️', '🔥', '⚡', '🎯', '🏆', '💥', '🦾', '🚀', '⭐', '🎽', '🧠', '🦵', '💯', '🔱']
  return (
    <div className="grid grid-cols-5 gap-2">
      {EMOJIS.map(e => (
        <button key={e} onClick={() => onChange(e)}
          className="w-10 h-10 rounded-xl flex items-center justify-center text-xl"
          style={{ background: value === e ? '#333' : '#222', border: value === e ? '2px solid #fff' : '2px solid transparent' }}>
          {e}
        </button>
      ))}
    </div>
  )
}
