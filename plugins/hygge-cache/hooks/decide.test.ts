import { test, expect } from 'claude-code/testing'
import { decide, found, receipt, MINUTE, type Snapshot, type Limits } from './decide'

const H = 60 * MINUTE
const limits: Limits = { ttlMs: H, intervalMs: 50 * MINUTE, giveUpMs: 12 * H, minTokens: 50_000 }
const warm: Snapshot = { now: 50 * MINUTE + 1, lastRequestAt: 1, lastHumanAt: 0, contextTokens: 200_000, isIdle: true }

test('pings a big idle session once the interval has passed since its last request', () => {
  expect(decide(warm, limits)).toBe('ping')
})

test('waits quietly before the interval, during a turn, and with nothing cached yet', () => {
  expect(decide({ ...warm, now: 20 * MINUTE + 1 }, limits)).toBe('wait')
  expect(decide({ ...warm, isIdle: false }, limits)).toBe('wait')
  expect(decide({ ...warm, lastRequestAt: 0 }, limits)).toBe('wait')
})

test('a late tick, as after a laptop sleep, still pings while the hour runs and stands down once it lapsed', () => {
  expect(decide({ ...warm, now: 58 * MINUTE + 1 }, limits)).toBe('ping')
  expect(decide({ ...warm, now: 59 * MINUTE + 1 }, limits)).toEqual({ skip: expect.stringContaining('lapsed') })
})

test('gives up on a session nobody has typed in for the give-up window', () => {
  expect(decide({ ...warm, now: 12 * H + 1, lastRequestAt: 12 * H - 50 * MINUTE }, limits)).toEqual({ skip: expect.stringContaining('gave up') })
})

test('leaves small sessions alone, and says why it is off', () => {
  expect(decide({ ...warm, contextTokens: 20_000 }, limits)).toBe('wait')
  expect(decide({ ...warm, off: 'off' }, limits)).toEqual({ skip: 'off' })
})

test('refuses an interval that does not fit under the lifetime, so a five-minute cache never pings', () => {
  expect(decide(warm, { ...limits, ttlMs: 5 * MINUTE })).toEqual({ skip: expect.stringContaining('lifetime') })
})

test('a ping found the prefix when it read about what the session holds', () => {
  expect(found(195_000, 200_000)).toBe(true)
  expect(found(0, 200_000)).toBe(false)
  expect(found(1_000, 0)).toBe(false)
})

test('the receipt judges by what was served from cache, so a big new message is not a failure', () => {
  const p = { read: 200_000, model: 'claude-opus-5-5' }
  expect(receipt({ read: 200_000, model: p.model, sinceLastPingMs: 30 * MINUTE }, p, H)).toBe('held')
  expect(receipt({ read: 190_000, model: p.model, sinceLastPingMs: 30 * MINUTE }, p, H)).toBe('held')
  expect(receipt({ read: 0, model: p.model, sinceLastPingMs: 30 * MINUTE }, p, H)).toBe('failed')
})

test('the receipt is moot after a model switch, a return past the hour, or with no ping pending', () => {
  const p = { read: 200_000, model: 'claude-opus-5-5' }
  expect(receipt({ read: 0, model: 'claude-sonnet-5-5', sinceLastPingMs: 30 * MINUTE }, p, H)).toBe('moot')
  expect(receipt({ read: 0, model: p.model, sinceLastPingMs: 70 * MINUTE }, p, H)).toBe('moot')
  expect(receipt({ read: 0, model: p.model, sinceLastPingMs: 30 * MINUTE }, { read: 0, model: p.model }, H)).toBe('moot')
})
