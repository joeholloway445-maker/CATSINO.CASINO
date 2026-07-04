'use client'
import { useEffect, useState } from 'react'

const DISTRICTS = ['paw_vegas','neon_alley','cat_coliseum','cat_forest','arcade_galaxy']
const ITEM_TYPES = ['consumable','frame','mod','equipment','companion_item']

type Item = { item_id: string; name: string; type: string; price: number; description: string; emoji: string }
type Shop = { shop_id: string; shop_name: string; district: string; items: Item[] }

const BLANK_ITEM = (): Item => ({ item_id: 'item_'+Date.now(), name: '', type: 'consumable', price: 500, description: '', emoji: '🎁' })
const BLANK: Shop = { shop_id:'', shop_name:'', district:'paw_vegas', items:[] }

export default function ShopsPage() {
  const [shops, setShops] = useState<Shop[]>([])
  const [editing, setEditing] = useState<Shop | null>(null)
  const [saving, setSaving] = useState(false)
  const [msg, setMsg] = useState('')

  useEffect(() => { fetch('/api/world/shops').then(r=>r.json()).then(d=>setShops(d.shops||[])) }, [])

  const save = async () => {
    if (!editing) return
    setSaving(true); setMsg('')
    const r = await fetch('/api/world/shops', { method: editing.shop_id?'PUT':'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(editing) })
    const d = await r.json()
    if (d.error) { setMsg('Error: '+d.error) } else {
      setMsg('Saved!')
      setShops(prev=>editing.shop_id ? prev.map(s=>s.shop_id===editing.shop_id?editing:s) : [...prev,editing])
      setEditing(null)
    }
    setSaving(false)
  }

  const addItem = () => setEditing(e=>e?{...e,items:[...e.items,BLANK_ITEM()]}:e)
  const removeItem = (i:number) => setEditing(e=>e?{...e,items:e.items.filter((_,j)=>j!==i)}:e)
  const updateItem = (i:number, f:keyof Item, v:unknown) =>
    setEditing(e=>e?{...e,items:e.items.map((it,j)=>j===i?{...it,[f]:v}:it)}:e)

  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-3xl font-bold">🛍️ Shop Editor</h1>
            <p className="text-gray-400 text-sm mt-1">Manage shop inventories — items, Cat Chip prices, and districts.</p>
          </div>
          <button onClick={()=>setEditing({...BLANK,items:[BLANK_ITEM()]})}
            className="bg-yellow-600 hover:bg-yellow-500 px-4 py-2 rounded-xl font-semibold text-sm">
            + New Shop
          </button>
        </div>

        {editing && (
          <div className="bg-gray-900 border border-gray-700 rounded-2xl p-6 mb-8">
            <div className="grid grid-cols-3 gap-4 mb-5">
              <div>
                <label className="block text-xs text-gray-400 mb-1">Shop ID</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.shop_id} onChange={e=>setEditing({...editing,shop_id:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">Shop Name</label>
                <input className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.shop_name} onChange={e=>setEditing({...editing,shop_name:e.target.value})} />
              </div>
              <div>
                <label className="block text-xs text-gray-400 mb-1">District</label>
                <select className="w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2 text-sm text-white"
                  value={editing.district} onChange={e=>setEditing({...editing,district:e.target.value})}>
                  {DISTRICTS.map(d=><option key={d}>{d}</option>)}
                </select>
              </div>
            </div>

            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-semibold text-sm">Items</h3>
              <button onClick={addItem} className="text-yellow-400 text-xs hover:text-yellow-300">+ Add Item</button>
            </div>
            {editing.items.map((item,i)=>(
              <div key={item.item_id} className="bg-gray-800 rounded-xl p-4 mb-2 grid grid-cols-6 gap-3 items-start">
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Emoji</label>
                  <input className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white text-center"
                    value={item.emoji} onChange={e=>updateItem(i,'emoji',e.target.value)} />
                </div>
                <div className="col-span-2">
                  <label className="block text-xs text-gray-400 mb-1">Item Name</label>
                  <input className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                    value={item.name} onChange={e=>updateItem(i,'name',e.target.value)} />
                </div>
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Type</label>
                  <select className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                    value={item.type} onChange={e=>updateItem(i,'type',e.target.value)}>
                    {ITEM_TYPES.map(t=><option key={t}>{t}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Price 🪙</label>
                  <input type="number" min={0} className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                    value={item.price} onChange={e=>updateItem(i,'price',parseInt(e.target.value)||0)} />
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs text-gray-400">Action</label>
                  <button onClick={()=>removeItem(i)} className="text-red-400 hover:text-red-300 text-xs mt-1">Remove</button>
                </div>
                <div className="col-span-5">
                  <label className="block text-xs text-gray-400 mb-1">Description (what does it do?)</label>
                  <input className="w-full bg-gray-700 border border-gray-600 rounded px-2 py-1.5 text-sm text-white"
                    value={item.description} onChange={e=>updateItem(i,'description',e.target.value)} />
                </div>
              </div>
            ))}
            <div className="flex gap-3 mt-4">
              <button onClick={save} disabled={saving}
                className="bg-yellow-600 hover:bg-yellow-500 disabled:opacity-50 px-5 py-2 rounded-xl font-semibold text-sm">
                {saving?'Saving...':'Save Shop'}
              </button>
              <button onClick={()=>setEditing(null)} className="bg-gray-700 hover:bg-gray-600 px-5 py-2 rounded-xl font-semibold text-sm">Cancel</button>
              {msg && <span className={`text-sm my-auto ${msg.startsWith('Error')?'text-red-400':'text-green-400'}`}>{msg}</span>}
            </div>
          </div>
        )}

        <div className="grid gap-3">
          {shops.map(s=>(
            <div key={s.shop_id} className="bg-gray-900 border border-gray-800 rounded-xl px-5 py-4 flex items-center gap-4">
              <span className="text-2xl">🛍️</span>
              <div className="flex-1 min-w-0">
                <div className="font-semibold">{s.shop_name}</div>
                <div className="text-xs text-gray-400">{s.district} · {s.items.length} item{s.items.length!==1?'s':''}</div>
                <div className="text-xs text-gray-500">{s.items.map(it=>`${it.emoji}${it.name}`).join(' · ')}</div>
              </div>
              <button onClick={()=>setEditing({...s})} className="bg-gray-700 hover:bg-gray-600 px-3 py-1.5 rounded-lg text-xs">Edit</button>
            </div>
          ))}
          {shops.length===0 && <div className="text-gray-500 text-center py-12">No shops yet — click "+ New Shop" to create your first shop.</div>}
        </div>
      </div>
    </main>
  )
}
