# 核心工程流程复现

## 1. 建立兼容环境

推荐从上游声明的基线开始：Ubuntu 20.04、CPython 3.8、PyTorch 1.10.0、CUDA runtime 11.3 和 Isaac Gym Preview 3/4。新显卡并不意味着旧研究栈天然兼容，因此先运行 `scripts/check_environment.sh`。

验证顺序：

1. `platform.python_implementation()` 必须符合预编译 wheel 的 ABI 预期。
2. `torch.cuda.is_available()`、driver 和 runtime 状态正常。
3. Isaac Gym 官方 `joint_monkey.py` 可运行。
4. CSDF、PointNet2 等扩展在最终 conda 环境内重新构建。
5. 最后才运行项目脚本。

## 2. Grasp generation

上游提供 GraspIPDF、GraspGlow 和 ContactNet 训练入口：

```bash
cd "$UNIDEX_ROOT/dexgrasp_generation_forlinker"
python network/train.py --config-name ipdf_config --exp-dir ./ipdf_train
python network/eval.py --config-name eval_config --exp-dir ./eval
```

该阶段输出的是抓取候选或评估结果。运行前需按上游说明准备 DFCdata、MJCF 和第三方依赖。

## 3. 数据转换与资产检查

重点检查：

- 物体标识与资产目录是否一致。
- 手模型关节名称、顺序和自由度是否一致。
- 世界系、物体系、手腕系之间的位姿定义。
- 四元数顺序是 `xyzw` 还是 `wxyz`。
- tensor 的 shape、dtype 与 device。

转换后先对单个物体做可视化 sanity check，再扩大数据规模。

## 4. PPO 训练

```bash
export UNIDEX_ROOT=/path/to/linkerhand-unidexgrasp
bash scripts/train.sh state
```

脚本封装上游 `dexgrasp/script/run_train_ppo_state.sh`。训练日志与权重默认由上游配置决定，不应直接提交大型 `.pt` 文件。

TensorBoard 示例：

```bash
tensorboard --logdir /path/to/logs --port 6007 --bind_all
```

## 5. Checkpoint 测试

```bash
CHECKPOINT=/absolute/path/to/model.pt bash scripts/test_checkpoint.sh state
```

如果上游脚本不接受统一的 checkpoint 参数，测试脚本会停止并提示你查看实际 CLI，而不是猜测参数。加载前必须保证任务配置、观测维度、网络结构和训练时一致。

## 6. Isaac Gym 可视化

先用少量环境、关闭 headless，再检查：

- 手与物体是否正确生成。
- root state 和关节状态是否合理。
- 策略 action 是否写入目标 tensor。
- camera/viewer 是否初始化。
- 物体、模型和纹理路径是否真实存在。

## 7. 结果记录规范

每个可展示结果至少记录：commit、环境摘要、启动命令、配置、checkpoint 名称、日期和观察结论。没有完整指标时只描述可观察结果，不推导论文成功率。