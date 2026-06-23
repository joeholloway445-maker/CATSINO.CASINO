'use client'
import { useEffect, useState } from 'react'

const DISTRICTS = ['paw_vegas','neon_alley','cat_coliseum','cat_forest','arcade_galaxy']
const TYPES = ['main','side','daily','faction']
const OBJ_TYPES = ['spin','win_game','play_game','win_combat','win_race','visit_district','complete_quest','puzzle_score','play_blackjack','summon_companion']

type Objective = { id: string; description: string; type: string; target: number; district?: string }
type Quest = {
  id: string; title: string; type: string; description: string; giver_npc: string;
  district: string; prerequisites: string; objectives: Objective[];
  reward_coins: number; reward_xp: number; unlock_companion: string; next_quest: string;
}

const BLANK_OBJ = (): Objective => ({ id: 'obj_' + Date.now(), description: '', type: 'win_game', target: 1 })
const BLANK: Quest = { id:'', title:'', type:'side', description:'', giver_npc:'', district:'paw_vegas', prerequisites:'', objectives:[BLANK_OBJ()], reward_coins:500, reward_xp:100, unlock_companion:'', next_quest:'' }

export default function QuestsPage() {
  const [quests, setQuests] = useState<Quest[]>([])
  const [editing, setEditing] = useState<Quest | null>(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  useEffect(() => { fetch('/api/world/quests').then(r=>r.json()).then(d=>setQuests(d.quests||[])) }, [])

  const save = async () => {
    if (!editing) return
    setSaving(true); setMsg('')
    const payload = { ...editing, prerequisites: editing.prerequisites.split(',').map(s=>s.trim()).filter(Boolean) }
    const r = await fetch('/api/world/quests', { method: editing.id?'PUT':'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload) })
    const d = await r.json()
    if (d.error) { setMsg('Error: '+d.error) } else {
      setMsg('Saved!')
      setQuests(prev=>editing.id ? prev.map(q=>q.id===editing.id?editing:q) : [...prev, editing])
      setEditing(null)
    }
    setSaving(false)
  }

  const addObj = () => setEditing(e=>e ? {...e, objectives:[...e.objectives, BLANK_OBJ()]} : e)
  const removeObj = (i:number) => setEditing(e=>e ? {...e, objectives:e.objectives.filter((_,j)=>j!==i)} : e)
  const updateObj = (i:number, field:keyof Objective, val:unknown) =>
    setEditing(e=>e ? {...e, objectives:e.objectives.map((o,j)=>j===i?{...o,[field]:val}:o)} : e)

  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">📋 Quest Editor</h1>
            <p className="text-gray-400 text-sm mt-1">Create quests with objectives, rewards, and story chains.</p>
          </div>
          <button onClick={()=>setEditing({...BLANK, objectives:[BLANK_OBJ()]})}
            className="bg-green-600 hover:bg-green-500 px-4 py-2 rounded-xl font-semibold text-sm transition-colors">
            + New Quest
          </button>
        </div>

        {editing && (
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 mb-8">
            <h2 className="text-xl font-semibold mb-4">{editing.id?'Edit Quest':'New Quest'}</h2>
            <div className="grid grid-cols-2 gap-4">
              {([['Quest ID (no spaces)', 'id'], ['Quest Title', 'title']] as const).map(([l,f])=>(
                <div key={f}>
                  <label className="block text-xs text-gray-400 mb-1">{l}</label>
                  <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                    value={editing[f]} onChange={e=>setEditing({...editing,[f]:e.target.value})} />
                </div>
              ))}
              <div>
                <label className="block text-xs text-gray-400 mb-1">Type</label>
                <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.type} onChange={e=>setEditing({...editing,type:e.target.value})}>
                  {TYPES.map(t=><option key={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">District</label>
                <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.district} onChange={e=>setEditing({...editing,district:e.target.value})}>
                  {DISTRICTS.map(d=><option key={d}>{d}</option>)}
                </select>
              </div>
              <div className="col-span-2">
                <label className="block text-xs text-gray-400 mb-1">Description (shown to players)</label>
                <textarea className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white h-16 resize-none"
                  value={editing.description} onChange={e=>setEditing({...editing,description:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Giver NPC ID (who gives this quest)</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.giver_npc} onChange={e=>setEditing({...editing,giver_npc:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Prerequisites (quest IDs, comma-separated)</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  placeholder="e.g. main_001, side_002"
                  value={editing.prerequisites} onChange={e=>setEditing({...editing,prerequisites:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Reward: Cat Chips 🪙</label>
                <input type="number" className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.reward_coins} onChange={e=>setEditing({...editing,reward_coins:parseInt(e.target.value)||0})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Reward: XP ⭐</label>
                <input type="number" className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.reward_xp} onChange={e=>setEditing({...editing,reward_xp:parseInt(e.target.value)||0})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Unlock Companion ID (optional)</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  placeholder="e.g. FL001" value={editing.unlock_companion} onChange={e=>setEditing({...editing,unlock_companion:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Next Quest ID (chains to this quest)</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.next_quest} onChange={e=>setEditing({...editing,next_quest:e.target.value})} />
              </div>
            </div>

            <div className="mt-5">
              <div className="flex items-center justify-between mb-3">
                <h3 className="font-semibold text-sm">Objectives (steps players must complete)</h3>
                <button onClick={addObj} className="text-blue-400 text-xs hover:text-blue-300">+ Add Step</button>
              </div>
              {editing.objectives.map((obj,i)=>(
                <div key={obj.id} className="bg-gray-800 rounded-xl p-4 mb-2 grid grid-cols-4 gap-3">
                  <div className="col-span-2">
                    <label className="block text-xs text-gray-400 mb-1">Step Description</label>
                    <input className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                      value={obj.description} onChange={e=>updateObj(i,'description',e.target.value)} />
                  </div>
                  <div>
                    <label className="block text-xs text-gray-400 mb-1">Type</label>
                    <select className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                      value={obj.type} onChange={e=>updateObj(i,'type',e.target.value)}>
                      {OBJ_TYPES.map(t=><option key={t}>{t}</option>)}
                    </select>
                  </div>
                  <div className="flex gap-2">
                    <div className="flex-1">
                      <label className="block text-xs text-gray-400 mb-1">Target #</label>
                      <input type="number" min={1} className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                        value={obj.target} onChange={e=>updateObj(i,'target',parseInt(e.target.value)||1)} />
                    </div>
                    <button onClick={()=>removeObj(i)} className="mt-5 text-red-400 hover:text-red-300 text-xs">✕</button>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex gap-3 mt-4">
              <button onClick={save} disabled={saving}
                className="bg-green-600 hover:bg-green-500 disabled:opacity-50 px-5 py-2 rounded-xl font-semibold text-sm">
                {saving?'Saving...':'Save Quest'}
              </button>
              <button onClick={()=>setEditing(null)} className="bg-gray-700 hover:bg-gray-600 px-5 py-2 rounded-xl font-semibold text-sm">Cancel</button>
              {msg && <span className={`text-sm my-auto ${msg.startsWith('Error')?'text-red-400':'text-green-400'}`}>{msg}</span>}
            </div>
          </div>
        )}

        <div className="grid gap-3">
          {quests.map(q=>(
            <div key={q.id} className="bg-gray-900 border border-gray-800 rounded-xl px-5 py-4 flex items-center gap-4">
              <span className="text-2xl">{q.type==='main'?'⚔️':q.type==='daily'?'☀️':q.type==='faction'?'🎖️':'📌'}</span>
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{q.title} <span className="text-xs text-gray-500">({q.type})</span></div>
                <div className="text-xs text-gray-400">{q.district} · {q.objectives.length} objective{q.objectives.length!==1?'s':''} · 🪙{q.reward_coins} ⭐{q.reward_xp}</div>
                <div className="text-xs text-gray-500 truncate mt-0.5">{q.description}</div>
              </div>
              <button onClick={()=>setEditing({...q,prerequisites:Array.isArray(q.prerequisites)?q.prerequisites.join(', '):q.prerequisites||''})}
                className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded-lg text-xs">Edit</button>
            </div>
          ))}
          {quests.length===0 && <div className="text-gray-500 text-center py-12">No quests yet — click "+ New Quest" to create your first quest.</div>}
        </div>
      </div>
    </main>
  )
}
