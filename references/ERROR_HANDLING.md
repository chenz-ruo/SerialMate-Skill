# 错误处理参考

根据结构化的 `error.code` 分支，不依赖易变的 message 文本。下面的动作是 Automation Protocol v1 工作流建议；具体字段和退出码以 `AUTOMATION_PROTOCOL.md` 为准。

| `error.code` | 推荐动作 |
|---|---|
| `usage_error` | 修正命令行用法；先以 `--help` 确认当前参数。 |
| `instance_not_found` | 重新执行 `--list-instances`；确认 PID/实例仍在运行后再重试。 |
| `instance_id_required` | 重新获取目标 `instanceId`，并为 `open`、`close`、发送或读取命令显式传入它。 |
| `instance_mismatch` | 停止当前操作，重新核对 `pid`、`instanceId` 和目标端口；不要猜测。 |
| `pipe_unavailable` | 不重试未知实例；刷新实例列表，确认目标进程和权限后再试。 |
| `invalid_request` | 停止调用并检查请求结构；不要依赖 message 猜测缺失字段。 |
| `invalid_argument` | 修正参数；HEX、编码、后缀和串口配置必须符合 `--help`/协议约束。 |
| `unsupported_command` | 读取 `capabilities`，不要假设当前版本支持该命令。 |
| `serial_not_open` | 先确认端口仍存在，再按发现 → 实例 → `status` → `open` 流程操作。 |
| `serial_open_failed` | 报告打开失败；检查设备占用、参数和权限，不要抢占或绕过 SerialMate。 |
| `already_connected` | 用 `status` 确认当前连接归属；SerialMate 不会自动切换到另一个端口。 |
| `send_queue_full` | 不立即循环重发；等待队列恢复，并在必要时请用户降低发送速率。 |
| `automation_read_busy` | 等待当前 waited read 完成或取消后再发起下一次等待读取。 |
| `shutting_down` | 停止后续调用，等待实例退出或重新发现可用实例。 |

以下是结果状态，不是 `error.code`：`timedOut=true` 表示 `ok=true` 的空等待结果；`truncated=true` 表示有界缓存已淘汰部分历史，必须告知用户数据不完整；`more=true` 时使用 `nextAfter` 继续分页。多个候选实例也不是错误码，必须请求用户明确目标。

错误恢复不得绕过 SerialMate，也不得自动发送未经授权的危险命令。

