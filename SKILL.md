---
name: serialmate-skill
description: Use SerialMate CLI for safe serial-port discovery, instance selection, open/close, send, and read workflows. Apply when a user asks to inspect COM devices, communicate with an MCU/RS-485 board, or test hardware over a serial connection; do not use it to replace SerialMate, implement a driver, or parse application protocols.
---

# SerialMate Skill v1.0.1

SerialMate-Skill is guidance for calling the user's installed SerialMate CLI. It is not the SerialMate application and must not become a second serial implementation.

## When to use

Prefer this skill for:

- discovering serial devices or COM ports;
- opening or closing a COM port;
- sending hexadecimal bytes or text;
- waiting for and reading device responses;
- testing hardware boards, MCU UARTs, or RS-485 devices.

Do not use Python serial libraries, pyserial, a custom driver, or an invented protocol to bypass SerialMate.

## Required workflow

For every serial operation, follow this order:

1. Discover a running instance first, then locate the executable if needed.
2. Identify the target SerialMate instance.
3. Run `status` and confirm the state.
4. Perform the requested operation.
5. Read and report the result.

## Discovery workflow

Prefer a running SerialMate GUI over path discovery. Enumerate running `SerialMate.exe` processes, obtain their executable paths, and use a running path to execute `--list-instances`. If the response contains an instance, use Automation directly; do not ask the user for the executable path or require PATH configuration.

If no running instance is available, locate `SerialMate.exe` in this order:

1. `SERIALMATE_EXE`.
2. `PATH`.
3. `C:\Program Files\SerialMate\SerialMate.exe`.
4. `%LOCALAPPDATA%\SerialMate\SerialMate.exe`.
5. `tools\SerialMate.exe`, then `bin\SerialMate.exe`, under the current working directory.

Also accept an explicit path already supplied by the user. When an executable is found but no instance is running, start SerialMate, wait up to 10 seconds for Automation to become available, and run `--list-instances` again. Starting the GUI does not authorize opening a port or sending data.

Only after instance detection and all executable locations fail, say: `未找到SerialMate。请安装SerialMate或提供SerialMate.exe路径。` Do not require the user to add SerialMate to PATH, and do not download or run an unknown executable.

Use `--list-ports` to confirm the COM number and device name; do not assume undocumented VID/PID fields. Use `--list-instances` to identify running instances. Never guess a COM port or reuse a historical port without checking it. If the target instance is known, address it with `--pid` and verify its `instanceId` with `status` or `ping`.

`open`, `close`, `send-hex`, `send-text` and `read` must include the matching `--instanceId` as well as `--pid`. A missing ID is `instance_id_required`; a stale or mismatched ID is `instance_mismatch`, and neither should cause a side effect.

The frozen baseline is `AutomationProtocolVersion=1`. Supported operations are `--list-instances`, `--list-ports`, `ping`, `capabilities`, `status`, `open`, `close`, `send-hex`, `send-text`, and `read`. One SerialMate process owns at most one COM port; use distinct instances for multiple COM ports.

## Instance and read cursor rules

Track each target independently as:

```text
{ pid, instanceId, port, lastSeq }
```

Never use a global “current serial port”, and never mix sequence values between instances. Before sending, run `status`, then establish or reuse that instance's cursor from a read result's `lastSeq`; after `send-hex` or `send-text`, read with `--afterSeq <saved-lastSeq>` so only newer records are considered. `read --afterSeq N` means sequence values greater than `N`.

If a read result reports `truncated=true`, explicitly tell the user that older history was evicted from the bounded buffer and the response is incomplete. Follow `more`/`nextAfter` for pagination. A waited read that returns `timedOut=true` with `ok=true` is a successful empty wait, not an error. Treat returned HEX as the authoritative raw data; TEXT is a convenience display when encoding is known.

## Safety and errors

Do not automatically close other instances. When multiple instances could match and the user has not identified one, stop and ask which `pid`/`instanceId` to use. Do not send dangerous commands without user authorization.

Branch on `error.code`, not on message wording. Recommended actions for the baseline error codes are in [references/ERROR_HANDLING.md](references/ERROR_HANDLING.md). Read [references/CLI.md](references/CLI.md) for command-shape guidance, [references/MULTI_INSTANCE.md](references/MULTI_INSTANCE.md) for concurrent devices, and [references/EXAMPLES.md](references/EXAMPLES.md) for end-to-end workflows.

Keep interface details aligned with the upstream SerialMate `AUTOMATION.md`, `AUTOMATION_PROTOCOL.md`, `SerialMate.exe --help`, and `SerialMate.exe capabilities`. Do not assume capabilities that are not confirmed by those public interfaces.

