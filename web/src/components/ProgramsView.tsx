import React, { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, newId, type WorkoutProgram } from '../types'
import { DarkTextField, SectionHeader, ColorPicker, EmojiPicker, Modal } from './ui'
import { ProgramDetailView } from './ProgramDetailView'

export function ProgramsView() {
  const { programs, addProgram, updateProgram, deleteProgram, settings } = useAppStore()
  const [selectedProgram, setSelectedProgram] = useState<WorkoutProgram | null>(null)
  const [editing, setEditing] = useState<WorkoutProgram | 'new' | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<WorkoutProgram | null>(null)

  if (selectedProgram) {
    const current = programs.find(p => p.id === selectedProgram.id) ?? selectedProgram
    return <ProgramDetailView program={current} onBack={() => setSelectedProgram(null)} />
  }

  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)

  return (
    <>
      <div style={{ background: '#0A0A0A' }}>
        <div className="px-4 safe-top">
          <div className="flex items-center justify-between py-4">
            <h1 className="text-2xl font-bold text-white">Programs</h1>
            <button onClick={() => setEditing('new')}
              className="w-8 h-8 rounded-full flex items-center justify-center font-bold text-lg"
              style={{ background: accent, color: accentFg }}>+</button>
          </div>
        </div>

        <div className="px-4 pb-6">
          {programs.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-20 gap-4">
              <span className="text-5xl">🏋️</span>
              <p className="text-white font-bold text-lg">No Programs Yet</p>
              <p className="text-textSecondary text-sm text-center">Create your first workout program to get started.</p>
              <button onClick={() => setEditing('new')}
                className="px-6 py-3 rounded-2xl font-semibold"
                style={{ background: accent, color: accentFg }}>
                Create Program
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-3">
              {programs.map(p => (
                <div key={p.id} className="card cursor-pointer relative"
                  onClick={() => setSelectedProgram(p)}
                  style={{ minHeight: 120 }}>
                  <div className="absolute top-2 right-2 flex gap-1">
                    <button onClick={e => { e.stopPropagation(); setEditing(p) }}
                      className="text-textSecondary text-xs p-1">✏️</button>
                    <button onClick={e => { e.stopPropagation(); setDeleteTarget(p) }}
                      className="text-red-500 opacity-60 text-xs p-1">🗑</button>
                  </div>
                  <div className="text-3xl mb-2">{p.emoji}</div>
                  <h3 className="font-bold text-white text-sm leading-tight">{p.name}</h3>
                  {p.description && <p className="text-xs text-textSecondary mt-0.5 truncate">{p.description}</p>}
                  <p className="text-xs text-textSecondary mt-2">
                    {p.workouts.length} workout{p.workouts.length !== 1 ? 's' : ''}
                  </p>
                  {p.splits.length > 0 && (
                    <div className="flex gap-1 flex-wrap mt-1">
                      {p.splits.slice(0, 3).map(s => (
                        <span key={s.id} className="text-xs px-1.5 py-0.5 rounded-full"
                          style={{ background: `#${s.colorHex}33`, color: `#${s.colorHex}` }}>
                          {s.name}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      <ProgramEditorSheet
        isOpen={editing !== null}
        onClose={() => setEditing(null)}
        program={editing === 'new' ? null : (editing as WorkoutProgram)}
        onSave={(p) => {
          if (editing === 'new') addProgram(p)
          else updateProgram(p)
          setEditing(null)
        }}
      />

      <Modal
        isOpen={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        title="Delete Program?"
        message={`"${deleteTarget?.name}" and all its workouts will be permanently deleted.`}
        actions={[{
          label: 'Delete', destructive: true, onClick: () => {
            if (deleteTarget) deleteProgram(deleteTarget.id)
            setDeleteTarget(null)
          }
        }]}
      />
    </>
  )
}

function ProgramEditorSheet({
  isOpen, onClose, program, onSave,
}: {
  isOpen: boolean
  onClose: () => void
  program: WorkoutProgram | null
  onSave: (p: WorkoutProgram) => void
}) {
  const { settings } = useAppStore()
  const [name, setName] = useState(program?.name ?? '')
  const [desc, setDesc] = useState(program?.description ?? '')
  const [emoji, setEmoji] = useState(program?.emoji ?? '💪')
  const [colorHex, setColorHex] = useState(program?.colorHex ?? '0A84FF')
  const [tab, setTab] = useState<'emoji' | 'color'>('emoji')

  React.useEffect(() => {
    if (isOpen) {
      setName(program?.name ?? '')
      setDesc(program?.description ?? '')
      setEmoji(program?.emoji ?? '💪')
      setColorHex(program?.colorHex ?? '0A84FF')
    }
  }, [isOpen, program])

  const save = () => {
    if (!name.trim()) return
    onSave({
      id: program?.id ?? newId(),
      name: name.trim(),
      description: desc,
      emoji,
      colorHex,
      splits: program?.splits ?? [],
      workouts: program?.workouts ?? [],
      createdAt: program?.createdAt ?? new Date().toISOString(),
    })
  }

  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-40 flex flex-col justify-end" style={{ background: 'rgba(0,0,0,0.6)' }}>
      <div className="absolute inset-0" onClick={onClose} />
      <div className="relative rounded-t-2xl overflow-hidden" style={{ background: '#171717', maxHeight: '85dvh' }}>
        <div className="flex items-center justify-between px-4 py-3 border-b border-divider">
          <button onClick={onClose} className="text-textSecondary text-sm">Cancel</button>
          <span className="font-semibold text-white text-sm">{program ? 'Edit Program' : 'New Program'}</span>
          <button onClick={save} disabled={!name.trim()}
            className="text-sm font-bold"
            style={{ color: name.trim() ? accent : '#555' }}>
            {program ? 'Save' : 'Create'}
          </button>
        </div>
        <div className="overflow-y-auto p-4 space-y-4 pb-8">
          <div className="flex justify-center mb-2">
            <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl"
              style={{ background: `#${colorHex}22` }}>
              {emoji}
            </div>
          </div>
          <div>
            <SectionHeader>Program Name</SectionHeader>
            <DarkTextField placeholder="e.g. PPL, 5/3/1, Bro Split..." value={name} onChange={setName} />
          </div>
          <div>
            <SectionHeader>Description (optional)</SectionHeader>
            <DarkTextField placeholder="Short description..." value={desc} onChange={setDesc} />
          </div>
          <div>
            <div className="flex gap-3 mb-3">
              {(['emoji', 'color'] as const).map(t => (
                <button key={t} onClick={() => setTab(t)}
                  className="px-4 py-1.5 rounded-full text-sm font-semibold capitalize"
                  style={{ background: tab === t ? accent : '#222', color: tab === t ? accentFg : '#8E8E93' }}>
                  {t}
                </button>
              ))}
            </div>
            {tab === 'emoji' ? (
              <EmojiPicker value={emoji} onChange={setEmoji} />
            ) : (
              <ColorPicker value={colorHex} onChange={setColorHex} />
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
