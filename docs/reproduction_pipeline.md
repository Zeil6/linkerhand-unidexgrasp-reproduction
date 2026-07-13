# 我的复现步骤与验证顺序

这不是一份假设所有环境都相同的安装教程，而是我实际采用的验证顺序。

## 1. 先确认解释器

我曾经只检查 `python --version`，后来发现 Python 已经被切换成 GraalVM。之后我会同时检查：

```bash
which python
python -VV
python -c "import platform,sys; print(platform.python_implementation()); print(sys.executable)"
```

因为 PyTorch、CSDF 和 PointNet2 包含面向 CPython ABI 的本地扩展。

## 2. 再确认 PyTorch 与 CUDA

```bash
nvidia-smi
nvcc --version
python -c "import torch; print(torch.__version__, torch.version.cuda); print(torch.cuda.is_available())"
```

我最初把 `nvidia-smi` 显示的 CUDA 版本当成 PyTorch runtime。后来才明确 driver、runtime、toolkit 和目标 GPU 架构是不同层次。

## 3. 独立验证本地扩展

CSDF、PointNet2 和 gymtorch 都应在最终环境中重新构建。我先验证 import，再用最小输入验证 op，不直接从完整训练脚本开始。

## 4. 运行 Isaac Gym 官方示例

如果 `joint_monkey.py` 等官方 example 无法运行，我不会继续修改 PPO。这样可以先区分平台错误与项目 task 错误。

## 5. 检查 generation 数据

我逐项确认：

- 物体标识和目录是否对应。
- qpos 的关节数、名称与顺序。
- 世界系、物体系和手腕系之间的位姿。
- 四元数顺序。
- NumPy/PyTorch 的 shape、dtype 和 device。

只重命名字段不能解决机器人关节定义不同的问题。

## 6. 进入 PPO 训练

```bash
export UNIDEX_ROOT=/path/to/linkerhand-unidexgrasp
bash scripts/train.sh state
```

训练过程中我主要观察 reward、episode length、value loss、surrogate loss 和 checkpoint 是否按配置保存。曲线本身需要结合 reward 定义解释。

## 7. 测试 checkpoint

```bash
CHECKPOINT=/absolute/path/model.pt bash scripts/test_checkpoint.sh state
```

加载前我会确认权重、网络类、observation、action、任务 YAML 和代码版本是否对应，而不是仅确认文件存在。

## 8. 记录结果

每次结果至少应附带 commit、命令、配置、对象列表、checkpoint 和日期。没有完整指标时，我只描述实际观察到的运行状态。