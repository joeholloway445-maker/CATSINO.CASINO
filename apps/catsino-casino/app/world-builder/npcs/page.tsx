'use client'
import { useEffect, useState } from 'react'

const DISTRICTS = ['paw_vegas','neon_alley','cat_coliseum','cat_forest','arcade_galaxy']
const FACTIONS = ['SovereignCrown','WildlandsAscendant','VeiledCurrent','Factionless']
const ROLES = ['shopkeeper','quest_giver','dealer','race_coordinator','tournament_master','healer','lore_keeper','ambient']

type NPC = {
  id: string; name: string; district: string; role: string; faction: string;
  emoji: string; greeting: string; shop_id: string; dialogue_id: string;
  pos_x: number; pos_y: number; pos_z: number;
}

const BLANK: NPC = { id:'', name:'', district:'paw_vegas', role:'ambient', faction:'Factionless', emoji:'🐱', greeting:'Hello!', shop_id:'', dialogue_id:'', pos_x:0, pos_y:0, pos_z:0 }

export default function NPCsPage() {
  const [npcs, setNpcs] = useState<NPC[]>([])
  const [editing, setEditing] = useState<NPC | null>(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  useEffect(() => { fetch('/api/world/npcs').then(r=>r.json()).then(d=>setNpcs(d.npcs||[])) }, [])

  const save = async () => {
    if (!editing) return
    setSaving(true); setMsg('')
    const r = await fetch('/api/world/npcs', { method: editing.id ? 'PUT' : 'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify(editing) })
    const d = await r.json()
    if (d.error) { setMsg('Error: ' + d.error) } else {
      setMsg('Saved!')
      setNpcs(prev => editing.id ? prev.map(n=>n.id===editing.id ? editing : n) : [...prev, {...editing, id: d.id}])
      setEditing(null)
    }
    setSaving(false)
  }

  const del = async (id: string) => {
    if (!confirm('Delete this NPC?')) return
    await fetch('/api/world/npcs?id='+id, { method:'DELETE' })
    setNpcs(prev => prev.filter(n=>n.id!==id))
  }

  const F = ({label, field, type='text', opts}: {label:string, field:keyof NPC, type?:string, opts?:string[]}) => (
    <div>
      <label className="block text-xs text-gray-400 mb-1">{label}</label>
      {opts ? (
        <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
          value={editing![field] as string} onChange={e=>setEditing({...editing!, [field]: e.target.value})}>
          {opts.map(o=><option key={o}>{o}</option>)}
        </select>
      ) : (
        <input type={type} className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
          value={editing![field] as string} onChange={e=>setEditing({...editing!, [field]: type==='number'?parseFloat(e.target.value):e.target.value})} />
      )}
    </div>
  )

  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">🐱 NPC Editor</h1>
            <p className="text-gray-400 text-sm mt-1">Add and edit characters that appear in each district.</p>
          </div>
          <button onClick={()=>setEditing({...BLANK})}
            className="bg-blue-600 hover:bg-blue-500 px-4 py-2 rounded-xl font-semibold text-sm transition-colors">
            + Add NPC
          </button>
        </div>

        {editing && (
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 mb-8">
            <h2 className="text-xl font-semibold mb-4">{editing.id ? 'Edit NPC' : 'New NPC'}</h2>
            <div className="grid grid-cols-2 gap-4">
              <F label="NPC ID (no spaces, e.g. npc_my_cat)" field="id" />
              <F label="Display Name" field="name" />
              <F label="Emoji (copy-paste any emoji)" field="emoji" />
              <F label="District" field="district" opts={DISTRICTS} />
              <F label="Role" field="role" opts={ROLES} />
              <F label="Faction" field="faction" opts={FACTIONS} />
              <div className="col-span-2">
                <label className="block text-xs text-gray-400 mb-1">Greeting (first thing they say)</label>
                <textarea className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white h-20 resize-none"
                  value={editing.greeting} onChange={e=>setEditing({...editing, greeting:e.target.value})} />
              </div>
              <F label="Shop ID (leave blank if no shop)" field="shop_id" />
              <F label="Dialogue ID (must match dialogue.json)" field="dialogue_id" />
              <F label="Position X" field="pos_x" type="number" />
              <F label="Position Z" field="pos_z" type="number" />
            </div>
            <div className="flex gap-3 mt-4">
              <button onClick={save} disabled={saving}
                className="bg-green-600 hover:bg-green-500 disabled:opacity-50 px-5 py-2 rounded-xl font-semibold text-sm transition-colors">
                {saving ? 'Saving...' : 'Save NPC'}
              </button>
              <button onClick={()=>setEditing(null)}
                className="bg-gray-700 hover:bg-gray-600 px-5 py-2 rounded-xl font-semibold text-sm transition-colors">
                Cancel
              </button>
              {msg && <span className={`text-sm my-auto ${msg.startsWith('Error') ? 'text-red-400' : 'text-green-400'}`}>{msg}</span>}
            </div>
          </div>
        )}

        <div className="grid gap-3">
          {npcs.map(n=>(
            <div key={n.id} className="bg-gray-900 border border-gray-800 rounded-xl px-5 py-4 flex items-center gap-4">
              <span className="text-3xl">{n.emoji}</span>
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{n.name}</div>
                <div className="text-xs text-gray-400">{n.role} · {n.district} · {n.faction}</div>
                <div className="text-xs text-gray-500 truncate mt-0.5">"{n.greeting}"</div>
              </div>
              <div className="flex gap-2">
                <button onClick={()=>setEditing({...n})} className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded-lg text-xs transition-colors">Edit</button>
                <button onClick={()=>del(n.id)} className="bg-red-900 hover:bg-red-800 px-3 py-1.5 rounded-lg text-xs transition-colors">Delete</button>
              </div>
            </div>
          ))}
          {npcs.length===0 && <div className="text-gray-500 text-center py-12">No NPCs yet — click "+ Add NPC" to create your first character.</div>}
        </div>
      </div>
    </main>
  )
}
