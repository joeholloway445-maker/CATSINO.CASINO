export const MATRIX_HOMESERVER = process.env.NEXT_PUBLIC_MATRIX_HOMESERVER_URL ?? 'https://matrix.org'

export async function createMatrixClient(accessToken: string, userId: string) {
  const { createClient } = await import('matrix-js-sdk')
  const client = createClient({
    baseUrl: MATRIX_HOMESERVER,
    accessToken,
    userId,
  })
  return client
}

export async function joinMatrixRoom(client: Awaited<ReturnType<typeof createMatrixClient>>, roomId: string) {
  await client.joinRoom(roomId)
  await client.startClient({ initialSyncLimit: 20 })
  return client
}
