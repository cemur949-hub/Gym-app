export interface Exercise {
  id: string
  name: string
  sets: number
  reps: string
  weight: string
  restSeconds: number
  notes: string
}

export interface WorkoutSplit {
  id: string
  name: string
  colorHex: string
  icon: string
}

export interface Workout {
  id: string
  name: string
  splitID: string | null
  exercises: Exercise[]
  notes: string
  createdAt: string
}

export interface WorkoutProgram {
  id: string
  name: string
  description: string
  emoji: string
  colorHex: string
  splits: WorkoutSplit[]
  workouts: Workout[]
  createdAt: string
}

export interface AppSettings {
  accentColorHex: string
  weightUnit: 'lbs' | 'kg'
  showRestTimes: boolean
}

export const PRESET_COLORS = [
  { name: 'Orange', hex: 'FF6B35' },
  { name: 'Red', hex: 'FF3B30' },
  { name: 'Pink', hex: 'FF2D55' },
  { name: 'Purple', hex: 'BF5AF2' },
  { name: 'Indigo', hex: '5E5CE6' },
  { name: 'Blue', hex: '0A84FF' },
  { name: 'Teal', hex: '4ECDC4' },
  { name: 'Green', hex: '30D158' },
  { name: 'Yellow', hex: 'FFD60A' },
  { name: 'Cyan', hex: '32ADE6' },
]

export const SPLIT_ICONS = [
  'dumbbell', 'bolt', 'flame', 'star', 'heart', 'tag',
  'arrow-up', 'activity', 'target', 'zap', 'shield', 'award',
]

export function newId() {
  return crypto.randomUUID()
}

export function newExercise(): Exercise {
  return { id: newId(), name: '', sets: 3, reps: '10', weight: '', restSeconds: 60, notes: '' }
}

export function hexColor(hex: string) {
  return `#${hex}`
}

export function restDisplay(seconds: number) {
  if (seconds === 0) return 'No rest'
  if (seconds < 60) return `${seconds}s`
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  return s ? `${m}m ${s}s` : `${m}m`
}

export function exerciseDisplay(ex: Exercise) {
  const parts = [`${ex.sets} × ${ex.reps}`]
  if (ex.weight) parts.push(`@ ${ex.weight}`)
  return parts.join(' ')
}
