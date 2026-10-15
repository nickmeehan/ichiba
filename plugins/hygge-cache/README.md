# hygge-cache

Keeps an idle session's prompt cache warm with a silent fork ping and
refuses idle compaction, so coming back after a break reads the cache
instead of rewriting it, with every detail still there.

Two things happen to a session you leave open. After the
[cache lifetime](https://code.claude.com/docs/en/prompt-caching#cache-lifetime)
passes, your next message re-processes the whole conversation at the
cache-write rate. And a session over 200k tokens is
[compacted while idle](https://code.claude.com/docs/en/settings-reference#idlecompaction)
about 54 minutes after its last request, so you come back to a summary.

- **The tick.** Every five minutes the plugin asks one question: has it
  been the interval since the last request, is the cache still alive,
  and is the session worth it. If so, it sends one tool-less fork over
  the session's own transcript. The API reads the cached prefix and
  restarts its clock. A read is a small fraction of a rewrite.
- **The refusal.** An automatic compaction that arrives with no turn
  running is refused while the context window has headroom. Above the
  headroom, and during a turn, compaction runs as normal.
- **The receipt.** The first request of your next turn shows whether the
  ping held: served from cache about what the ping read, it held; served
  nearly nothing, it did not, and pinging stops for the session. A model
  switch or a return past the hour says nothing about the ping and is
  not counted.

It is a hooks module: no files, processes, network, environment,
persistence or commands of its own, and it never starts a turn.

## Installation

```
/plugin marketplace add nickmeehan/ichiba
/plugin install hygge-cache@ichiba
```

Requires a Claude Code build with function hooks (developed against
2.1.300).

## Settings to pair with

- `idleCompaction: false`, so sessions without the plugin, and
  organizations whose managed settings skip a user-installed plugin's
  compaction hook, are covered too.
- `promptCacheTtl: "1h"` on an API key, a cloud provider, or once a
  subscription is drawing on usage credits. Those get the five-minute
  lifetime by default, and set `ttlMinutes` to match whatever you chose.
- `subagentPromptCacheTtl: "1h"` only if the receipt reports that a ping
  did not hold. Forks sit in the five-minute request bucket; this makes
  their request match the main conversation's. It doubles the cache-write
  rate for subagents too, so leave it unset until a receipt says otherwise.

## What you see

| Status line | Meaning |
|---|---|
| `warm · ping 1 at 50m · read 183k · next in 50m` | A ping found the prefix and read it. The gap is how idle the session was when it fired |
| `warm · ping at 50m held · 183k served from cache` | Your next turn's first request confirmed the ping restarted the hour |
| `hygge: ping at 50m did not hold · stopped; ...` | The receipt showed the cache gone within the hour after a ping; no more pings this session. Try a shorter interval, or the subagent lifetime setting above |
| `hygge: ping missed · 183k re-sent · waiting for your next turn` | The prefix was not in the cache when the ping ran; the fork paid for it. No retry until the next turn rebuilds the cache |
| `hygge: cache lapsed · warming again after your next turn` | A tick came too late, as after a laptop sleep |
| `hygge: idle too long · gave up; ...` | Past the give-up window; a cold read is now cheaper than more pings |

Between those the plugin is silent. To switch it off, flip `enabled` in
`/config`.

## Options

| Option | Default | What it does |
|---|---|---|
| `enabled` | `true` | Off stops every ping and lets idle compaction run |
| `intervalMinutes` | `50` | Idle minutes since the last request before a ping. Checked every five minutes |
| `ttlMinutes` | `60` | The cache lifetime in effect. At 5 nothing pings |
| `minContextK` | `50` | Sessions under this many thousand tokens are left alone |
| `giveUpAfterHours` | `12` | Stop pinging a session nobody has typed in for this long |
| `compactAbovePercent` | `85` | Let idle compaction through above this much of the context window |

## What a ping costs

A ping is one cache read of the context; a cold return is one cache
write at the one-hour rate, double the input price. For 200k tokens at
list price: Opus 5.5 $0.04 against $1.60, Fable 5.1 $0.05 against
$4.00, Sonnet 5.5 $0.04 against $0.80. Size cancels out of that ratio,
so what decides whether pinging pays is how many pings go out before you
come back, which is what the give-up window bounds. Twelve hours at
fifty-minute pings stays under one rewrite on every current model.

## Limits

- A session you closed cannot be kept warm.
- The lifetime is a knob, not detected. A five-minute account that leaves
  it at 60 loses one cache read per session before the receipt stops it.
- A model switch or a `/compact` while idle makes the next ping miss and
  stand down until your next turn.
- Under organization-managed settings a user-installed plugin's
  compaction hook does not run; `idleCompaction: false` does the refusing.

## Development

```bash
claude plugin validate plugins/hygge-cache
claude plugin test plugins/hygge-cache
```

## License

MIT
