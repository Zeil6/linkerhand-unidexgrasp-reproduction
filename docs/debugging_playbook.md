# 我的科研代码排错方法

这份方法不是把所有错误归结为“版本不兼容”，而是记录我在这次复现中逐渐形成的检查顺序。

## 1. 先写出对应关系

运行 checkpoint 前，我先回答五个问题：

| 维度 | 必须确认的内容 |
|---|---|
| 模型 | 算法、参数名称、第一层输入、最后一层输出 |
| 任务 | observation、action、reward、reset |
| 机器人 | DOF 数、受控关节数、关节顺序 |
| 数据 | key、shape、dtype、坐标/关节语义 |
| 配置 | task 名、`numObservations`、`object_code_dict`、资产根目录 |

任何一项无法确认时，我不会用 reshape、补零或重命名去强行越过错误。

## 2. 把错误按层级排列

```text
路径与文件存在性
└── 数据 schema 与资产完整性
    └── task 构造与配置
        └── observation/action space
            └── checkpoint 参数匹配
                └── rollout 与 reset
                    └── 行为和指标
```

每修复一层后出现新报错，说明程序进入了下一层。只有旧错误重新出现或验证结果冲突时，我才回退判断。

## 3. Checkpoint 检查

我不再只看文件名，而是：

```bash
python scripts/inspect_checkpoint.py /path/to/model.pt
```

关注：

- 是否为裸 `state_dict`，还是外层包含 `model`、`state_dict`。
- 第一组二维权重的第二维，通常能提示输入维度。
- 输出层和 `log_std` 等形状能提示动作维度。
- 参数前缀能提示 PPO actor、DAgger actor 或 expert。

这些只能形成证据，最终仍需与模型类代码对照。

## 4. 数据检查

```bash
python scripts/inspect_npz_schema.py /path/to/file.npz --expected qpos scale plane
```

我依次检查 key、shape、dtype、样本数和数值范围。对于机器人 qpos，还要检查关节名称与顺序；`21 → 22` 不能靠改字段名完成。

## 5. 资产检查

```bash
python scripts/validate_assets.py --root /path/to/dexgrasp --config /path/to/task.yaml
```

同一个 object code 可能需要同时存在抓取数据、点云特征和缩放 mesh。只找到其中一个目录不能说明对象完整。

## 6. 维度错误的处理

当出现 `mat1 and mat2 shapes cannot be multiplied` 时，我检查：

1. checkpoint 第一层输入维度。
2. 环境声明的 observation space。
3. reset/step 实际返回的 tensor shape。
4. 是否启用了 vision/backbone，导致特征替换。
5. YAML 的 `numObservations` 是否与 task 实现一致。

我不会先修改线性层，因为这会让预训练权重失去意义。

## 7. 阻塞与非阻塞问题

- **阻塞**：模型/任务不匹配、资产缺失、schema 错误、shape/dtype/device 错误。
- **非阻塞**：不影响物理与策略输入的纹理缺失、部分显示警告。

非阻塞问题仍记录，但不抢占核心链路的排错顺序。

## 8. 每次修改后的验证

我尽量使用最小验证，而不是直接启动长时间训练：

- checkpoint：打印参数形状，不创建环境。
- NPZ：只加载并检查 schema。
- assets：只遍历 YAML 对象并检查三套目录。
- task：单环境、短 episode。
- policy：先完成一次 reset 和一次 step。
- 最后再扩大环境数或启动训练。

## 9. 我修正过的几个错误习惯

- 原来我过度相信目录名；现在先检查参数形状。
- 原来我认为文件存在就可以使用；现在检查 schema 和物理语义。
- 原来我把新报错误解为前面修错了；现在先判断执行是否推进。
- 原来我倾向于直接改维度；现在先追溯 observation 的设计来源。
- 原来我把所有输出问题都当阻塞；现在区分核心计算和显示资产。