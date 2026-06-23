'use client'
import { useEffect, useState } from 'react'

const ACTIONS = ['nothing','quest_accept:','shop_open','open_game:blackjack','open_game:poker','open_game:race','open_game:combat','give_coins:']

type Option = { label: string; next_node: string; action: string }
type Node = { id: string; text: string; options: Option[] }
type Dialogue = { dialogue_id: string; npc_id: string; start_node: string; nodes: Node[] }

const BLANK_OPT = (): Option => ({ label: 'OK', next_node: 'END', action: 'nothing' })
const BLANK_NODE = (): Node => ({ id: 'node_' + Date.now(), text: '', options: [BLANK_OPT()] })
const BLANK: Dialogue = { dialogue_id: '', npc_id: '', start_node: 'greeting', nodes: [{ id:'greeting', text:'', options:[BLANK_OPT()] }] }

export default function DialoguePage() {
  const [dialogues, setDialogues] = useState<Dialogue[]>([])
  const [editing, setEditing] = useState<Dialogue | null>(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  useEffect(() => { fetch('/api/world/dialogue').then(r=>r.json()).then(d=>setDialogues(d.dialogues||[])) }, [])

  const save = async () => {
    if (!editing) return
    setSaving(true); setMsg('')
    const r = await fetch('/api/world/dialogue', { method: editing.dialogue_id?'PUT':'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(editing) })
    const d = await r.json()
    if (d.error) { setMsg('Error: '+d.error) } else {
      setMsg('Saved!')
      setDialogues(prev => editing.dialogue_id ? prev.map(x=>x.dialogue_id===editing.dialogue_id?editing:x) : [...prev, editing])
      setEditing(null)
    }
    setSaving(false)
  }

  const updateNode = (i: number, field: keyof Node, val: unknown) =>
    setEditing(e => e ? { ...e, nodes: e.nodes.map((n, j) => j === i ? { ...n, [field]: val } : n) } : e)

  const updateOpt = (ni: number, oi: number, field: keyof Option, val: string) =>
    setEditing(e => e ? { ...e, nodes: e.nodes.map((n,j)=>j===ni?{...n,options:n.options.map((o,k)=>k===oi?{...o,[field]:val}:o)}:n) } : e)

  const addNode = () => setEditing(e => e ? { ...e, nodes: [...e.nodes, BLANK_NODE()] } : e)
  const removeNode = (i: number) => setEditing(e => e ? { ...e, nodes: e.nodes.filter((_,j)=>j!==i) } : e)
  const addOpt = (ni: number) => setEditing(e => e ? { ...e, nodes: e.nodes.map((n,j)=>j===ni?{...n,options:[...n.options,BLANK_OPT()]}:n) } : e)
  const removeOpt = (ni: number, oi: number) => setEditing(e => e ? { ...e, nodes: e.nodes.map((n,j)=>j===ni?{...n,options:n.options.filter((_,k)=>k!==oi)}:n) } : e)

  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">💬 Dialogue Editor</h1>
            <p className="text-gray-400 text-sm mt-1">Write branching NPC conversations. Each node is a screen of dialogue; options lead to the next node.</p>
          </div>
          <button onClick={()=>setEditing({...BLANK, nodes:[{id:'greeting',text:'',options:[BLANK_OPT()]}]})}
            className="bg-cyan-600 hover:bg-cyan-500 px-4 py-2 rounded-xl font-semibold text-sm">
            + New Dialogue
          </button>
        </div>

        {editing && (
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 mb-8">
            <div className="grid grid-cols-2 gap-4 mb-6">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Dialogue ID (must match NPC's dialogue_id)</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.dialogue_id} onChange={e=>setEditing({...editing,dialogue_id:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Start Node (first node shown, usually "greeting")</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.start_node} onChange={e=>setEditing({...editing,start_node:e.target.value})} />
              </div>
            </div>

            <div className="space-y-4">
              {editing.nodes.map((node, ni) => (
                <div key={node.id} className="bg-gray-800 rounded-xl p-4 border border-gray-700">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="bg-cyan-700 text-white text-xs font-bold px-2 py-1 rounded">Node: {node.id}</div>
                    <input placeholder="node_id" className="bg-gray-700 border border-gray-600 rounded px-2 py-1 text-xs text-white w-36"
                      value={node.id} onChange={e=>updateNode(ni,'id',e.target.value)} />
                    {editing.nodes.length > 1 && (
                      <button onClick={()=>removeNode(ni)} className="ml-auto text-red-400 text-xs hover:text-red-300">Remove Node</button>
                    )}
                  </div>
                  <textarea placeholder="What does the NPC say in this part of the conversation?"
                    className="w-full bg-gray-700 border border-gray-600 rounded-lg px-3 py-2 text-sm text-white h-20 resize-none mb-3"
                    value={node.text} onChange={e=>updateNode(ni,'text',e.target.value)} />
                  <div className="text-xs text-gray-400 mb-2 font-semibold">Player choices (buttons shown to the player):</div>
                  {node.options.map((opt, oi) => (
                    <div key={oi} className="flex gap-2 mb-2 items-start">
                      <input placeholder="Button label (e.g. &quot;Let's fight!&quot;)"
                        className="flex-1 bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                        value={opt.label} onChange={e=>updateOpt(ni,oi,'label',e.target.value)} />
                      <input placeholder='Next node id (or "END")'
                        className="w-32 bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                        value={opt.next_node} onChange={e=>updateOpt(ni,oi,'next_node',e.target.value)} />
                      <select className="w-48 bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                        value={opt.action} onChange={e=>updateOpt(ni,oi,'action',e.target.value)}>
                        <option value="nothing">No action</option>
                        {ACTIONS.filter(a=>a!=='nothing').map(a=><option key={a} value={a}>{a}</option>)}
                      </select>
                      {node.options.length>1 && <button onClick={()=>removeOpt(ni,oi)} className="text-red-400 text-xs mt-2">✕</button>}
                    </div>
                  ))}
                  <button onClick={()=>addOpt(ni)} className="text-blue-400 text-xs hover:text-blue-300 mt-1">+ Add Choice</button>
                </div>
              ))}
            </div>

            <button onClick={addNode} className="mt-4 text-cyan-400 text-sm hover:text-cyan-300">+ Add Dialogue Node</button>

            <div className="flex gap-3 mt-4">
              <button onClick={save} disabled={saving}
                className="bg-cyan-600 hover:bg-cyan-500 disabled:opacity-50 px-5 py-2 rounded-xl font-semibold text-sm">
                {saving?'Saving...':'Save Dialogue'}
              </button>
              <button onClick={()=>setEditing(null)} className="bg-gray-700 hover:bg-gray-600 px-5 py-2 rounded-xl font-semibold text-sm">Cancel</button>
              {msg && <span className={`text-sm my-auto ${msg.startsWith('Error')?'text-red-400':'text-green-400'}`}>{msg}</span>}
            </div>
          </div>
        )}

        <div className="grid gap-3">
          {dialogues.map(d=>(
            <div key={d.dialogue_id} className="bg-gray-900 border border-gray-800 rounded-xl px-5 py-4 flex items-center gap-4">
              <span className="text-2xl">💬</span>
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{d.dialogue_id}</div>
                <div className="text-xs text-gray-400">{d.nodes.length} node{d.nodes.length!==1?'s':''} · starts at "{d.start_node}"</div>
              </div>
              <button onClick={()=>setEditing({...d})} className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded-lg text-xs">Edit</button>
            </div>
          ))}
          {dialogues.length===0 && <div className="text-gray-500 text-center py-12">No dialogues yet — click "+ New Dialogue" to write your first NPC conversation.</div>}
        </div>
      </div>
    </main>
  )
}
