export {
  Room,
  RoomEvent,
  Track,
  VideoPresets,
  createLocalAudioTrack,
  createLocalVideoTrack,
} from 'livekit-client'
export type {
  RemoteParticipant,
  LocalParticipant,
  Participant,
  RoomConnectOptions,
} from 'livekit-client'

export const LIVEKIT_URL = process.env.NEXT_PUBLIC_LIVEKIT_URL ?? ''

export async function joinRoom(token: string, url = LIVEKIT_URL) {
  const { Room } = await import('livekit-client')
  const room = new Room()
  await room.connect(url, token)
  return room
}
