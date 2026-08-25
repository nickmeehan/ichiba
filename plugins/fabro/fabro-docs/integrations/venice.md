> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Venice

> Run Kimi, Grok, GLM, DeepSeek, and Qwen models through Venice

[Venice](https://venice.ai/) provides an OpenAI-compatible API for hosted text models. Fabro enables the `venice` provider in its built-in catalog and maps stable Fabro model slugs to Venice's API model IDs.

## Prerequisites

* A Venice account
* An inference API key from [venice.ai/settings/api](https://venice.ai/settings/api)
* A running Fabro server

## Configure credentials

Store the API key in the target Fabro server vault:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro provider login --provider venice

# For a non-default remote server:
fabro provider login --server https://your-fabro.example --provider venice

# Or set the vault token directly:
fabro secret set VENICE_API_KEY
fabro secret --server https://your-fabro.example set VENICE_API_KEY
```

Standalone SDK usage outside a Fabro server can use an env-backed credential source explicitly:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
export VENICE_API_KEY=<api-key>
```

Fabro sends bearer-authenticated Chat Completions requests to `https://api.venice.ai/api/v1`.

## Included models

| Fabro model slug    | Venice API ID            |   Context | Max output | Role and aliases                                                                          |
| ------------------- | ------------------------ | --------: | ---------: | ----------------------------------------------------------------------------------------- |
| `kimi-k3`           | `kimi-k3`                | 1,000,000 |    131,072 | Alias `kimi`                                                                              |
| `kimi-k3-fast`      | `kimi-k3-fast-api`       | 1,000,000 |    131,072 | Alias `kimi-fast`                                                                         |
| `grok-4.6`          | `grok-4-6`               |   500,000 |     32,000 | Aliases `grok`, `grok46`, `grok-46`                                                       |
| `glm-5.3`           | `z-ai-glm-5-3`           | 1,000,000 |    131,072 | Aliases `glm`, `glm5`, `glm53`, `glm5.3`, `glm-5-3`                                       |
| `deepseek-v4-flash` | `deepseek-v4-flash-0731` | 1,000,000 |     32,768 | Provider default; aliases `deepseek`, `deepseek-v4`, `deepseek-flash`                     |
| `deepseek-v4-pro`   | `deepseek-v4-pro-0813`   | 1,000,000 |     32,768 | Alias `deepseek-pro`                                                                      |
| `qwen3.8-max`       | `qwen-3-8-max`           | 1,000,000 |    131,072 | Aliases `qwen`, `qwen-max`, `qwen3.8`, `qwen-3.8`, `qwen38`, `qwen-3.8-max`, `qwen38-max` |
| `qwen3.8-27b`       | `qwen-3-8-27b`           |   262,144 |    131,072 | Aliases `qwen-27b`, `qwen-3.8-27b`, `qwen38-27b`                                          |

Venice API IDs are also valid provider-scoped selectors. Fabro persists the stable Fabro slug and the selected provider when it creates a run.

## Select Venice explicitly

Some Venice models use the same stable slugs as direct providers. An unqualified selector chooses the highest-priority ready provider. For example, `deepseek` can select the direct DeepSeek provider when both API keys are configured.

Pin Venice when the run must use Venice:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro model list --provider venice
fabro model test --provider venice --model deepseek-v4-flash --deep
fabro run workflow.fabro --provider venice --model deepseek-v4-flash
```

In a workflow stylesheet:

```dot title="workflow.fabro" theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
digraph Example {
    graph [
        model_stylesheet="
            *         { provider: venice; model: deepseek-v4-flash; }
            .complex  { provider: venice; model: qwen; }
            .fast     { provider: venice; model: kimi-fast; }
        "
    ]

    start [shape=Mdiamond, label="Start"]
    work  [label="Implement", class="complex"]
    check [label="Check", class="fast"]
    exit  [shape=Msquare, label="Exit"]

    start -> work -> check -> exit
}
```

The generic Qwen aliases `qwen` and `qwen3.8` select Qwen 3.8 Max. Use a size-specific alias such as `qwen-27b` to select Qwen 3.8 27B.

## Capabilities and reasoning

All included models support tool calling and reasoning. Kimi K3, Kimi K3 Fast, Grok 4.6, Qwen 3.8 Max, and Qwen 3.8 27B also accept image input.

Fabro exposes native reasoning-effort controls only when Venice supports them:

| Model               | Reasoning effort values          |
| ------------------- | -------------------------------- |
| `grok-4.6`          | `low`, `medium`, `high`, `xhigh` |
| `glm-5.3`           | `low`, `high`, `max`             |
| `deepseek-v4-flash` | `low`, `high`, `max`             |
| `qwen3.8-27b`       | `low`, `medium`, `xhigh`         |

The other models reason by default but do not expose a Venice reasoning-effort control. Fabro omits sampling parameters for Kimi and DeepSeek because those routes do not use them with their configured reasoning behavior.

## Pricing and prompt caching

The built-in catalog uses Venice's published prices per million tokens:

| Model               | Uncached input | Cache hit |  Output |
| ------------------- | -------------: | --------: | ------: |
| `kimi-k3`           |         \$3.75 |   \$0.375 | \$18.75 |
| `kimi-k3-fast`      |         \$4.50 |    \$0.45 | \$22.50 |
| `grok-4.6`          |         \$2.27 |    \$0.57 |  \$6.80 |
| `glm-5.3`           |         \$1.75 |   \$0.325 |  \$5.50 |
| `deepseek-v4-flash` |        \$0.175 |   \$0.035 |  \$0.35 |
| `deepseek-v4-pro`   |         \$1.65 |   \$0.165 |  \$4.95 |
| `qwen3.8-max`       |         \$2.50 |  \$0.3125 |  \$7.50 |
| `qwen3.8-27b`       |         \$0.45 |       n/a |  \$3.20 |

Fabro reports cached input separately when Venice returns cache usage for the selected model. Prices and model availability can change upstream; use `fabro model list --provider venice` to inspect the catalog shipped with your Fabro version and the [Venice model catalog](https://docs.venice.ai/models/overview) for the current upstream service.

## Troubleshooting

**"No credential was found for provider 'venice'"** — Store `VENICE_API_KEY` in the server vault with `fabro provider login --provider venice`. Pass `--server` when configuring a remote Fabro server.

**A shared model used another provider** — Pin Venice with `--provider venice` or `provider: venice` in the workflow stylesheet. Unqualified selectors use provider priority.

**A Venice API model ID is rejected without a provider** — Use the stable Fabro slug for portable selection, or qualify the API ID with the provider, such as `venice:qwen-3-8-max`.
