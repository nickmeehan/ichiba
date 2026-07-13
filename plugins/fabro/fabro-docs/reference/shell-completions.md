> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Shell Completions

> Set up tab completion for the fabro CLI in your shell

The `fabro completion` command generates shell completion scripts for tab-completing commands, flags, and arguments.

## Bash

Add to your `~/.bashrc`:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
eval "$(fabro completion bash)"
```

Or generate a file and source it:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion bash > ~/.local/share/bash-completion/completions/fabro
```

## Zsh

Add to your `~/.zshrc` (before `compinit`):

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
eval "$(fabro completion zsh)"
```

Or generate a file:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion zsh > "${fpath[1]}/_fabro"
```

You may need to run `compinit` or start a new shell session for changes to take effect.

## Fish

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion fish | source
```

Or persist to the completions directory:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion fish > ~/.config/fish/completions/fabro.fish
```

## PowerShell

Add to your PowerShell profile:

```powershell theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion powershell | Out-String | Invoke-Expression
```

## Elvish

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
eval (fabro completion elvish | slurp)
```

## Supported shells

Run `fabro completion --help` to see all supported shells:

```bash theme={"languages":{"custom":["/languages/dot.json","/languages/fabro.json"]}}
fabro completion --help
```
