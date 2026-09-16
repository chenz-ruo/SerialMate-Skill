# 多实例与多 COM

一个 SerialMate 进程最多拥有一个 COM 口。需要同时操作多个 COM 时，使用多个 SerialMate 实例，并为每个实例维护独立记录：

```text
target instance = {
  pid,
  instanceId,
  port,
  lastSeq
}
```

## 选择实例

1. 用 `--list-instances` 获取运行中的实例。
2. 用 `--list-ports` 确认设备和 COM 元数据。
3. 将目标端口与明确的 `pid`/`instanceId` 绑定。
4. 每次调用使用对应实例的 `--pid`，并先 `status`。

如果存在多个可能匹配项，要求用户指定目标；不能维护一个全局 current port，也不能把一个实例的 sequence 用到另一个实例。

## 游标隔离

每个实例的 `lastSeq` 独立保存。发送前读取该实例状态，发送后只对同一实例执行 `read --afterSeq <that-instance-lastSeq>`。设备拔出、实例重启或重新绑定后，重新发现实例并建立新的游标，不要复用旧实例的序号。

