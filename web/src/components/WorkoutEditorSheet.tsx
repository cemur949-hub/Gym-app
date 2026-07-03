import React, { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, newId, newExercise, type Workout, type WorkoutProgram, type Exercise } from '../types'
import { DarkTextField, SectionHeader } from './ui'
import { ExerciseEditorRow } from './ExerciseEditor'
import { CreateSplitSheet } from './CreateSplitSheet'

export function WorkoutEditorSheet({
  isOpen, onClose, program, workout, scanData,
}: {
  isOpen: boolean
  onClose: () => void
  program: WorkoutProgram
  workout: Workout | null
  scanData?: { name: string; exercises: Exercise[] } | null
}) {
  const { addWorkout, updateWorkout, settings } = useAppStore()
  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)
  const [name, setName] = useState(workout?.name ?? '')
  const [splitID, setSplitID] = useState<string | null>(workout?.splitID ?? null)
  const [notes, setNotes] = useState(workout?.notes ?? '')
  const [exercises, setExercises] = useState<Exercise[]>(workout?.exercises ?? [])
  const [expandedID, setExpandedID] = useState<string | null>(null)
  const [showCreateSplit, setShowCreateSplit] = useState(false)

  React.useEffect(() => {
    if (isOpen) {
      setName(workout?.name ?? scanData?.name ?? '')
      setSplitID(workout?.splitID ?? null)
      setNotes(workout?.notes ?? '')
      setExercises(workout?.exercises ?? scanData?.exercises ?? [])
      setExpandedID(null)
    }
  }, [isOpen, workout, scanData])

  const canSave = name.trim().length > 0

  const save = () => {
    if (!canSave) return
    const w: Workout = {
      id: workout?.id ?? newId(),
      name: name.trim(),
      splitID,
      notes,
      exercises,
      createdAt: workout?.createdAt ?? new Date().toISOString(),
    }
    if (workout) updateWorkout(program.id, w)
    else addWorkout(program.id, w)
    onClose()
  }

  const addEx = () => {
    const ex = newExercise()
    setExercises(prev => [...prev, ex])
    setExpandedID(ex.id)
  }

  if (!isOpen) return null

  return (
    <>
      <div className="fixed inset-0 z-40 flex flex-col anim-right" style={{ background: '#0A0A0A' }}>
        <div className="flex items-center justify-between px-4 py-3 border-b border-divider shrink-0 safe-top">
          <button onClick={onClose} className="text-textSecondary text-sm">Cancel</button>
          <span className="font-semibold text-white text-sm">{workout ? 'Edit Workout' : 'New Workout'}</span>
          <button onClick={save} disabled={!canSave}
            className="text-sm font-bold"
            style={{ color: canSave ? accent : '#555' }}>
            {workout ? 'Save' : 'Add'}
          </button>
        </div>

        <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4"
          style={{ paddingBottom: 'calc(env(safe-area-inset-bottom, 16px) + 32px)' }}>
          {/* Workout info */}
          <div className="card space-y-3">
            <SectionHeader>Workout Info</SectionHeader>
            <DarkTextField placeholder="Workout name (e.g. Push Day)" value={name} onChange={setName} />

            <div>
              <SectionHeader>Split Tag</SectionHeader>
              <div className="flex gap-2 overflow-x-auto pb-1">
                <button onClick={() => setSplitID(null)}
                  className="px-3.5 py-1.5 rounded-full text-sm font-bold shrink-0"
                  style={{ background: splitID === null ? accent : '#222', color: splitID === null ? accentFg : '#8E8E93' }}>
                  None
                </button>
                {program.splits.map(s => (
                  <button key={s.id} onClick={() => setSplitID(s.id)}
                    className="px-3.5 py-1.5 rounded-full text-sm font-bold shrink-0"
                    style={{ background: splitID === s.id ? `#${s.colorHex}` : '#222', color: splitID === s.id ? accentTextColor(s.colorHex) : '#8E8E93' }}>
                    {s.name}
                  </button>
                ))}
                <button onClick={() => setShowCreateSplit(true)}
                  className="px-3.5 py-1.5 rounded-full text-sm font-bold shrink-0 border"
                  style={{ background: '#222', color: accent, borderColor: `${accent}66` }}>
                  + New Split
                </button>
              </div>
            </div>
          </div>

          {/* Exercises */}
          <div className="card space-y-3">
            <div className="flex items-center justify-between">
              <SectionHeader>Exercises</SectionHeader>
              <span className="text-xs font-bold px-2 py-0.5 rounded-full"
                style={{ background: `${accent}22`, color: accent }}>
                {exercises.length}
              </span>
            </div>

            {exercises.length === 0 && (
              <p className="text-center text-textSecondary text-sm py-4">No exercises added yet</p>
            )}

            <div className="space-y-2">
              {exercises.map(ex => (
                <ExerciseEditorRow
                  key={ex.id}
                  exercise={ex}
                  isExpanded={expandedID === ex.id}
                  onTap={() => setExpandedID(expandedID === ex.id ? null : ex.id)}
                  onChange={updated => setExercises(prev => prev.map(e => e.id === updated.id ? updated : e))}
                  onDelete={() => {
                    setExercises(prev => prev.filter(e => e.id !== ex.id))
                    if (expandedID === ex.id) setExpandedID(null)
                  }}
                />
              ))}
            </div>

            <button onClick={addEx}
              className="w-full py-3.5 rounded-2xl flex items-center justify-center gap-2 text-sm font-bold border"
              style={{ background: '#222', color: '#fff', borderColor: '#333' }}>
              <span style={{ color: accent }}>⊕</span> Add Exercise
            </button>
          </div>

          {/* Notes */}
          {exercises.length > 0 && (
            <div className="card space-y-2">
              <SectionHeader>Notes</SectionHeader>
              <DarkTextField placeholder="Workout notes, instructions..." value={notes} onChange={setNotes} multiline rows={3} />
            </div>
          )}
        </div>
      </div>

      <CreateSplitSheet
        isOpen={showCreateSplit}
        onClose={() => setShowCreateSplit(false)}
        programID={program.id}
      />
    </>
  )
}
