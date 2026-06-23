import { Client, DefaultSocket } from '@heroiclabs/nakama-js'
import type { Session } from '@heroiclabs/nakama-js'

const HOST = process.env.NEXT_PUBLIC_NAKAMA_HOST ?? '127.0.0.1'
const PORT = process.env.NEXT_PUBLIC_NAKAMA_PORT ?? '7350'
const SERVER_KEY = process.env.NEXT_PUBLIC_NAKAMA_SERVER_KEY ?? 'defaultkey'
const USE_SSL = process.env.NEXT_PUBLIC_NAKAMA_SSL === 'true'

let _client: Client | null = null

export function getNakamaClient(): Client {
  if (!_client) {
    _client = new Client(SERVER_KEY, HOST, PORT, USE_SSL)
  }
  return _client
}

export async function nakamaAuth(deviceId: string): Promise<Session> {
  const client = getNakamaClient()
  return client.authenticateDevice(deviceId, true)
}

export async function nakamaConnect(session: Session) {
  const client = getNakamaClient()
  const socket = client.createSocket(USE_SSL)
  await socket.connect(session, true)
  return socket
}

export type { Session, DefaultSocket }
