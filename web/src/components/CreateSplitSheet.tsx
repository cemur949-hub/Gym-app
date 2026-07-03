import { useState, useEffect } from 'react'
import { useAppStore } from '../context'
import { hexColor, newId, type WorkoutSplit } from '../types'
import { DarkTextField, SectionHeader, ColorPicker, AccentButton } from './ui'

const ICONS = ['🔥', '⚡', '💪', '🎯', '🏆', '⭐', '💥', '🦾', '🚀', '🔱', '🛡️', '🎽']

export function CreateSplitSheet({
  isOpen, onClose, programID,
}: {
  isOpen: boolean
  onClose: () => void
  programID: string
}) {
  const { addSplit, settings } = useAppStore()
  const accent = hexColor(settings.accentColorHex)
  const [name, setName] = useState('')
  const [colorHex, setColorHex] = useState('0A84FF')
  const [icon, setIcon] = useState('🔥')

  useEffect(() => {
    if (isOpen) {
      setName('')
      setColorHex('0A84FF')
      setIcon('🔥')
    }
  }, [isOpen])

  const create = () => {
    if (!name.trim()) return
    const split: WorkoutSplit = { id: newId(), name: name.trim(), colorHex, icon }
    addSplit(programID, split)
    setName('')
    setColorHex('0A84FF')
    setIcon('🔥')
    onClose()
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end anim-backdrop" style={{ background: 'rgba(0,0,0,0.7)' }}>
      <div className="absolute inset-0" onClick={onClose} />
      <div className="relative rounded-t-2xl overflow-hidden anim-sheet" style={{ background: '#171717' }}>
        <div className="flex items-center justify-between px-4 py-3 border-b border-divider">
          <button onClick={onClose} className="text-textSecondary text-sm">Cancel</button>
          <span className="font-semibold text-white text-sm">New Split</span>
          <button onClick={create} disabled={!name.trim()}
            className="text-sm font-bold" style={{ color: accent, opacity: name.trim() ? 1 : 0.4 }}>
            Create
          </button>
        </div>
        <div className="p-4 space-y-4"
          style={{ paddingBottom: 'calc(env(safe-area-inset-bottom, 16px) + 16px)' }}>
          <div>
            <SectionHeader>Split Name</SectionHeader>
            <DarkTextField placeholder="e.g. Push Day, Upper Body..." value={name} onChange={setName} />
          </div>
          <div>
            <SectionHeader>Color</SectionHeader>
            <ColorPicker value={colorHex} onChange={setColorHex} />
          </div>
          <div>
            <SectionHeader>Icon</SectionHeader>
            <div className="grid grid-cols-6 gap-2">
              {ICONS.map(i => (
                <button key={i} onClick={() => setIcon(i)}
                  className="w-10 h-10 rounded-xl text-xl flex items-center justify-center"
                  style={{ background: icon === i ? '#333' : '#222', border: icon === i ? '2px solid #fff' : '2px solid transparent' }}>
                  {i}
                </button>
              ))}
            </div>
          </div>
          <div className="pb-6">
            <AccentButton onClick={create} disabled={!name.trim()}>Create Split</AccentButton>
          </div>
        </div>
      </div>
    </div>
  )
}
