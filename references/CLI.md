# CLI 工作流参考

本页只记录 Automation Protocol v1 冻结基线中的命令类别和调用顺序。参数、输出字段和退出码以当前安装版本的 `SerialMate.exe --help`、`capabilities` 以及上游 `AUTOMATION_PROTOCOL.md` 为准。

## 发现与能力确认

```text
SerialMate.exe --help
SerialMate.exe --list-ports
SerialMate.exe --list-instances
SerialMate.exe --pid <pid> capabilities
```

先确认可执行文件和 `AutomationProtocolVersion=1`，再根据 `--list-ports` 选择设备、根据 `--list-instances` 选择实例。输出中的 `pid` 与 `instanceId` 共同构成实例身份。

## 实例优先发现

路径发现之前先检查正在运行的 `SerialMate.exe`。从运行进程取得实际可执行文件路径，用该路径执行 `--list-instances`；只要返回可用实例，就直接通过 Automation Protocol 控制，不要求用户提供 EXE 路径或配置 PATH。

没有实例时，按 `SERIALMATE_EXE`、PATH、`C:\Program Files\SerialMate\SerialMate.exe`、`%LOCALAPPDATA%\SerialMate\SerialMate.exe`、当前目录 `tools\SerialMate.exe`、当前目录 `bin\SerialMate.exe` 的顺序搜索。找到 EXE 后可启动 SerialMate，最多等待 10 秒并再次执行 `--list-instances`。超时后停止等待并如实报告，不循环启动多个 GUI。

## JSON 与退出码

标准输出是一个 UTF-8 JSON 值加换行；诊断信息属于 stderr。成功和失败 envelope 分别为：

```json
{"ok":true,"result":{}}
{"ok":false,"error":{"code":"serial_not_open","message":"..."}}
```

`--list-ports`、`--list-instances` 和 `--help` 也会在顶层返回各自的 `ports`、`instances` 或 `usage` 字段。按 `error.code` 分支，不按 message 文本分支。退出码 `0` 也包括没有新记录的 waited read；`2` 是参数错误，`3` 是实例不存在或身份不匹配，`4` 是 IPC/协议错误，`5` 是目标操作失败。

## 实例操作

目标实例明确时，使用该实例的 `--pid`，并在操作前运行：

```text
SerialMate.exe --pid <pid> status
```

确认状态后再执行 `open`、`close`、`send-hex`、`send-text` 或 `read`。除 `status`、`ping`、`capabilities` 外，这些操作都必须同时传入同一实例的 `--instanceId`。不要根据历史记录猜测端口，也不要在多个候选实例之间自动选择。

## 发送后增量读取

发送前先确认同一实例状态，并从该实例的 `read` 结果取得或复用 `lastSeq`：

```text
SerialMate.exe --pid <pid> status
SerialMate.exe --pid <pid> read --instanceId <instanceId> --afterSeq 0 --limit 1
save result.lastSeq
SerialMate.exe --pid <pid> send-hex --instanceId <instanceId> --data "<confirmed-hex>"
SerialMate.exe --pid <pid> read --instanceId <instanceId> --afterSeq <saved-lastSeq>
```

`--afterSeq` 是严格的增量游标：只请求 sequence 大于给定值的记录。若返回 `truncated=true`，必须声明有界缓存淘汰了部分历史，不能声称结果完整；若 `more=true`，继续使用 `nextAfter` 分页。

## 数据表示

HEX 是原始数据依据；TEXT 仅用于辅助显示。编码不确定时优先报告 HEX，并把任何文本解码说明为推断而非原始事实。

## 发送与安全边界

`send-hex` 和 `send-text` 返回 `acceptedBytes`，表示进入 SerialMate 有界发送队列的字节数，不代表已经完成物理发送。`send-text` 必须明确 `encoding`（`utf8`、`gbk` 或 `ascii`）和 `suffix`（`none`、`cr`、`lf` 或 `crlf`）。

Automation 是同机、同用户范围的本地 CLI；公开边界不是 TCP、HTTP 或远程控制。不要降低权限边界，也不要通过其他串口库绕过 SerialMate。

