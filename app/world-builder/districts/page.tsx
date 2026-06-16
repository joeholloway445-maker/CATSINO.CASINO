'use client'
import { useEffect, useState } from 'react'

const WEATHERS = ['clear','foggy','misty','rainy','stormy','snowy']
const TIMES = ['dawn','day','dusk','night']

type District = {
  id: string; display_name: string; description: string; entry_fee: number;
  color_hex: string; max_players: number; ambient_npc_count: number;
  weather: string; time_of_day: string;
}

export default function DistrictsPage() {
  const [districts, setDistricts] = useState<District[]>([])
  const [editing, setEditing] = useState<District | null>(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  useEffect(() => { fetch('/api/world/districts').then(r=>r.json()).then(d=>setDistricts(d.districts||[])) }, [])

  const save = async () => {
    if (!editing) return
    setSaving(true); setMsg('')
    const r = await fetch('/api/world/districts', { method:'PUT', headers:{'Content-Type':'application/json'}, body:JSON.stringify(editing) })
    const d = await r.json()
    if (d.error) { setMsg('Error: '+d.error) } else {
      setMsg('Saved!')
      setDistricts(prev=>prev.map(x=>x.id===editing.id?editing:x))
      setEditing(null)
    }
    setSaving(false)
  }

  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-3xl font-bold mb-2">🗺️ District Editor</h1>
        <p className="text-gray-400 text-sm mb-8">Customize each district — descriptions, colors, weather, and player limits.</p>

        {editing && (
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 mb-8">
            <h2 className="text-xl font-semibold mb-4">Editing: {editing.display_name}</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Display Name</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.display_name} onChange={e=>setEditing({...editing,display_name:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Theme Color (hex)</label>
                <div className="flex gap-2">
                  <input type="color" className="h-10 w-12 rounded cursor-pointer border-0 bg-transparent"
                    value={editing.color_hex} onChange={e=>setEditing({...editing,color_hex:e.target.value})} />
                  <input className="flex-1 bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                    value={editing.color_hex} onChange={e=>setEditing({...editing,color_hex:e.target.value})} />
                </div>
              </div>
              <div className="col-span-2">
                <label className="block text-xs text-gray-400 mb-1">Description (shown to players)</label>
                <textarea className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white h-20 resize-none"
                  value={editing.description} onChange={e=>setEditing({...editing,description:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Entry Fee (Cat Coins, 0 = free)</label>
                <input type="number" min={0} className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.entry_fee} onChange={e=>setEditing({...editing,entry_fee:parseInt(e.target.value)||0})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Max Players</label>
                <input type="number" min={1} max={1000} className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.max_players} onChange={e=>setEditing({...editing,max_players:parseInt(e.target.value)||100})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Ambient NPC Count (background crowds)</label>
                <input type="number" min={0} max={100} className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.ambient_npc_count} onChange={e=>setEditing({...editing,ambient_npc_count:parseInt(e.target.value)||0})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Weather</label>
                <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.weather} onChange={e=>setEditing({...editing,weather:e.target.value})}>
                  {WEATHERS.map(w=><option key={w}>{w}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Time of Day</label>
                <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.time_of_day} onChange={e=>setEditing({...editing,time_of_day:e.target.value})}>
                  {TIMES.map(t=><option key={t}>{t}</option>)}
                </select>
              </div>
            </div>
            <div className="flex gap-3 mt-4">
              <button onClick={save} disabled={saving}
                className="bg-purple-600 hover:bg-purple-500 disabled:opacity-50 px-5 py-2 rounded-xl font-semibold text-sm">
                {saving?'Saving...':'Save District'}
              </button>
              <button onClick={()=>setEditing(null)} className="bg-gray-700 hover:bg-gray-600 px-5 py-2 rounded-xl font-semibold text-sm">Cancel</button>
              {msg && <span className={`text-sm my-auto ${msg.startsWith('Error')?'text-red-400':'text-green-400'}`}>{msg}</span>}
            </div>
          </div>
        )}

        <div className="grid gap-4">
          {districts.map(d=>(
            <div key={d.id} className="bg-gray-900 border border-gray-800 rounded-xl p-5 flex items-center gap-5">
              <div className="w-12 h-12 rounded-xl flex-shrink-0" style={{backgroundColor:d.color_hex}} />
              <div className="flex-1 min-w-0">
                <div className="font-bold text-lg">{d.display_name}</div>
                <div className="text-xs text-gray-400 mt-0.5">{d.weather} · {d.time_of_day} · {d.max_players} max players · {d.ambient_npc_count} crowd NPCs</div>
                <div className="text-sm text-gray-300 mt-1 truncate">{d.description}</div>
              </div>
              <button onClick={()=>setEditing({...d})}
                className="bg-gray-700 hover:bg-gray-600 px-4 py-2 rounded-lg text-sm transition-colors flex-shrink-0">
                Edit
              </button>
            </div>
          ))}
          {districts.length===0 && <div className="text-gray-500 text-center py-12">Loading districts...</div>}
        </div>
      </div>
    </main>
  )
}
