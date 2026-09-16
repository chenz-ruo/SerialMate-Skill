# 标准示例

以下示例展示决策顺序；占位参数必须替换为命令帮助和实际输出确认过的值。

## 案例 1：查找设备

```text
发现 SerialMate.exe
SerialMate.exe --list-ports
SerialMate.exe --list-instances
```

根据 COM 号、设备名称和实例 `pid`/`instanceId` 让用户确认目标。

## 案例 2：打开 COM7

```text
--list-ports                 # 确认 COM7 仍存在
--list-instances             # 找到目标实例
--pid <pid> status           # 确认 instanceId 和连接状态
--pid <pid> open --instanceId <instanceId> --port COM7 --baud 115200 --dataBits 8 --stopBits 1 --parity none --rtsCts false
--pid <pid> status            # 报告最终状态
```

不要仅因为用户提到“COM7”就跳过发现和状态确认。

## 案例 3：发送 HEX 并等待返回

```text
--pid <pid> status
--pid <pid> read --instanceId <instanceId> --afterSeq 0 --limit 1  # 取得当前 lastSeq
--pid <pid> send-hex --instanceId <instanceId> --data "01 03 00 00 00 02 C4 0B"
--pid <pid> read --instanceId <instanceId> --afterSeq <saved-lastSeq>
```

超时或 `truncated=true` 时如实报告，不把历史缓存误当作本次响应。

## 案例 4：发送 ASCII 命令

```text
--pid <pid> status
--pid <pid> read --instanceId <instanceId> --afterSeq 0 --limit 1  # 取得当前 lastSeq
--pid <pid> send-text --instanceId <instanceId> --data "<authorized-command>" --encoding ascii --suffix crlf
--pid <pid> read --instanceId <instanceId> --afterSeq <saved-lastSeq>
```

发送前确认命令内容和设备上下文；危险命令必须得到用户授权。

## 案例 5：多个 SerialMate 实例

为每个 `{pid, instanceId, port, lastSeq}` 建立独立记录，所有调用都带对应 `--pid`；`open`、`close`、发送和读取还必须带对应 `--instanceId`。禁止跨实例共享游标或猜测目标。

## 案例 6：长时间轮询设备

固定使用同一实例的递增 `lastSeq`：每轮先读取 `read --afterSeq <lastSeq>`，处理新记录后更新该实例游标。若返回 `truncated=true`，标记数据缺口并告知用户；不要声称可恢复已淘汰记录。

## 案例 7：设备拔出后的恢复

停止发送，重新执行 `--list-ports` 和 `--list-instances`。确认设备重新出现且实例身份匹配后，再 `status`、`open`，并从新的 `lastSeq` 开始读取。若实例已退出，按 `instance_not_found` 处理，不自动关闭或替换其它实例。

## Discovery Policy 测试案例

### Case 1：SerialMate GUI 已打开

环境中没有 `SERIALMATE_EXE`，PATH 中也没有 SerialMate。应从运行进程取得 `SerialMate.exe` 路径，执行 `--list-instances` 并直接使用返回实例；不得要求用户重复提供路径。

### Case 2：没有 GUI 实例但 EXE 存在

按标准位置找到 `SerialMate.exe` 后启动 SerialMate，最多等待 10 秒，再执行 `--list-instances`。Automation 可用后继续原任务；不得启动多个重复实例。

### Case 3：实例和 EXE 都不存在

完成全部搜索后停止，并提示：`未找到SerialMate。请安装SerialMate或提供SerialMate.exe路径。` 不要求必须加入 PATH，也不自动下载程序。

