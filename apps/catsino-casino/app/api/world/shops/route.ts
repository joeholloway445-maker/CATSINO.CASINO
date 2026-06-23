import { NextRequest, NextResponse } from 'next/server'
import { getAdminClient } from '@/lib/supabase/admin'

export async function GET() {
  const { data, error } = await getAdminClient().from('world_shops').select('*').order('district')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ shops: data })
}

export async function POST(req: NextRequest) {
  const body = await req.json()
  const { data, error } = await getAdminClient().from('world_shops').insert({
    shop_id: body.shop_id, shop_name: body.shop_name,
    district: body.district, items: body.items || [],
  }).select().single()
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ shop: data })
}

export async function PUT(req: NextRequest) {
  const body = await req.json()
  const { error } = await getAdminClient().from('world_shops').update({
    shop_name: body.shop_name, district: body.district, items: body.items || [],
    updated_at: new Date().toISOString(),
  }).eq('shop_id', body.shop_id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}

export async function DELETE(req: NextRequest) {
  const id = new URL(req.url).searchParams.get('id')
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
  const { error } = await getAdminClient().from('world_shops').delete().eq('shop_id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}
