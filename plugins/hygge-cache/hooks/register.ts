import type { EngineInterface, Register } from 'claude-code'
import { decide, found, receipt, MINUTE } from './decide'

type Options = {
  enabled?: boolean
  intervalMinutes?: number
  ttlMinutes?: number
  minContextK?: number
  giveUpAfterHours?: number
  compactAbovePercent?: number
}

const PING = 'Cache keep-alive from the hygge-cache plugin. Do nothing. Reply with the single word: ok'
const TICK = 5 * MINUTE
const NO_PING = { at: 0, read: 0, model: '', gapMin: 0 }

let opts: Options = {}
let lastRequestAt = 0 // START of the last main request or ping; 0 until something is cached
let lastHumanAt = 0 // when the person last sent a prompt
let isIdle = false // between a turn's end and the next prompt: when a ping may go, and idle compaction may fire
let model = '' // the model that answered the last main request
let ping = NO_PING // the last ping, until its receipt is in
let stopped: string | null = null // a receipt failed: no more pings this session
let lastWhy = '' // the last skip said on the status line, so a tick says each once
let pings = 0

export const register: Register = (on, options) => {
  opts = options as Options

  // The tick is the whole schedule: every five minutes, ask whether to ping.
  on('session.start', ($, e, next) => {
    $.clock.every(TICK, () => void tick($))
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    if (!e.isMeta) lastHumanAt = await $.clock.now()
    isIdle = false
    return next(e)
  })

  // Each request of the main loop. The cache lifetime runs from the request's START, so the stamp
  // goes before the send. The first request after a ping is the receipt.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId) return yield* next(e)
    const startedAt = await $.clock.now()
    lastRequestAt = startedAt
    isIdle = false
    const r = yield* next(e)
    if (r.usage) {
      model = r.usage.model
      if (ping.read) {
        // The receipt, judged in decide.ts. 'held': say so and carry on pinging. 'failed': stop
        // pinging for the session, with the fix named. 'moot': nothing to conclude. In every
        // case the ping is no longer pending.
        const read = r.usage.cache_read_input_tokens
        const verdict = receipt({ read, model, sinceLastPingMs: startedAt - ping.at }, ping, ttlMs())
        if (verdict === 'held') $.ui.status(`warm · ping at ${ping.gapMin}m held · ${k(read)} served from cache`)
        if (verdict === 'failed') {
          stopped = `ping at ${ping.gapMin}m did not hold · stopped; try a shorter interval, or subagentPromptCacheTtl 1h`
          lastWhy = stopped
          $.ui.status(`hygge: ${stopped}`)
        }
        ping = NO_PING
      }
    }
    return r
  })

  on('turn.complete', ($, e, next) => {
    if (!e.agentId) isIdle = true
    return next(e)
  })

  // Idle compaction is an automatic compaction with no turn running: the engine trading the
  // context for a summary before the cache lapses. While the window has headroom it is refused,
  // since that loss is what this mod exists to prevent. Above the headroom it goes through, as
  // does any compaction during a turn, which is the context-full kind.
  on('session.compact', { trigger: 'auto' }, async ($, e, next) => {
    if (isIdle && !e.agentId && opts.enabled !== false) {
      const { context } = await $.session.usage()
      if ((context.percent ?? 0) < (opts.compactAbovePercent ?? 85)) {
        return { skip: 'hygge-cache: keeping the full context; idle compaction refused' }
      }
    }
    const r = await next(e)
    if (!e.agentId && r.messages) {
      lastRequestAt = 0 // the prefix is new; nothing to keep warm until the next turn writes it
      ping = NO_PING
    }
    return r
  })

  on('session.end', ($, e, next) => {
    lastRequestAt = 0
    isIdle = false
    ping = NO_PING
    return next(e)
  })
}

async function tick($: EngineInterface) {
  const now = await $.clock.now()
  const contextTokens = (await $.session.usage()).context.tokens ?? 0
  const d = decide(
    { now, lastRequestAt, lastHumanAt, contextTokens, isIdle, off: stopped ?? (opts.enabled === false ? 'off' : undefined) },
    {
      ttlMs: ttlMs(),
      intervalMs: (opts.intervalMinutes ?? 50) * MINUTE,
      giveUpMs: (opts.giveUpAfterHours ?? 12) * 60 * MINUTE,
      minTokens: (opts.minContextK ?? 50) * 1000,
    },
  )
  if (d === 'wait') return // nothing to do, nothing to say
  if (d !== 'ping') {
    // A skip: say why once, then stay quiet until the reason changes.
    if (d.skip !== lastWhy) $.ui.status(`hygge: ${d.skip}`)
    lastWhy = d.skip
    return
  }
  lastWhy = ''

  const gapMin = Math.round((now - lastRequestAt) / MINUTE)
  lastRequestAt = now // the lifetime runs from this request's start
  // Four ways the ping can end: nothing to fork (a new session before its first answer, or right
  // after /clear: nothing is cached), an API error, a miss (the cache was already gone), or a read.
  const reply = await $.model.fork({ prompt: PING })
  if (!reply.isAnswered && reply.reason === 'nothing-to-fork') return void (lastRequestAt = 0)
  if (!reply.isAnswered && reply.reason !== 'empty-reply') {
    lastRequestAt = 0 // not again until the next turn: a retry every tick could be a 429 loop
    return $.ui.status(`hygge: ping failed (${reply.reason}) · waiting for your next turn`)
  }
  // The fork re-sends the main thread's last request. A read means the prefix was there and the
  // API restarted its clock. Anything else means the fork paid for the prefix, which is the
  // rewrite we were avoiding, so no retry until the next turn rebuilds it.
  const u = reply.usage
  if (!found(u.cache_read_input_tokens, contextTokens)) {
    lastRequestAt = 0
    return $.ui.status(`hygge: ping missed · ${k(u.input_tokens + u.cache_creation_input_tokens)} re-sent · waiting for your next turn`)
  }
  // A read. The cache was alive and the API restarted its clock, if a fork's read does that
  // here, which the receipt on the next turn will say. Until then the ping is pending.
  pings += 1
  ping = { at: now, read: u.cache_read_input_tokens, model, gapMin }
  $.ui.status(`warm · ping ${pings} at ${gapMin}m · read ${k(ping.read)} · next in ${opts.intervalMinutes ?? 50}m`)
}

const ttlMs = () => (opts.ttlMinutes ?? 60) * MINUTE
const k = (n: number) => `${Math.round(n / 1000)}k`
