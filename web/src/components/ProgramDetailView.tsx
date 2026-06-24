import { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, type WorkoutProgram, type Workout } from '../types'
import { SplitPill, Modal } from './ui'
import { WorkoutEditorSheet } from './WorkoutEditorSheet'
import { CreateSplitSheet } from './CreateSplitSheet'

export function ProgramDetailView({
  program, onBack,
}: {
  program: WorkoutProgram
  onBack: () => void
}) {
  const { deleteWorkout, deleteSplit, settings } = useAppStore()
  const [filterSplitID, setFilterSplitID] = useState<string | null | 'all'>('all')
  const [editingWorkout, setEditingWorkout] = useState<Workout | null | 'new'>(null)
  const [deleteTarget, setDeleteTarget] = useState<Workout | null>(null)
  const [showSplits, setShowSplits] = useState(false)
  const [showCreateSplit, setShowCreateSplit] = useState(false)

  const filteredWorkouts = filterSplitID === 'all'
    ? program.workouts
    : program.workouts.filter(w => w.splitID === filterSplitID)

  const getSplit = (w: Workout) => program.splits.find(s => s.id === w.splitID)

  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)

  return (
    <>
      <div className="anim-right" style={{ background: '#0A0A0A' }}>
        {/* Sticky header */}
        <div className="px-4 safe-top" style={{ position: 'sticky', top: 0, zIndex: 10, background: '#0A0A0A', paddingBottom: 8 }}>
          <div className="flex items-center gap-3 pt-4 mb-3">
            <button onClick={onBack} className="text-textSecondary text-sm">← Back</button>
            <div className="flex-1" />
            <button onClick={() => setShowSplits(true)} className="text-textSecondary text-sm">Splits</button>
          </div>
          <div className="flex items-center gap-3 mb-3">
            <div className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl"
              style={{ background: `#${program.colorHex}22` }}>
              {program.emoji}
            </div>
            <div>
              <h1 className="text-xl font-bold text-white">{program.name}</h1>
              {program.description && <p className="text-sm text-textSecondary">{program.description}</p>}
            </div>
          </div>

          {/* Split filter */}
          <div className="flex gap-2 overflow-x-auto pb-1">
            <button onClick={() => setFilterSplitID('all')}
              className="px-3 py-1 rounded-full text-xs font-bold shrink-0"
              style={{ background: filterSplitID === 'all' ? accent : '#222', color: filterSplitID === 'all' ? accentFg : '#8E8E93' }}>
              All
            </button>
            {program.splits.map(s => (
              <button key={s.id} onClick={() => setFilterSplitID(filterSplitID === s.id ? 'all' : s.id)}
                className="px-3 py-1 rounded-full text-xs font-bold shrink-0"
                style={{ background: filterSplitID === s.id ? `#${s.colorHex}` : '#222', color: '#fff' }}>
                {s.name}
              </button>
            ))}
          </div>
        </div>

        {/* Workout list */}
        <div className="px-4 pb-28">
          {filteredWorkouts.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 gap-3">
              <span className="text-4xl">🏋️</span>
              <p className="text-textSecondary text-sm">No workouts yet</p>
              <button onClick={() => setEditingWorkout('new')}
                className="px-4 py-2 rounded-full text-sm font-semibold"
                style={{ background: accent, color: accentFg }}>
                Add Your First Workout
              </button>
            </div>
          ) : (
            <div className="space-y-3 pt-2">
              {filteredWorkouts.map(w => {
                const split = getSplit(w)
                return (
                  <div key={w.id} className="card"
                    onClick={() => setEditingWorkout(w)}
                    style={{ cursor: 'pointer' }}>
                    <div className="flex items-start justify-between">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1 flex-wrap">
                          <h3 className="font-bold text-white">{w.name}</h3>
                          {split && <SplitPill name={split.name} colorHex={split.colorHex} icon={split.icon} />}
                        </div>
                        <p className="text-sm text-textSecondary">
                          {w.exercises.length} exercise{w.exercises.length !== 1 ? 's' : ''}
                        </p>
                        {w.exercises.length > 0 && (
                          <p className="text-xs text-textSecondary mt-1 truncate">
                            {w.exercises.slice(0, 3).map(e => e.name).filter(Boolean).join(' · ')}
                            {w.exercises.length > 3 ? ' · ...' : ''}
                          </p>
                        )}
                      </div>
                      <button onClick={e => { e.stopPropagation(); setDeleteTarget(w) }}
                        className="ml-2 text-red-500 opacity-50 text-sm p-1">🗑</button>
                    </div>
                  </div>
                )
              })}
            </div>
          )}
        </div>

        {/* FAB */}
        <div className="fixed bottom-0 left-1/2 -translate-x-1/2 w-full max-w-[430px] px-4 pb-6 safe-bottom">
          <button onClick={() => setEditingWorkout('new')}
            className="w-full py-4 rounded-2xl font-bold text-base"
            style={{ background: accent, color: accentFg }}>
            + New Workout
          </button>
        </div>
      </div>

      <WorkoutEditorSheet
        isOpen={editingWorkout !== null}
        onClose={() => setEditingWorkout(null)}
        program={program}
        workout={editingWorkout === 'new' ? null : (editingWorkout as Workout)}
      />

      <Modal
        isOpen={deleteTarget !== null}
        onClose={() => setDeleteTarget(null)}
        title="Delete Workout?"
        message={`"${deleteTarget?.name}" will be permanently deleted.`}
        actions={[{
          label: 'Delete', destructive: true, onClick: () => {
            if (deleteTarget) deleteWorkout(program.id, deleteTarget.id)
            setDeleteTarget(null)
          }
        }]}
      />

      {/* Splits manager */}
      {showSplits && (
        <div className="fixed inset-0 z-40 flex flex-col anim-right" style={{ background: '#0A0A0A' }}>
          <div className="flex items-center justify-between px-4 py-3 border-b safe-top" style={{ borderColor: '#222' }}>
            <button onClick={() => setShowSplits(false)} className="text-textSecondary text-sm">← Back</button>
            <span className="font-semibold text-white text-sm">Manage Splits</span>
            <button onClick={() => { setShowSplits(false); setShowCreateSplit(true) }}
              className="text-sm font-bold" style={{ color: accent }}>
              + New
            </button>
          </div>
          <div className="flex-1 overflow-y-auto px-4 py-4">
            {program.splits.length === 0 ? (
              <p className="text-center text-textSecondary text-sm py-8">No splits yet. Create one!</p>
            ) : (
              <div className="space-y-2">
                {program.splits.map(s => (
                  <div key={s.id} className="card flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full flex items-center justify-center"
                        style={{ background: `#${s.colorHex}33` }}>
                        <div className="w-3 h-3 rounded-full" style={{ background: `#${s.colorHex}` }} />
                      </div>
                      <div>
                        <p className="font-semibold text-white text-sm">{s.name}</p>
                        <p className="text-xs text-textSecondary">
                          {program.workouts.filter(w => w.splitID === s.id).length} workouts
                        </p>
                      </div>
                    </div>
                    <button onClick={() => deleteSplit(program.id, s.id)}
                      className="text-red-500 opacity-70 text-sm">🗑</button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      <CreateSplitSheet
        isOpen={showCreateSplit}
        onClose={() => setShowCreateSplit(false)}
        programID={program.id}
      />
    </>
  )
}
