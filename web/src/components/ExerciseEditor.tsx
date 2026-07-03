import React, { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, restDisplay, exerciseDisplay, type Exercise } from '../types'

export function ExerciseEditorRow({
  exercise, isExpanded, onTap, onChange, onDelete,
}: {
  exercise: Exercise
  isExpanded: boolean
  onTap: () => void
  onChange: (e: Exercise) => void
  onDelete: () => void
}) {
  const { settings } = useAppStore()
  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)
  const [local, setLocal] = useState(exercise)

  const update = (patch: Partial<Exercise>) => {
    const updated = { ...local, ...patch }
    setLocal(updated)
    onChange(updated)
  }

  return (
    <div className="card-surface overflow-hidden" style={{ background: '#222' }}>
      <div className="flex items-center gap-3 px-3.5 py-2.5 cursor-pointer" onClick={onTap}>
        <span className="text-base" style={{ color: isExpanded ? accent : '#8E8E93' }}>
          {isExpanded ? '▼' : '▶'}
        </span>
        <div className="flex-1 min-w-0">
          {local.name ? (
            <>
              <p className="font-semibold text-sm text-white truncate">{local.name}</p>
              <p className="text-xs text-textSecondary">{exerciseDisplay(local)}</p>
            </>
          ) : (
            <p className="text-sm text-textSecondary">New Exercise</p>
          )}
        </div>
        <button onClick={e => { e.stopPropagation(); onDelete() }} className="p-2 text-red-500 opacity-70 text-sm">🗑</button>
      </div>

      {isExpanded && (
        <div className="px-3.5 pb-3.5 pt-0 border-t border-divider">
          <div className="space-y-3 pt-3">
            <FieldRow label="Exercise Name">
              <input value={local.name} onChange={e => update({ name: e.target.value })}
                placeholder="e.g. Bench Press" style={{ background: '#171717', color: '#fff', borderRadius: 10, padding: '8px 12px', width: '100%', border: 'none', outline: 'none', fontSize: 16 }} />
            </FieldRow>

            <div className="flex gap-3">
              <FieldRow label="Sets" className="flex-1">
                <div className="flex items-center gap-2">
                  <button onClick={() => update({ sets: Math.max(1, local.sets - 1) })}
                    className="w-7 h-7 rounded-full flex items-center justify-center text-white text-sm font-bold"
                    style={{ background: '#171717' }}>−</button>
                  <span className="font-bold text-white text-base w-6 text-center">{local.sets}</span>
                  <button onClick={() => update({ sets: local.sets + 1 })}
                    className="w-7 h-7 rounded-full flex items-center justify-center text-white text-sm font-bold"
                    style={{ background: accent, color: accentFg }}>+</button>
                </div>
              </FieldRow>
              <FieldRow label="Reps" className="flex-1">
                <input value={local.reps} onChange={e => update({ reps: e.target.value })}
                  placeholder="10 or 8-12" style={{ background: '#171717', color: '#fff', borderRadius: 10, padding: '8px 12px', width: '100%', border: 'none', outline: 'none', fontSize: 16 }} />
              </FieldRow>
            </div>

            <FieldRow label="Weight (optional)">
              <input value={local.weight} onChange={e => update({ weight: e.target.value })}
                placeholder="135 lbs, 60 kg..." style={{ background: '#171717', color: '#fff', borderRadius: 10, padding: '8px 12px', width: '100%', border: 'none', outline: 'none', fontSize: 16 }} />
            </FieldRow>

            <FieldRow label={`Rest: ${restDisplay(local.restSeconds)}`}>
              <input type="range" min={0} max={300} step={15} value={local.restSeconds}
                onChange={e => update({ restSeconds: Number(e.target.value) })}
                className="w-full" style={{ accentColor: accent }} />
            </FieldRow>

            <FieldRow label="Notes (optional)">
              <input value={local.notes} onChange={e => update({ notes: e.target.value })}
                placeholder="Cues, form tips..." style={{ background: '#171717', color: '#fff', borderRadius: 10, padding: '8px 12px', width: '100%', border: 'none', outline: 'none', fontSize: 16 }} />
            </FieldRow>
          </div>
        </div>
      )}
    </div>
  )
}

function FieldRow({ label, children, className }: { label: string; children: React.ReactNode; className?: string }) {
  return (
    <div className={className}>
      <p className="text-xs text-textSecondary mb-1">{label}</p>
      {children}
    </div>
  )
}
