# CLI 工作流参考

本页只记录 v1 冻结基线中的命令类别和调用顺序。参数、输出字段和退出码以当前安装版本的 `SerialMate.exe --help`、`capabilities` 以及上游 `AUTOMATION_PROTOCOL.md` 为准。

## 发现与能力确认

```text
SerialMate.exe --help
SerialMate.exe capabilities
SerialMate.exe --list-ports
SerialMate.exe --list-instances
```

先确认可执行文件和 `AutomationProtocolVersion=1`，再根据 `--list-ports` 选择设备、根据 `--list-instances` 选择实例。输出中的 `pid` 与 `instanceId` 共同构成实例身份。

## 实例操作

目标实例明确时，使用该实例的 `--pid`，并在操作前运行：

```text
SerialMate.exe --pid <pid> status
```

确认状态后再执行 `open`、`close`、`send-hex`、`send-text` 或 `read`。不要根据历史记录猜测端口，也不要在多个候选实例之间自动选择。

## 发送后增量读取

发送前从同一实例的 `status` 记录 `lastSeq`：

```text
status
save lastSeq
send-hex <confirmed-hex>
read --afterSeq <saved-lastSeq>
```

`--afterSeq` 是严格的增量游标：只请求 sequence 大于给定值的记录。若返回 `truncated=true`，必须声明有界缓存淘汰了部分历史，不能声称结果完整。

## 数据表示

HEX 是原始数据依据；TEXT 仅用于辅助显示。编码不确定时优先报告 HEX，并把任何文本解码说明为推断而非原始事实。

