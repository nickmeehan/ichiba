> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Venice Search

> Give Fabro agents web search capabilities via Venice's augment/search API

Fabro's [`web_search`](/agents/tools#web_search) tool lets agents search the web during workflow execution. Fabro uses [Venice Search](https://docs.venice.ai/api-reference/endpoint/augment/search) automatically when `VENICE_API_KEY` is available and a direct [Brave Search](/integrations/brave-search) key is not.

Venice Search reuses the same `VENICE_API_KEY` as the Venice LLM provider. Agents keep calling `web_search`; only the HTTP backend changes.

## Setup

1. Store a Venice API key on the Fabro server (skip this if the Venice LLM provider is already logged in):

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro provider login --provider venice
# or
fabro secret set VENICE_API_KEY venice-...
```

Fabro prefers direct Brave Search whenever `BRAVE_SEARCH_API_KEY` is also present. To select Venice, leave that key unset or remove it:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro secret rm BRAVE_SEARCH_API_KEY
```

2. Verify the key is working:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro doctor
```

The doctor output should show **Web Search** as `venice: configured and reachable`. If neither Venice nor Brave is configured, web search is reported as a warning. Workflows still run, but the `web_search` tool is omitted from the agent's tool set.

The Fabro server reads this key from the vault only. It does not read `VENICE_API_KEY` from process env or `server.env`.

## How it works

Agents call the `web_search` tool with a query string. Fabro `POST`s to Venice `https://api.venice.ai/api/v1/augment/search` with the Brave search engine and returns numbered results with title, URL, description, and date when Venice includes one:

```
1. Rust Lang
   https://rust-lang.org
   A systems language
   2026-01-02
```

Venice Search is billed by Venice at \$0.01 per request and is rate-limited to 20 requests per minute on the Venice side. Queries longer than 400 characters are rejected before the HTTP call.

If `VENICE_API_KEY` is absent but `BRAVE_SEARCH_API_KEY` exists, Fabro uses direct Brave Search. If neither key exists, the tool is not registered. After selecting Venice, a failed call returns an error; Fabro does not retry through direct Brave Search.

See the [`web_search` tool reference](/agents/tools#web_search) for parameters and details.

## Permissions

`web_search` is classified as a `shell` category tool, requiring the `full` [permission level](/agents/permissions) for auto-approval. At lower permission levels:

* **Interactive mode** — the user is prompted to approve each call
* **Non-interactive mode** (`--auto-approve`) — calls are denied

## Troubleshooting

**"VENICE\_API\_KEY is not configured"** — Add the key with `fabro secret set VENICE_API_KEY <key>` or `fabro provider login --provider venice`. Run `fabro doctor` to verify.

**"Venice Search API returned status 401"** — The API key is invalid or expired. Create a new key at [venice.ai](https://venice.ai).

**"Venice Search API returned status 402"** — The Venice account is out of credits. The error may include a remaining-balance hint.

**"Venice Search API returned status 429"** — Rate limit exceeded (20 requests per minute on Venice Search). Reduce the frequency of `web_search` calls.

## Further reading

<Columns cols={2}>
  <Card title="Tools" icon="wrench" href="/agents/tools#web_search">
    Full `web_search` tool reference — parameters, output format, and error handling.
  </Card>

  <Card title="Brave Search" icon="globe" href="/integrations/brave-search">
    Direct Brave Search backend, preferred whenever its key is configured.
  </Card>
</Columns>
