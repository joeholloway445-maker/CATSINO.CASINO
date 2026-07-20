// Vendored ambient type declarations for the Nakama TypeScript server runtime.
// Heroic Labs distributes this as a raw .d.ts in their nakama-project-template
// (not as an npm package) — vendoring it here keeps the build self-contained.
// Covers exactly the API surface used by this project's RPC modules.

declare namespace nkruntime {
  interface Context {
    env: { [key: string]: string };
    executionMode: string;
    node: string;
    userId: string;
    username: string;
    vars: { [key: string]: string };
    userSessionExp: number;
    sessionId: string;
    clientIp?: string;
    clientPort?: string;
    matchId?: string;
    matchNode?: string;
    matchLabel?: string;
    matchTickRate?: number;
  }

  interface Logger {
    debug(format: string, ...args: unknown[]): string;
    error(format: string, ...args: unknown[]): string;
    info(format: string, ...args: unknown[]): string;
    warn(format: string, ...args: unknown[]): string;
  }

  interface Presence {
    userId: string;
    sessionId: string;
    username: string;
    node: string;
  }

  interface StorageObject {
    collection: string;
    key: string;
    userId: string;
    value: { [key: string]: unknown };
    version: string;
    permissionRead: number;
    permissionWrite: number;
    createTime: number;
    updateTime: number;
  }

  interface StorageWriteRequest {
    collection: string;
    key: string;
    userId: string;
    value: { [key: string]: unknown };
    version?: string;
    permissionRead?: number;
    permissionWrite?: number;
  }

  interface StorageReadRequest {
    collection: string;
    key: string;
    userId: string;
  }

  interface StorageDeleteRequest {
    collection: string;
    key: string;
    userId: string;
  }

  interface LeaderboardRecord {
    leaderboardId: string;
    ownerId: string;
    username?: string;
    score: number;
    subscore: number;
    numScore: number;
    metadata?: string;
    createTime: number;
    updateTime: number;
    expiryTime: number;
    rank: number;
  }

  interface LeaderboardRecordList {
    records: LeaderboardRecord[];
    ownerRecords: LeaderboardRecord[];
    nextCursor: string;
    prevCursor: string;
  }

  interface ChannelMessage {
    channelId: string;
    messageId: string;
    code: number;
    senderId: string;
    username: string;
    content: string;
    createTime: number;
    updateTime: number;
    persistent: boolean;
  }

  interface FriendList {
    friends: { user: { id: string; username: string }; state: number }[];
    cursor?: string;
  }

  interface Group {
    id: string;
    creatorId: string;
    name: string;
    description: string;
    avatarUrl: string;
    langTag: string;
    open: boolean;
    edgeCount: number;
    maxCount: number;
    createTime: number;
    updateTime: number;
    metadata: string;
  }

  interface GroupUserList {
    groupUsers: { user: { id: string; username: string }; state: number }[];
    cursor?: string;
  }

  interface WalletUpdate {
    userId: string;
    changeset: { [key: string]: number };
    metadata?: { [key: string]: unknown };
  }

  interface WalletLedgerResult {
    id: string;
    userId: string;
    createTime: number;
    updateTime: number;
    changeset: { [key: string]: number };
    metadata: { [key: string]: unknown };
  }

  interface MatchDispatcher {
    broadcastMessage(
      opCode: number,
      data?: string | Uint8Array | null,
      presences?: Presence[] | null,
      sender?: Presence | null,
      reliable?: boolean
    ): void;
    matchKick(presences: Presence[]): void;
    matchLabelUpdate(label: string): void;
  }

  interface MatchMessage {
    sender: Presence;
    persistence: boolean;
    status?: string;
    opCode: number;
    data: string;
    reliable: boolean;
    receiveTimeMs: number;
  }

  type MatchState = { [key: string]: unknown };

  interface MatchInitFunction {
    (ctx: Context, logger: Logger, nk: Nakama, params: { [key: string]: string }): {
      state: MatchState;
      tickRate: number;
      label: string;
    };
  }

  interface MatchJoinAttemptFunction {
    (
      ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
      tick: number, state: MatchState, presence: Presence, metadata: { [key: string]: string }
    ): { state: MatchState; accept: boolean; rejectMessage?: string } | null;
  }

  interface MatchJoinFunction {
    (ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
      tick: number, state: MatchState, presences: Presence[]): { state: MatchState } | null;
  }

  interface MatchLeaveFunction {
    (ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
      tick: number, state: MatchState, presences: Presence[]): { state: MatchState } | null;
  }

  interface MatchLoopFunction {
    (ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
      tick: number, state: MatchState, messages: MatchMessage[]): { state: MatchState } | null;
  }

  interface MatchTerminateFunction {
    (ctx: Context, logger: Logger, nk: Nakama, dispatcher: MatchDispatcher,
      tick: number, state: MatchState, graceSeconds: number): { state: MatchState } | null;
  }

  interface MatchHandler {
    matchInit: MatchInitFunction;
    matchJoinAttempt: MatchJoinAttemptFunction;
    matchJoin: MatchJoinFunction;
    matchLeave: MatchLeaveFunction;
    matchLoop: MatchLoopFunction;
    matchTerminate: MatchTerminateFunction;
    /** Required by Nakama 3.21+ — omitting it fatals with "matchSignal not found". */
    matchSignal: MatchSignalFunction;
  }

  type MatchSignalFunction = (
    ctx: Context,
    logger: Logger,
    nk: Nakama,
    dispatcher: MatchDispatcher,
    tick: number,
    state: MatchState,
    data: string
  ) => { state: MatchState };

  type RpcFunction = (
    ctx: Context,
    logger: Logger,
    nk: Nakama,
    payload: string
  ) => string;

  interface Initializer {
    registerRpc(id: string, func: RpcFunction): void;
    registerMatch(name: string, handler: MatchHandler): void;
    registerBeforeRt?(id: string, func: unknown): void;
    registerAfterRt?(id: string, func: unknown): void;
  }

  interface Nakama {
    mathRandom(): number;
    uuidv4(): string;
    binaryToString(data: Uint8Array): string;
    stringToBinary(data: string): Uint8Array;

    accountGetId(userId: string): unknown;
    usersGetUsername(usernames: string[]): unknown[];

    walletUpdate(userId: string, changeset: { [key: string]: number }, metadata?: { [key: string]: unknown }, updateLedger?: boolean): { updated: { [key: string]: number } };
    walletsUpdate(updates: WalletUpdate[], updateLedger?: boolean): { updated: { [key: string]: number } }[];
    walletLedgerList(userId: string, limit?: number, cursor?: string): { items: WalletLedgerResult[]; cursor: string };

    storageWrite(writes: StorageWriteRequest[]): { collection: string; key: string; version: string; userId: string }[];
    storageRead(reads: StorageReadRequest[]): StorageObject[];
    storageDelete(deletes: StorageDeleteRequest[]): void;
    storageList(userId: string | null, collection: string, limit?: number, cursor?: string): { objects: StorageObject[]; cursor: string };

    leaderboardCreate(id: string, authoritative: boolean, sortOrder?: string, operator?: string, resetSchedule?: string | null, metadata?: { [key: string]: unknown }): void;
    leaderboardRecordWrite(id: string, ownerId: string, username?: string, score?: number, subscore?: number, metadata?: { [key: string]: unknown }): LeaderboardRecord;
    leaderboardRecordsList(id: string, ownerIds?: string[], limit?: number, cursor?: string, expiry?: number): LeaderboardRecordList;
    leaderboardRecordDelete(id: string, ownerId: string): void;

    matchCreate(module: string, params?: { [key: string]: unknown }): string;
    matchList(limit?: number, authoritative?: boolean, label?: string, minSize?: number, maxSize?: number, query?: string): unknown[];

    friendsAdd(userId: string, username: string, ids: string[], usernames: string[]): void;
    friendsDelete(userId: string, username: string, ids: string[], usernames: string[]): void;
    friendsList(userId: string, limit?: number, state?: number, cursor?: string): FriendList;

    groupCreate(userId: string, name: string, creatorId?: string, langTag?: string, description?: string, avatarUrl?: string, open?: boolean, metadata?: { [key: string]: unknown }, maxCount?: number): Group;
    groupsGetId(groupIds: string[]): Group[];
    groupUserJoin(groupId: string, userId: string, username: string): void;
    groupUserLeave(groupId: string, userId: string, username: string): void;
    groupUsersAdd(callerId: string, groupId: string, userIds: string[]): void;
    groupUsersList(groupId: string, limit?: number, state?: number, cursor?: string): GroupUserList;

    channelMessageSend(channelId: string, content: { [key: string]: unknown }, senderId?: string, senderUsername?: string, persist?: boolean): unknown;
    channelMessagesList(channelId: string, limit?: number, forward?: boolean, cursor?: string): { messages: ChannelMessage[]; nextCursor: string; prevCursor: string };
  }
}
