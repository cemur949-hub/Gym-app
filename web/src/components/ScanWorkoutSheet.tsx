import { useState } from 'react'
import { useAppStore } from '../context'
import { hexColor, accentTextColor, newId, type Exercise } from '../types'

const PROMPT = `You are analyzing an image of a workout — handwritten notes, a printed program, a whiteboard, or a screenshot.

Extract every exercise you can see and return ONLY valid JSON in this exact format:
{
  "name": "Workout name, or 'My Workout' if not visible",
  "exercises": [
    {
      "name": "exercise name",
      "sets": 3,
      "reps": "10",
      "weight": "135 lbs",
      "notes": ""
    }
  ]
}

Rules:
- sets must be a number (use 3 if unclear)
- reps is a string (can be "8–12", "AMRAP", "failure", etc.)
- weight is a string or empty string if not shown
- notes captures any extra cues (tempo, grip, etc.)
- Return ONLY the JSON object, absolutely no other text`

async function resizeImage(file: File): Promise<{ data: string; mediaType: 'image/jpeg' }> {
  return new Promise((resolve) => {
    const img = new Image()
    const url = URL.createObjectURL(file)
    img.onload = () => {
      const MAX = 1280
      let { width, height } = img
      if (width > MAX || height > MAX) {
        const scale = MAX / Math.max(width, height)
        width = Math.round(width * scale)
        height = Math.round(height * scale)
      }
      const canvas = document.createElement('canvas')
      canvas.width = width
      canvas.height = height
      canvas.getContext('2d')!.drawImage(img, 0, 0, width, height)
      const data = canvas.toDataURL('image/jpeg', 0.85).split(',')[1]
      URL.revokeObjectURL(url)
      resolve({ data, mediaType: 'image/jpeg' })
    }
    img.src = url
  })
}

interface ScanResult {
  name: string
  exercises: Omit<Exercise, 'id' | 'restSeconds'>[]
}

export function ScanWorkoutSheet({
  isOpen, onClose, onResult,
}: {
  isOpen: boolean
  onClose: () => void
  onResult: (name: string, exercises: Exercise[]) => void
}) {
  const { settings } = useAppStore()
  const accent = hexColor(settings.accentColorHex)
  const accentFg = accentTextColor(settings.accentColorHex)
  const [status, setStatus] = useState<'idle' | 'scanning' | 'error'>('idle')
  const [errorMsg, setErrorMsg] = useState('')

  const handleFile = async (file: File) => {
    if (!settings.anthropicApiKey) {
      setErrorMsg('Add your Anthropic API key in Settings → AI Features first.')
      setStatus('error')
      return
    }
    setStatus('scanning')
    setErrorMsg('')
    try {
      const { data, mediaType } = await resizeImage(file)
      const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': settings.anthropicApiKey,
          'anthropic-version': '2023-06-01',
          'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: JSON.stringify({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 1024,
          messages: [{
            role: 'user',
            content: [
              { type: 'image', source: { type: 'base64', media_type: mediaType, data } },
              { type: 'text', text: PROMPT },
            ],
          }],
        }),
      })
      if (!res.ok) {
        const err = await res.json().catch(() => ({}))
        throw new Error((err as { error?: { message?: string } }).error?.message ?? `API error ${res.status}`)
      }
      const json = await res.json() as { content: { type: string; text: string }[] }
      const text = json.content.find(c => c.type === 'text')?.text ?? ''
      const parsed: ScanResult = JSON.parse(text.trim())
      const exercises: Exercise[] = (parsed.exercises ?? []).map(e => ({
        id: newId(),
        name: e.name ?? '',
        sets: typeof e.sets === 'number' ? e.sets : 3,
        reps: e.reps ?? '10',
        weight: e.weight ?? '',
        restSeconds: 60,
        notes: e.notes ?? '',
      }))
      onResult(parsed.name ?? 'My Workout', exercises)
      setStatus('idle')
    } catch (e) {
      setErrorMsg(e instanceof Error ? e.message : 'Scan failed. Try again.')
      setStatus('error')
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end anim-backdrop"
      style={{ background: 'rgba(0,0,0,0.7)' }}>
      <div className="absolute inset-0" onClick={onClose} />
      <div className="relative rounded-t-2xl overflow-hidden anim-sheet" style={{ background: '#171717' }}>
        <div className="flex items-center justify-between px-4 py-3 border-b" style={{ borderColor: '#222' }}>
          <button onClick={onClose} className="text-textSecondary text-sm">Cancel</button>
          <span className="font-semibold text-white text-sm">Scan Workout</span>
          <div className="w-12" />
        </div>

        <div className="p-6 pb-10 flex flex-col items-center gap-5">
          {status === 'scanning' ? (
            <>
              <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl"
                style={{ background: `${accent}22` }}>
                🖼️
              </div>
              <p className="text-white font-semibold">Reading workout…</p>
              <p className="text-textSecondary text-sm text-center">Claude is extracting exercises from your photo.</p>
              <div className="flex gap-1.5 mt-2">
                {[0, 1, 2].map(i => (
                  <div key={i} className="w-2 h-2 rounded-full"
                    style={{ background: accent, opacity: 0.4, animation: `pulse 1.2s ease-in-out ${i * 0.4}s infinite` }} />
                ))}
              </div>
            </>
          ) : (
            <>
              <div className="w-16 h-16 rounded-2xl flex items-center justify-center text-4xl"
                style={{ background: `${accent}22` }}>
                🖼️
              </div>
              <div className="text-center">
                <p className="text-white font-semibold mb-1">Upload a Workout Photo</p>
                <p className="text-textSecondary text-sm">Select a photo of handwritten notes, a printed program, or a screenshot.</p>
              </div>

              {status === 'error' && (
                <p className="text-sm text-center px-2" style={{ color: '#FF3B30' }}>{errorMsg}</p>
              )}

              <input
                type="file"
                accept="image/*"
                className="hidden"
                id="scan-upload"
                onChange={e => { const f = e.target.files?.[0]; if (f) handleFile(f) }}
              />
              <label htmlFor="scan-upload"
                className="w-full py-4 rounded-2xl font-bold text-base text-center cursor-pointer block"
                style={{ background: accent, color: accentFg }}>
                Choose Photo
              </label>
              <p className="text-xs text-textSecondary text-center">
                Tip: in your photo library, scroll to the bottom to find your most recent photos
              </p>

              {!settings.anthropicApiKey && (
                <p className="text-xs text-center" style={{ color: '#FF9F0A' }}>
                  No API key set — add it in Settings → AI Features
                </p>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  )
}
