import { useState, useEffect, useCallback } from 'react'
import type { WorkoutProgram, AppSettings, Workout, WorkoutSplit } from './types'
import { newId } from './types'

const PROGRAMS_KEY = 'gymtracker_programs_v1'
const SETTINGS_KEY = 'gymtracker_settings_v1'

function sampleData(): WorkoutProgram[] {
  const pushSplit: WorkoutSplit = { id: newId(), name: 'Push', colorHex: '0A84FF', icon: 'flame' }
  const pullSplit: WorkoutSplit = { id: newId(), name: 'Pull', colorHex: '30D158', icon: 'activity' }
  const legsSplit: WorkoutSplit = { id: newId(), name: 'Legs', colorHex: 'BF5AF2', icon: 'bolt' }

  return [{
    id: newId(),
    name: 'My Program',
    description: 'Push Pull Legs',
    emoji: '💪',
    colorHex: '0A84FF',
    splits: [pushSplit, pullSplit, legsSplit],
    createdAt: new Date().toISOString(),
    workouts: [
      {
        id: newId(),
        name: 'Push Day',
        splitID: pushSplit.id,
        notes: '',
        createdAt: new Date().toISOString(),
        exercises: [
          { id: newId(), name: 'Bench Press', sets: 4, reps: '8', weight: '135 lbs', restSeconds: 120, notes: '' },
          { id: newId(), name: 'Overhead Press', sets: 3, reps: '10', weight: '95 lbs', restSeconds: 90, notes: '' },
          { id: newId(), name: 'Tricep Pushdown', sets: 3, reps: '12', weight: '50 lbs', restSeconds: 60, notes: '' },
        ],
      },
      {
        id: newId(),
        name: 'Pull Day',
        splitID: pullSplit.id,
        notes: '',
        createdAt: new Date().toISOString(),
        exercises: [
          { id: newId(), name: 'Deadlift', sets: 4, reps: '5', weight: '225 lbs', restSeconds: 180, notes: '' },
          { id: newId(), name: 'Pull Ups', sets: 3, reps: '8', weight: 'Bodyweight', restSeconds: 90, notes: '' },
          { id: newId(), name: 'Barbell Row', sets: 3, reps: '10', weight: '135 lbs', restSeconds: 90, notes: '' },
        ],
      },
    ],
  }]
}

function loadPrograms(): WorkoutProgram[] {
  try {
    const raw = localStorage.getItem(PROGRAMS_KEY)
    if (raw) return JSON.parse(raw)
  } catch {}
  return sampleData()
}

const DEFAULT_SETTINGS: AppSettings = {
  accentColorHex: 'FFFFFF',
  weightUnit: 'lbs',
  showRestTimes: true,
  anthropicApiKey: '',
}

function loadSettings(): AppSettings {
  try {
    const raw = localStorage.getItem(SETTINGS_KEY)
    if (raw) {
      const parsed = JSON.parse(raw)
      if (parsed.accentColorHex === 'FF6B35') parsed.accentColorHex = 'FFFFFF'
      // Merge so fields added after the user's first visit get defaults
      return { ...DEFAULT_SETTINGS, ...parsed }
    }
  } catch {}
  return DEFAULT_SETTINGS
}

function savePrograms(programs: WorkoutProgram[]) {
  localStorage.setItem(PROGRAMS_KEY, JSON.stringify(programs))
}

function saveSettings(settings: AppSettings) {
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings))
}

export function useStore() {
  const [programs, setPrograms] = useState<WorkoutProgram[]>(loadPrograms)
  const [settings, setSettings] = useState<AppSettings>(loadSettings)

  useEffect(() => { savePrograms(programs) }, [programs])
  useEffect(() => { saveSettings(settings) }, [settings])

  const addProgram = useCallback((p: WorkoutProgram) => {
    setPrograms(prev => [...prev, p])
  }, [])

  const updateProgram = useCallback((p: WorkoutProgram) => {
    setPrograms(prev => prev.map(x => x.id === p.id ? p : x))
  }, [])

  const deleteProgram = useCallback((id: string) => {
    setPrograms(prev => prev.filter(x => x.id !== id))
  }, [])

  const addWorkout = useCallback((programID: string, w: Workout) => {
    setPrograms(prev => prev.map(p =>
      p.id === programID ? { ...p, workouts: [...p.workouts, w] } : p
    ))
  }, [])

  const updateWorkout = useCallback((programID: string, w: Workout) => {
    setPrograms(prev => prev.map(p =>
      p.id === programID ? { ...p, workouts: p.workouts.map(x => x.id === w.id ? w : x) } : p
    ))
  }, [])

  const deleteWorkout = useCallback((programID: string, workoutID: string) => {
    setPrograms(prev => prev.map(p =>
      p.id === programID ? { ...p, workouts: p.workouts.filter(x => x.id !== workoutID) } : p
    ))
  }, [])

  const addSplit = useCallback((programID: string, split: WorkoutSplit) => {
    setPrograms(prev => prev.map(p =>
      p.id === programID ? { ...p, splits: [...p.splits, split] } : p
    ))
  }, [])

  const deleteSplit = useCallback((programID: string, splitID: string) => {
    setPrograms(prev => prev.map(p => {
      if (p.id !== programID) return p
      return {
        ...p,
        splits: p.splits.filter(s => s.id !== splitID),
        workouts: p.workouts.map(w => w.splitID === splitID ? { ...w, splitID: null } : w),
      }
    }))
  }, [])

  const updateSettings = useCallback((s: Partial<AppSettings>) => {
    setSettings(prev => ({ ...prev, ...s }))
  }, [])

  const exportJSON = useCallback(() => JSON.stringify(programs, null, 2), [programs])

  const importJSON = useCallback((json: string) => {
    const data = JSON.parse(json)
    if (!Array.isArray(data)) throw new Error('Invalid format')
    const valid = data.every((p: unknown) =>
      p !== null && typeof p === 'object' &&
      typeof (p as WorkoutProgram).id === 'string' &&
      typeof (p as WorkoutProgram).name === 'string' &&
      Array.isArray((p as WorkoutProgram).workouts) &&
      Array.isArray((p as WorkoutProgram).splits)
    )
    if (!valid) throw new Error('Invalid format')
    setPrograms(data)
  }, [])

  const clearAll = useCallback(() => {
    setPrograms([])
  }, [])

  return {
    programs, settings,
    addProgram, updateProgram, deleteProgram,
    addWorkout, updateWorkout, deleteWorkout,
    addSplit, deleteSplit,
    updateSettings,
    exportJSON, importJSON, clearAll,
  }
}

export type Store = ReturnType<typeof useStore>
