#!/usr/bin/env python3
"""
Hook Configuration Validator

Validates Claude Code hook configurations for:
- JSON syntax
- Valid event names
- Proper structure
- Matcher requirements
- Security concerns
"""

import json
import sys
import re
from pathlib import Path
from typing import Dict, List, Tuple

# Valid hook event names
VALID_EVENTS = {
    'PreToolUse', 'PermissionRequest', 'PostToolUse',
    'Notification', 'UserPromptSubmit', 'Stop',
    'SubagentStop', 'PreCompact', 'SessionStart', 'SessionEnd'
}

# Events that require matchers
MATCHER_REQUIRED = {
    'PreToolUse', 'PermissionRequest', 'PostToolUse',
    'Notification', 'PreCompact', 'SessionStart'
}

# Events that don't use matchers
NO_MATCHER = {'UserPromptSubmit', 'Stop', 'SubagentStop', 'SessionEnd'}

# Valid hook types
VALID_TYPES = {'command', 'prompt'}


class ValidationError:
    def __init__(self, level: str, message: str, path: str = ""):
        self.level = level  # 'error', 'warning', 'info'
        self.message = message
        self.path = path

    def __str__(self):
        prefix = "❌" if self.level == "error" else "⚠️ " if self.level == "warning" else "ℹ️ "
        path_str = f" ({self.path})" if self.path else ""
        return f"{prefix} {self.message}{path_str}"


def validate_json_syntax(file_path: str) -> Tuple[bool, Dict, List[ValidationError]]:
    """Validate JSON syntax and return parsed config."""
    errors = []

    try:
        with open(file_path, 'r') as f:
            config = json.load(f)
        errors.append(ValidationError('info', '✓ Valid JSON syntax'))
        return True, config, errors
    except json.JSONDecodeError as e:
        errors.append(ValidationError('error', f'Invalid JSON: {e}'))
        return False, {}, errors
    except FileNotFoundError:
        errors.append(ValidationError('error', f'File not found: {file_path}'))
        return False, {}, errors


def validate_event_names(config: Dict) -> List[ValidationError]:
    """Validate all event names are correct."""
    errors = []

    hooks = config.get('hooks', {})
    if not hooks:
        return [ValidationError('warning', 'No hooks defined in configuration')]

    invalid_events = set(hooks.keys()) - VALID_EVENTS
    if invalid_events:
        for event in invalid_events:
            errors.append(ValidationError(
                'error',
                f'Invalid event name: "{event}". Valid events: {", ".join(sorted(VALID_EVENTS))}',
                f'hooks.{event}'
            ))
    else:
        errors.append(ValidationError('info', f'✓ All event names are valid ({len(hooks)} events)'))

    return errors


def validate_hook_structure(config: Dict) -> List[ValidationError]:
    """Validate hook configuration structure."""
    errors = []

    hooks = config.get('hooks', {})

    for event_name, matchers in hooks.items():
        if event_name not in VALID_EVENTS:
            continue  # Already caught by validate_event_names

        if not isinstance(matchers, list):
            errors.append(ValidationError(
                'error',
                f'Event "{event_name}" must be an array of matcher objects',
                f'hooks.{event_name}'
            ))
            continue

        for idx, matcher_obj in enumerate(matchers):
            path = f'hooks.{event_name}[{idx}]'

            # Check for hooks array
            if 'hooks' not in matcher_obj:
                errors.append(ValidationError(
                    'error',
                    'Missing "hooks" array',
                    path
                ))
                continue

            # Validate matcher presence
            has_matcher = 'matcher' in matcher_obj
            if event_name in NO_MATCHER and has_matcher:
                errors.append(ValidationError(
                    'warning',
                    f'Event "{event_name}" does not use matchers (matcher will be ignored)',
                    path
                ))

            # Validate each hook
            for hook_idx, hook in enumerate(matcher_obj.get('hooks', [])):
                hook_path = f'{path}.hooks[{hook_idx}]'

                # Check type
                hook_type = hook.get('type')
                if not hook_type:
                    errors.append(ValidationError(
                        'error',
                        'Missing "type" field',
                        hook_path
                    ))
                elif hook_type not in VALID_TYPES:
                    errors.append(ValidationError(
                        'error',
                        f'Invalid type "{hook_type}". Must be "command" or "prompt"',
                        hook_path
                    ))

                # Check command/prompt
                if hook_type == 'command' and 'command' not in hook:
                    errors.append(ValidationError(
                        'error',
                        'type "command" requires "command" field',
                        hook_path
                    ))
                elif hook_type == 'prompt' and 'prompt' not in hook:
                    errors.append(ValidationError(
                        'error',
                        'type "prompt" requires "prompt" field',
                        hook_path
                    ))

                # Check timeout
                timeout = hook.get('timeout')
                if timeout:
                    if not isinstance(timeout, (int, float)):
                        errors.append(ValidationError(
                            'error',
                            f'timeout must be a number, got {type(timeout).__name__}',
                            hook_path
                        ))
                    elif timeout > 600:
                        errors.append(ValidationError(
                            'warning',
                            f'timeout is very high ({timeout}s). Consider reducing.',
                            hook_path
                        ))
                    elif timeout < 1:
                        errors.append(ValidationError(
                            'warning',
                            f'timeout is very low ({timeout}s). May cause issues.',
                            hook_path
                        ))

    if not errors:
        errors.append(ValidationError('info', '✓ Hook structure is valid'))

    return errors


def validate_file_paths(config: Dict) -> List[ValidationError]:
    """Validate file paths in commands."""
    errors = []

    hooks = config.get('hooks', {})

    for event_name, matchers in hooks.items():
        for idx, matcher_obj in enumerate(matchers):
            for hook_idx, hook in enumerate(matcher_obj.get('hooks', [])):
                if hook.get('type') != 'command':
                    continue

                command = hook.get('command', '')
                path = f'hooks.{event_name}[{idx}].hooks[{hook_idx}]'

                # Check for relative paths
                if command.startswith('./') or command.startswith('../'):
                    errors.append(ValidationError(
                        'warning',
                        'Relative path detected. Consider using absolute path or $CLAUDE_PROJECT_DIR',
                        path
                    ))

                # Check if uses environment variables (good)
                if '$CLAUDE_PROJECT_DIR' in command or '$CLAUDE_PLUGIN_ROOT' in command:
                    # Good practice
                    pass
                elif '/' in command and not command.startswith('/'):
                    # Looks like a path but not absolute or using vars
                    errors.append(ValidationError(
                        'warning',
                        'Path should be absolute or use $CLAUDE_PROJECT_DIR',
                        path
                    ))

    return errors


def validate_security(config: Dict) -> List[ValidationError]:
    """Check for potential security issues."""
    errors = []

    hooks = config.get('hooks', {})

    dangerous_patterns = [
        ('rm -rf /', 'Dangerous recursive delete'),
        ('sudo', 'Sudo usage - may require password or be dangerous'),
        ('curl.*|.*bash', 'Piping curl to bash is dangerous'),
        ('eval', 'eval can execute arbitrary code'),
    ]

    for event_name, matchers in hooks.items():
        for idx, matcher_obj in enumerate(matchers):
            for hook_idx, hook in enumerate(matcher_obj.get('hooks', [])):
                if hook.get('type') != 'command':
                    continue

                command = hook.get('command', '')
                path = f'hooks.{event_name}[{idx}].hooks[{hook_idx}]'

                for pattern, warning in dangerous_patterns:
                    if re.search(pattern, command, re.IGNORECASE):
                        errors.append(ValidationError(
                            'warning',
                            f'Potentially dangerous command: {warning}',
                            path
                        ))

    return errors


def validate_stop_hooks(config: Dict) -> List[ValidationError]:
    """Validate Stop/SubagentStop hooks check stop_hook_active."""
    errors = []

    stop_events = {'Stop', 'SubagentStop'}
    hooks = config.get('hooks', {})

    for event_name in stop_events:
        if event_name not in hooks:
            continue

        for idx, matcher_obj in enumerate(hooks[event_name]):
            for hook_idx, hook in enumerate(matcher_obj.get('hooks', [])):
                if hook.get('type') != 'command':
                    continue

                command = hook.get('command', '')
                path = f'hooks.{event_name}[{idx}].hooks[{hook_idx}]'

                # Check if command contains stop_hook_active check
                # (This is a heuristic - we can't validate script contents perfectly)
                if 'stop_hook_active' not in command:
                    errors.append(ValidationError(
                        'warning',
                        f'{event_name} hook should check stop_hook_active to prevent infinite loops',
                        path
                    ))

    return errors


def main():
    if len(sys.argv) < 2:
        print("Usage: validate-hook-config.py <settings.json>")
        sys.exit(1)

    file_path = sys.argv[1]

    print(f"Validating hook configuration: {file_path}\n")

    all_errors = []

    # 1. JSON syntax
    valid, config, errors = validate_json_syntax(file_path)
    all_errors.extend(errors)

    if not valid:
        print("\n".join(str(e) for e in all_errors))
        sys.exit(1)

    # 2. Event names
    all_errors.extend(validate_event_names(config))

    # 3. Hook structure
    all_errors.extend(validate_hook_structure(config))

    # 4. File paths
    all_errors.extend(validate_file_paths(config))

    # 5. Security
    all_errors.extend(validate_security(config))

    # 6. Stop hooks
    all_errors.extend(validate_stop_hooks(config))

    # Print results
    error_count = sum(1 for e in all_errors if e.level == 'error')
    warning_count = sum(1 for e in all_errors if e.level == 'warning')

    for error in all_errors:
        print(error)

    print()

    if error_count > 0:
        print(f"❌ Validation failed with {error_count} error(s) and {warning_count} warning(s)")
        sys.exit(1)
    elif warning_count > 0:
        print(f"⚠️  Validation passed with {warning_count} warning(s)")
        sys.exit(0)
    else:
        print("✅ Configuration is valid!")
        sys.exit(0)


if __name__ == '__main__':
    main()
