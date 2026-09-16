# SerialMate-Skill

SerialMate-Skill v1.0.0 是一个供 Codex 使用 SerialMate CLI 的 Skill。它把串口发现、实例选择、状态确认、发送和增量读取组织成安全、可复用的工作流。

本仓库独立于 `chenz-ruo/SerialMate`，不包含 SerialMate 程序、串口驱动或 Python 串口实现。

## 适用范围

当用户需要查找 COM 设备、打开/关闭串口、发送 HEX/文本、读取响应，或测试 MCU、UART、RS-485 硬件时使用本 Skill。协议解析和设备业务逻辑仍由用户明确指定，Skill 不自动猜测。

## 依赖与兼容性

- 依赖 SerialMate 的公开接口：`AUTOMATION.md`、`AUTOMATION_PROTOCOL.md`、`SerialMate.exe --help`、`SerialMate.exe capabilities`。
- 当前冻结的 `AutomationProtocolVersion=1` 支持：`--list-instances`、`--list-ports`、`ping`、`capabilities`、`status`、`open`、`close`、`send-hex`、`send-text`、`read`。
- 一个 SerialMate 进程最多拥有一个 COM；多个 COM 使用多个实例。
- 发现顺序：`SERIALMATE_EXE` → PATH 中的 `SerialMate.exe` → 用户提供的路径。

## 仓库结构

```text
SKILL.md
README.md
references/
  CLI.md
  ERROR_HANDLING.md
  MULTI_INSTANCE.md
  EXAMPLES.md
scripts/
  check_serialmate.ps1
```

## 健康检查

在 PowerShell 中运行：

```powershell
.\scripts\check_serialmate.ps1
```

如果环境变量和 PATH 都未找到，也可以提供备用路径：

```powershell
.\scripts\check_serialmate.ps1 -ExecutablePath 'C:\\Tools\\SerialMate.exe'
```

脚本只检查可执行文件、运行 `--help` 和 `--list-instances`，不会打开或关闭任何 COM 口。

## 来源维护

接口说明以 SerialMate 仓库的公开协议文档和 CLI 输出为准。本仓库不复制或推测 SerialMate 内部实现；协议变化时，先确认上游 `AUTOMATION_PROTOCOL.md`，再更新 Skill。

