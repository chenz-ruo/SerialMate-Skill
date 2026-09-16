# 错误处理参考

根据结构化的 `error.code` 分支，不依赖易变的 message 文本。下面的动作是 v1 工作流建议；具体字段和退出码以 `AUTOMATION_PROTOCOL.md` 为准。

| `error.code` | 推荐动作 |
|---|---|
| `instance_not_found` | 重新执行 `--list-instances`；确认 PID/实例仍在运行后再重试。 |
| `instance_mismatch` | 停止当前操作，重新核对 `pid`、`instanceId` 和目标端口；不要猜测。 |
| `multiple_instances` | 展示候选实例并请求用户明确目标；不要自动选取或关闭其它实例。 |
| `already_connected` | 用 `status` 确认当前连接归属；若是目标实例，继续使用它，否则请求用户处理冲突。 |
| `not_connected` | 先确认端口仍存在，再按发现 → 实例 → `status` → `open` 流程操作。 |
| `invalid_hex` | 不发送；指出输入不是有效 HEX，请用户修正字节串。 |
| `send_queue_full` | 不立即循环重发；读取/等待队列恢复，并在必要时请用户降低发送速率。 |
| `timeout` | 报告等待超时；检查连接、设备供电和命令时序，再由用户决定是否重试。 |
| `shutting_down` | 停止后续调用，等待实例退出或重新发现可用实例。 |
| `read_truncated` | 明确告知有界缓存已淘汰部分历史；缩短轮询间隔或从新的游标重新采集。 |

错误恢复不得绕过 SerialMate，也不得自动发送未经授权的危险命令。

