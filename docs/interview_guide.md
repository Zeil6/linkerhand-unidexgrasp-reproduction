# 面试讲解提纲

## 30 秒版本

我复现了 LinkerHand-UniDexGrasp 的核心工程流程，覆盖抓取候选生成、数据转换、Isaac Gym 并行环境中的 PPO 训练、checkpoint 测试和可视化。最大的工作量不在运行命令，而在让旧版 Python/PyTorch/CUDA 研究栈适配新硬件。我通过分层排查解决了 GraalVM ABI、RTX 4090 CUDA 架构、CSDF/PointNet2 扩展、gymtorch 类型和模型路径问题。最终完成核心流程验证，但没有把论文成功率当作自己的结果。

## 2 分钟版本

1. **问题背景**：灵巧手抓取需要连接抓取生成与策略执行两部分。
2. **工程挑战**：上游依赖 Ubuntu 20.04、Python 3.8、PyTorch 1.10、CUDA 11.3 和 Isaac Gym Preview，和新显卡环境存在时间跨度。
3. **排障方法**：按解释器 ABI → Python wheel → CUDA 扩展 → Isaac Gym → task → PPO 的顺序验证。
4. **算法理解**：PPO 在并行环境采样 rollout，通过 GAE 估计 advantage，再用 clipped objective 限制策略更新幅度。
5. **结果边界**：跑通核心工程流程和可视化；未在完整数据集上复测论文指标。

## 可能追问

### 为什么 GraalVM 会让 PyTorch 失败？

PyTorch wheel 包含按 CPython ABI 编译的本地扩展。解释器能运行 Python 语法，不代表能加载该 ABI 的 `.so`。

### 新驱动为什么能运行旧 CUDA runtime？

NVIDIA 驱动通常对旧 CUDA runtime 提供向后兼容，但本地扩展编译还要考虑 toolkit、torch API 和 GPU compute capability。

### PPO 为什么需要 clipping？

同一批 rollout 被重复更新时，策略可能变化过大。概率比裁剪限制更新幅度，提高训练稳定性。

### 视觉策略为什么更难？

除了控制学习，还加入点云采样、PointNet2 编码、显存开销和 sim-to-real 观测差异，错误链路更长。

### 如何证明不是只会调环境？

可以从 observation/action/reward 定义讲到 rollout storage、GAE、PPO update 和 checkpoint 恢复，并解释每个接口的 shape、dtype、device 契约。

## 诚实回答未完成项

当前可以确认核心工程链路已跑通，但没有足够证据声称达到论文成功率。下一步应固定 commit 与配置，在明确的数据划分上重复评估并报告均值、方差和随机种子。