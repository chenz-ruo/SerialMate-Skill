# 标准示例

以下示例展示决策顺序；占位参数必须替换为命令帮助和实际输出确认过的值。

## 案例 1：查找设备

```text
发现 SerialMate.exe
SerialMate.exe --list-ports
SerialMate.exe --list-instances
```

根据 COM 号、设备名称、VID/PID 和实例 `pid`/`instanceId` 让用户确认目标。

## 案例 2：打开 COM7

```text
--list-ports                 # 确认 COM7 仍存在
--list-instances             # 找到目标实例
--pid <pid> status           # 确认 instanceId 和连接状态
--pid <pid> open <confirmed-port-and-options>
--pid <pid> status            # 报告最终状态
```

不要仅因为用户提到“COM7”就跳过发现和状态确认。

## 案例 3：发送 HEX 并等待返回

```text
--pid <pid> status            # 记录 lastSeq
--pid <pid> send-hex <hex>
--pid <pid> read --afterSeq <saved-lastSeq>
```

超时或 `truncated=true` 时如实报告，不把历史缓存误当作本次响应。

## 案例 4：发送 ASCII 命令

```text
--pid <pid> status
--pid <pid> send-text <authorized-command>
--pid <pid> read --afterSeq <saved-lastSeq>
```

发送前确认命令内容和设备上下文；危险命令必须得到用户授权。

## 案例 5：多个 SerialMate 实例

为每个 `{pid, instanceId, port, lastSeq}` 建立独立记录，所有 `status`、发送和读取调用都带对应 `--pid`。禁止跨实例共享游标或猜测目标。

## 案例 6：长时间轮询设备

固定使用同一实例的递增 `lastSeq`：每轮先读取 `read --afterSeq <lastSeq>`，处理新记录后更新该实例游标。若返回 `truncated=true`，标记数据缺口并告知用户；不要声称可恢复已淘汰记录。

## 案例 7：设备拔出后的恢复

停止发送，重新执行 `--list-ports` 和 `--list-instances`。确认设备重新出现且实例身份匹配后，再 `status`、`open`，并从新的 `lastSeq` 开始读取。若实例已退出，按 `instance_not_found` 处理，不自动关闭或替换其它实例。

