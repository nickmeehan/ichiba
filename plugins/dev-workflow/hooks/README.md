# Hooks

Hooks are shell commands that run at specific points in Claude Code's lifecycle.

## Available Hook Events

- `PreToolUse` - Before a tool runs
- `PostToolUse` - After a tool completes successfully
- `Notification` - When Claude sends an alert
- `Stop` - When the AI agent finishes its response
- `UserPromptSubmit` - When user submits a prompt
- `SessionStart` - When a session starts

## Example Configuration

The `hooks.json` file contains an example hook. Modify it for your needs.

## Hook Communication

Hooks receive JSON via stdin and communicate through:
- Exit code 0 = Success
- Exit code non-zero = Failure
- stdout = Output shown to user (or added to context for certain events)
- stderr = Error messages

## Remove This

Remove the example hooks.json and create your actual hooks configuration.
