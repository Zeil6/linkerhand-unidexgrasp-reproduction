# 官方 `example_model/model.pt` 复现记录

这份记录按我实际排错的先后顺序整理。每一阶段都保留“当时的判断—报错—分析—根因—修改—验证—反思”，因为最终答案本身无法说明我为什么改变判断。

## 阶段 0：我最初把官方模型理解成 L20 示例模型

### 当时的判断

我看到权重位于 LinkerHand 适配仓库的 `example_model/model.pt`，因此自然地认为它可以直接放进 L20 的 PPO 测试命令。

### 报错现象

模型路径能够解析，但后续逐渐出现资产、输入维度和参数不匹配。最开始我把这些错误当作普通路径问题，没有先问“这个模型究竟属于哪个机器人和算法”。

### 我的分析与实际根因

我后来检查了 checkpoint 的参数名称与矩阵形状，并对照 `process_dagger`、DAgger 中的 `actor_expert` 和任务空间。证据指向同一个结论：

- checkpoint 的第一层对应 300 维状态输入；
- 输出侧对应 ShadowHand task 的 24 维动作；
- DAgger 实现显式创建 300 维 `expert_observation_space`；
- 官方启动脚本通过 `--expert_model_dir=example_model/model.pt` 加载它。

它实际是 ShadowHand、22 DOF 数据、24 维动作的 DAgger 状态专家，不是我的 L20 PPO 权重。

### 修改方法

我停止把它送入 L20 PPO 路径，改为沿 DAgger expert 路径复现，并把 L20 与官方 expert 视为两个独立实验。

### 验证结果

模型身份与代码路径、参数形状和启动参数能够互相印证。两种模型不能直接比较性能。

### 反思

我一开始过度相信文件名和目录名，没有先检查 checkpoint 的参数形状。科研代码中的“example”只说明作者把文件放在这里，不说明它适配当前分支里的所有机器人。

## 阶段 1：运行前缺少三类数据目录

### 当时的判断

我起初以为仓库已经包含测试官方权重所需的最小数据。

### 报错现象

task 在查找对象、点云特征或缩放网格时，缺少：

- `datasetv4.1`
- `meshdatav3_pc_feat`
- `meshdatav3_scaled`

### 我的分析

这些目录分别参与抓取数据、点云特征和缩放后的物体资产读取。checkpoint 本身不包含这些任务资源。

### 实际根因

上游仓库与模型权重只提供了部分代码和示例，运行 task 仍依赖外部数据。

### 修改方法

我补齐任务实际访问的目录，并在启动前验证 YAML 中每个 object code 对应的数据、点云和 mesh 是否同时存在。

### 验证结果

程序越过了最初的目录缺失错误，继续进入对象加载。

### 反思

模型能被找到，不代表它能在当前任务中运行。checkpoint 只是实验的一部分。

## 阶段 2：原配置中的 Car 对象不存在

### 当时的判断

我认为只要沿用官方 YAML 中的 `object_code_dict`，对象就应该存在。

### 报错现象

`sem/Car-...` 在本地三套资产目录中无法形成完整对应。

### 我的分析与实际根因

YAML 描述的是作者环境中的对象集合，本地下载或转换后的资产并不一定包含同一个 Car。只修改路径无法生成不存在的资产。

### 修改方法

我没有继续伪造 Car 路径，而是筛选三类资源都完整的 cellphone、jar、bowl、bottle，并更新 `object_code_dict`。

### 验证结果

对象加载进入下一阶段。后来官方模型和我的 L20 模型显示不同物体，也由各自 YAML 的 `object_code_dict` 解释，而不是 checkpoint 内保存了对象。

### 反思

配置文件不是事实来源，文件系统也必须参与验证。科研项目经常只开源配置的一部分上下文。

## 阶段 3：L20 NPZ 的字段名与官方 task 不一致

### 当时的判断

我最初认为把 L20 的 `arr_0/arr_1/arr_2` 重命名成 `qpos/scale/plane` 就可以复用。

### 报错现象

官方任务按名称读取 `qpos/scale/plane`，L20 文件只有 NumPy 默认字段。

### 我的分析

字段名确实不一致，但我继续检查 shape 后发现更深层问题：L20 与 ShadowHand 的关节数不同。

### 实际根因

这不是单纯 schema 命名问题。L20 数据对应 21 个关节，官方 ShadowHand 数据对应 22 个关节；两套 qpos 的语义和关节顺序不同。

### 修改方法

我放弃简单重命名，从 `result.pt` 中重新生成符合 ShadowHand task 预期的 `qpos/scale/plane` 数据，并检查每个字段的 shape 和 dtype。

### 验证结果

官方 task 能按预期 schema 读取数据。

### 反思

数据文件存在，不代表数据 schema 与代码一致；schema 名称一致，也不代表物理语义一致。机器人关节数据必须同时确认数量、顺序、名称和定义。

## 阶段 4：task 构造函数缺少 `args`

### 当时的判断

我以为数据问题修复后，task 应该可以直接创建。

### 报错现象

任务构造函数的调用参数与定义不一致，缺少运行参数 `args`。

### 我的分析与实际根因

代码在不同版本或适配过程中修改过 task 构造签名，但创建路径没有同步。

### 修改方法

我沿 `train.py → parse_task → task constructor` 检查调用链，将 `args` 从入口向下传到 task，而不是在 task 内重新解析全局参数。

### 验证结果

任务完成构造并继续初始化网络。

### 反思

修复数据后出现构造函数错误，不代表之前的数据方向错了，而是程序终于运行到了下一层。

## 阶段 5：视觉 PPO 的 348 维输入与 checkpoint 的 300 维输入冲突

### 当时的判断

我曾尝试通过视觉 PPO 路径直接加载官方权重，因为官方脚本中也出现了 `--vision` 和 `model.pt`。

### 报错现象

网络第一层出现矩阵形状不匹配。视觉配置注释给出的实际输入为：

```text
300 - 64 - 16 + 128 = 348
```

而 checkpoint 第一层权重对应 300 维输入。

### 我的分析

我比较了 checkpoint 第一层形状、PPO `use_pc=True` 的视觉网络和 DAgger expert 的状态输入。348 维包含视觉特征替换后的观测设计，300 维则是状态专家观测。

### 实际根因

我选择了错误的模型加载路径。官方 checkpoint 不是视觉 PPO policy，而是 DAgger 使用的 state expert。

### 修改方法

我将官方权重放到 `--expert_model_dir`，由 DAgger 的 `actor_expert` 加载；不再通过视觉 PPO 的 `--model_dir` 强行加载。

### 验证结果

模型参数的输入维度与 expert observation 对齐。

### 反思

张量维度报错通常不是单独一行代码的问题，而是配置、任务观测和模型身份没有对齐。直接 reshape 或改线性层会破坏模型语义。

## 阶段 6：`map_location` 参数放错位置

### 报错现象

原测试代码类似：

```python
self.actor.load_state_dict(torch.load(path), map_location=self.device)
```

`load_state_dict` 不接收 `map_location`。

### 实际根因

`map_location` 属于反序列化阶段，应传给 `torch.load`。

### 修改方法

```python
state_dict = torch.load(path, map_location=self.device)
self.actor.load_state_dict(state_dict)
```

### 验证结果

checkpoint 能在指定 device 上反序列化并进入参数匹配。

### 反思

这是一个局部 API 错误，但只有先确认模型路径正确，修复它才有意义。否则只是让错误模型更顺利地加载到错误任务。

## 阶段 7：状态观测配置仍为 254

### 报错现象

官方 expert 需要 300 维输入，但 YAML 中 `numObservations` 仍为 254。

### 我的分析与实际根因

任务构建 observation space 时使用 YAML 数值，而 DAgger expert 固定按 300 维状态输入创建。配置与 checkpoint 的训练观测未对齐。

### 修改方法

在用于官方状态专家的配置中将 `numObservations: 254` 改为 `300`，同时检查实际 observation tensor 确实为 300 维。这里不能只改 YAML 而不检查 task 输出。

### 验证结果

环境声明、实际 tensor 和 checkpoint 第一层输入三者对齐。

### 反思

配置值不是越过 assert 的开关。修改配置后必须验证数据生产逻辑是否真的产生相同维度。

## 阶段 8：reset mask 不是 bool

### 报错现象

`torch.where(resets, ...)` 在当前 PyTorch 行为下要求 condition 为 bool。

### 实际根因

`resets` 保存为数值 tensor，旧代码依赖了历史版本中的宽松类型行为。

### 修改方法

```python
torch.where(resets.bool(), value_if_reset, value_if_keep)
```

### 验证结果

reset 分支能够继续运行，且条件语义更明确。

### 反思

旧科研代码升级时，类型收紧是常见兼容问题。显式类型转换比依赖隐式规则可靠。

## 阶段 9：桌面纹理缺失

### 报错现象

运行中出现桌面纹理找不到或 graphics texture 相关提示。

### 我的分析与实际根因

纹理属于视觉显示资产，不参与 checkpoint 参数和状态 expert 的核心计算。只要几何碰撞资产正常，它不应与模型输入维度问题混在一起处理。

### 修改方法

我将它记录为非阻塞问题：使用可用纹理或暂时关闭纹理依赖，同时保留桌面几何和物理属性。

### 验证结果

纹理问题不再阻止核心模型路径验证。

### 反思

报错需要按阻塞程度分类。不是所有红色输出都值得优先修改。

## 最终判断

| 对应关系 | 官方模型 | 我的模型 |
|---|---|---|
| 机器人 | ShadowHand | LinkerHand L20 |
| 数据关节数 | 22 | 21 |
| 算法角色 | DAgger state expert | PPO policy |
| 动作维度 | 24 | 27 |
| 输入维度 | 300 | 由 L20 task 定义 |
| 物体来源 | 官方 YAML `object_code_dict` | L20 YAML `object_code_dict` |

这一步让我建立了一个更可靠的复现顺序：先建立“模型—任务—机器人—数据—配置”的对应关系，再运行代码。每修复一层后出现新的错误，通常说明执行路径推进了，而不一定说明上一步判断错误。