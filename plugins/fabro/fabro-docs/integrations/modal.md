> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Modal

> Run Kimi K3 through Modal's OpenAI-compatible inference endpoints

[Modal](https://modal.com/) serves Kimi K3 through an OpenAI-compatible Shared API and through dedicated Auto Endpoints. Fabro ships a disabled `modal` provider entry for Kimi K3. Enable it after Modal gives you an endpoint URL.

## Prerequisites

* A [Modal account](https://modal.com/signup)
* A [Kimi K3 Shared API or Auto Endpoint](https://modal.com/library/moonshot/kimi-k3)
* A Modal proxy-token pair

## Create or select an endpoint

Use the Kimi K3 Shared API from the Modal model library, or create a dedicated Auto Endpoint:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
modal endpoint create --model moonshotai/Kimi-K3
```

Find the endpoint URL in the Modal dashboard or with `modal endpoint list`. Modal serves its OpenAI-compatible API under `/v1`.

## Create a proxy token

Modal endpoints are authenticated with two headers. Create a proxy-token pair:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
modal workspace proxy-tokens create
```

The command prints a token ID that starts with `wk-` and a secret that starts with `ws-`. Modal shows the secret only once, so save both values immediately.

If your Modal workspace uses RBAC, allow the token in the endpoint's environment:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
modal workspace proxy-tokens allow wk-... main
```

## Enable the provider

Add the provider override to the settings file used by the Fabro server. Include `/v1` in the endpoint URL and omit a trailing slash.

```toml title="settings.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
_version = 1

[llm.providers.modal]
base_url = "https://your-endpoint.modal.run/v1"
enabled = true
```

The endpoint URL is not built into Fabro because Modal assigns it to your Shared API or Auto Endpoint.

## Configure credentials

Store both proxy-token values in the target Fabro server vault:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro secret set MODAL_TOKEN_ID wk-...
fabro secret set MODAL_TOKEN_SECRET ws-...

# For a non-default remote server:
fabro secret --server https://your-fabro.example set MODAL_TOKEN_ID wk-...
fabro secret --server https://your-fabro.example set MODAL_TOKEN_SECRET ws-...
```

<Note>
  `fabro provider login --provider modal` is not supported in this release because that command accepts one credential value. Use the two `fabro secret set` commands above.
</Note>

Modal does not use a bearer API key for these endpoints. Fabro sends the vault values as `Modal-Key` and `Modal-Secret` headers and does not send an `Authorization` header.

## Included model

| Fabro model slug | Modal API ID         | Context   | Input / cached input / output    | Estimated speed |
| ---------------- | -------------------- | --------- | -------------------------------- | --------------- |
| `kimi-k3`        | `moonshotai/Kimi-K3` | 1M tokens | $3.00 / $0.30 / \$15.00 per MTok | 460 tok/s       |

The catalog marks Kimi K3 as supporting tools, vision, reasoning, and prompt caching. Modal's model ID is case-sensitive.

## Use Kimi K3

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro model list --provider modal
fabro model test --provider modal --model kimi-k3
fabro run workflow.fabro --provider modal --model kimi-k3
```

When targeting a non-default remote server, pass the same `--server` value:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro model list --server https://your-fabro.example --provider modal
fabro model test --server https://your-fabro.example --provider modal --model kimi-k3
```

In workflow stylesheets:

```dot title="workflow.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Example {
    graph [
        model_stylesheet="
            * { model: modal/kimi-k3; }
        "
    ]

    start [shape=Mdiamond, label="Start"]
    work  [label="Work", prompt="Use Kimi K3 through Modal."]
    exit  [shape=Msquare, label="Exit"]

    start -> work -> exit
}
```

## Direct SDK environment credentials

The built-in Modal provider authenticates with two headers, `Modal-Key` and `Modal-Secret`, read from the secrets `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET`. Direct SDK use reads the same two names from the process environment.

For direct SDK use, enable Modal and set its endpoint URL in the `[llm]` overlay, then build the client with `fabro_llm::build_client` over a `VaultCredentialSource` whose vault holds both secrets. The catalog you pass to the client must be built from the same settings file with `fabro_llm::build_catalog`.

```toml title="settings.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[llm.providers.modal]
base_url = "https://your-endpoint.modal.run/v1"
enabled = true
```

## Costs

Fabro estimates Shared API costs from Modal's published Kimi K3 prices. Completion and reasoning tokens use the output rate. Modal responses do not include an authoritative charge, so Fabro reports the cost source as `catalog`.

Dedicated Auto Endpoints use Modal compute billing instead of the Shared API token prices. The Fabro estimate does not represent that compute bill.

## Troubleshooting

**Modal requests fail with 404** — Add the Modal endpoint URL as `base_url` under `[llm.providers.modal]`. Include `/v1`.

**Modal is not configured** — Set both `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET` in the target server vault. One value is not sufficient.

**401 or 403** — Confirm that the token pair belongs to the correct Modal workspace and environment. If the workspace uses RBAC, allow the token in that environment.

**404** — Confirm that the base URL is the endpoint URL followed by `/v1`, with no trailing slash.

**Unknown model** — The built-in API ID is exactly `moonshotai/Kimi-K3`. Run `fabro model test --provider modal --model kimi-k3` to test the configured offering.

## Further reading

<Columns cols={2}>
  <Card title="Modal Kimi K3" icon="microchip" href="https://modal.com/library/moonshot/kimi-k3">
    Shared API prices, model specifications, and Auto Endpoint setup.
  </Card>

  <Card title="Modal endpoint authentication" icon="key" href="https://modal.com/docs/guide/endpoints#proxy-tokens">
    Proxy-token headers and endpoint calling conventions.
  </Card>
</Columns>
