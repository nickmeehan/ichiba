// The policy, with no `$` in it: what a tick decides from, and what it decides.

export const MINUTE = 60_000
export const MARGIN = MINUTE // what a request's own latency may eat off the lifetime

export type Snapshot = {
  now: number
  lastRequestAt: number // START of the last main request or ping; 0 until something is cached
  lastHumanAt: number // when the person last sent a prompt
  contextTokens: number // what the next request re-sends
  isIdle: boolean // between a turn's end and the next prompt
  off?: string // why pinging is off: switched off, or a receipt failed
}

export type Limits = { ttlMs: number; intervalMs: number; giveUpMs: number; minTokens: number }

// What a tick decides, one of three:
//
//   'ping'         Send the fork now. The session has sat idle for the interval, its cache is
//                  still alive, the person typed within the give-up window, and the context is
//                  big enough to be worth it.
//   'wait'         Nothing to do this tick and nothing to say: a turn is running, nothing is
//                  cached yet, the interval has not passed, or the context is under the floor.
//                  The tick asks again in five minutes.
//   { skip: why }  Not pinging, and the person should know why: the cache already lapsed, the
//                  give-up window passed, the plugin is off, or a receipt failed. Said once on
//                  the status line, then quiet until the reason changes.
export type Decision = 'ping' | 'wait' | { skip: string }

export function decide(s: Snapshot, l: Limits): Decision {
  if (s.off) return { skip: s.off }
  if (l.intervalMs >= l.ttlMs - MARGIN) return { skip: 'ping interval must be under the cache lifetime' }
  if (!s.isIdle || s.lastRequestAt === 0) return 'wait'
  const idle = s.now - s.lastRequestAt
  if (idle < l.intervalMs) return 'wait'
  if (idle >= l.ttlMs - MARGIN) return { skip: 'cache lapsed · warming again after your next turn' }
  if (s.now - s.lastHumanAt >= l.giveUpMs) return { skip: 'idle too long · gave up; a cold read is cheaper now' }
  if (s.contextTokens < l.minTokens) return 'wait'
  return 'ping'
}

// Did the ping itself find the conversation in the cache? A ping that found it read nearly
// all of what the session holds. One that did not read nearly none, and paid to process the
// whole conversation instead. Half is a clean line between the two.
export const found = (read: number, expected: number) => expected > 0 && read >= expected * 0.5

// The receipt: what the first real request after a ping proves about that ping.
//
// The ping read the conversation from the cache, so the cache was alive when the ping ran.
// The open question is whether that read restarted the cache's clock. The first request of
// the person's next turn answers it by how much it, too, gets from the cache:
//
//   'held'    It got about what the ping read (90% or more). The ping restarted the clock,
//             and pinging works on this account at this interval.
//   'failed'  It got nearly nothing. The cache was gone within the hour after the ping, so
//             the ping's read did not restart the clock. Every further ping would be wasted
//             the same way, so the caller stops pinging for the session.
//   'moot'    The result proves nothing about the ping, so no verdict: no ping was pending,
//             the model changed since the ping (each model has its own cache), or the person
//             came back more than a lifetime after the ping (the cache lapsed on its own).
export function receipt(
  r: { read: number; model: string; sinceLastPingMs: number },
  p: { read: number; model: string },
  ttlMs: number,
): 'held' | 'failed' | 'moot' {
  if (p.read === 0 || r.model !== p.model || r.sinceLastPingMs >= ttlMs - MARGIN) return 'moot'
  return r.read >= p.read * 0.9 ? 'held' : 'failed'
}
