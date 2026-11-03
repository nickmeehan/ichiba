> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# LiteLLM

> Route Fabro models through a LiteLLM proxy

[LiteLLM](https://docs.litellm.ai/) can run as an OpenAI-compatible proxy in front of many model providers. Fabro includes a disabled `litellm` provider entry so you can opt in from `settings.toml` without changing Fabro code.

## Prerequisites

* A running LiteLLM proxy reachable from the Fabro process
* At least one LiteLLM model name you want Fabro to route to
* A LiteLLM key or placeholder key available to Fabro

Fabro's built-in LiteLLM provider points at `http://localhost:4000/v1`. Change `base_url` if your proxy is hosted elsewhere.

## Enable the provider

Add the provider override and one or more model entries to `~/.fabro/settings.toml`:

```toml title="settings.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
_version = 1

[llm.providers.litellm]
base_url = "http://localhost:4000/v1"
default_model = "litellm-gpt-5"
enabled = true

[llm.providers.litellm.models."litellm-gpt-5"]
display_name = "LiteLLM GPT-5"
api_model = "gpt-5"
limits = { context_tokens = 128000, max_output_tokens = 8192 }
capabilities = { text = true, tools = true }
```

`api_model` is the model name Fabro sends to LiteLLM. It should match a model name configured in your LiteLLM proxy.

## Configure credentials

For server-backed runs, store `LITELLM_API_KEY` in the Fabro server vault.

For a server-owned secret:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro secret set LITELLM_API_KEY sk-proxy-key
```

For direct `fabro exec` (no server target), export the key in the invoking shell. SDK callers can explicitly choose an environment-backed credential source:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
export LITELLM_API_KEY=sk-proxy-key
```

`fabro exec --server ...` uses the target Fabro server's vault, even when the CLI has a key in its own environment. See [Credential sources](https://docs.fabro.sh/core-concepts/models.md#credential-sources).

If your local LiteLLM proxy does not enforce authentication, use a placeholder value such as `anything`; the OpenAI-compatible client still needs a credential value.

## Use LiteLLM models

Once the provider is enabled and at least one model is declared, use the Fabro model ID like any other catalog model:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro model list --provider litellm
fabro model test --model litellm-gpt-5
fabro run workflow.fabro --model litellm-gpt-5
```

In workflow stylesheets:

```dot title="workflow.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Example {
    graph [
        model_stylesheet="
            * { model: litellm-gpt-5; }
        "
    ]

    start [shape=Mdiamond, label="Start"]
    work  [label="Work", prompt="Use the configured LiteLLM model."]
    exit  [shape=Msquare, label="Exit"]

    start -> work -> exit
}
```

## Declaring more models

Declare each LiteLLM-routed model explicitly so Fabro knows its provider, context window, tool support, and routing defaults:

```toml title="settings.toml" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
[llm.providers.litellm.models."litellm-fast"]
display_name = "LiteLLM Fast"
aliases = ["fast"]
api_model = "fast-model"
limits = { context_tokens = 64000, max_output_tokens = 4096 }
capabilities = { text = true, tools = true }
```

The provider's `default_model` names its default. You may also mark one small utility model with `small_default = true`; Fabro uses it for metadata tasks such as generated run titles and falls back to the provider default when it is omitted.

## Troubleshooting

**"No API key configured"** — For runs, store `LITELLM_API_KEY` in the target server vault with `fabro secret set LITELLM_API_KEY ...`. Exporting it in the server's shell has no effect on runs: workers start from a cleared environment and provider keys are not inherited. For direct `fabro exec` (no server target), export `LITELLM_API_KEY` in the invoking shell or store it in the local secret store. SDK callers must choose the appropriate credential source.

**Connection refused** — Confirm the LiteLLM proxy is running and that `base_url` is reachable from the Fabro process. For Docker deployments, `localhost` means the Fabro container unless you point it at a host or service name.

**Unknown model from LiteLLM** — Check that the model's `api_model` matches the model name configured in LiteLLM, then run `fabro model test --model <fabro-model-id>`.

## Further reading

> [card] [Models](https://docs.fabro.sh/core-concepts/models.md)
>
> How Fabro routes model IDs, providers, and fallbacks.

> [card] [Settings Configuration](https://docs.fabro.sh/reference/user-configuration.md)
>
> Full reference for provider settings and provider-scoped model offerings.


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.