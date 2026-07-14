# LinkerHand-UniDexGrasp 复现仓库

这个仓库用于记录我复现 [LinkerHand-UniDexGrasp](https://github.com/linker-bot/linkerhand-unidexgrasp) 的过程。

`main` 分支只作为仓库导航页。具体实验记录分别保存在下面两个独立分支中。

## 分支说明

### 1. `portfolio-showcase`：项目整体复现记录

[进入 portfolio-showcase 分支](https://github.com/Zeil6/linkerhand-unidexgrasp-reproduction/tree/portfolio-showcase)

这个分支记录整个项目的复现过程，内容包括：

- Python、PyTorch、CUDA 和 Isaac Gym 环境搭建。
- Generation、数据转换、PPO训练、checkpoint测试和可视化流程。
- GraalVM、Python ABI、CSDF、PointNet2、gymtorch和资产路径等问题。
- 我在排错过程中出现过的错误判断、修正过程和最终认识。
- 项目架构、PPO代码流程、验证边界和辅助运行脚本。

如果想了解我是如何从零开始逐层复现整个项目，建议先阅读这个分支。

### 2. `official-model-personal-review`：官方模型专项复现

[进入 official-model-personal-review 分支](https://github.com/Zeil6/linkerhand-unidexgrasp-reproduction/tree/official-model-personal-review)

这个分支集中记录官方 `example_model/model.pt` 的复现和身份判断，内容包括：

- 我最初为什么误以为官方模型可以直接用于 LinkerHand L20。
- 如何通过checkpoint参数形状、输入维度和参数名称判断模型来源。
- 官方模型实际对应ShadowHand、DAgger状态专家、300维输入和24维动作。
- 我的L20模型对应PPO和27维动作，两者不能直接比较性能。
- 数据schema、21/22关节差异、资产缺失、`map_location`和reset mask等问题。
- checkpoint、NPZ和资产检查脚本，以及官方expert和L20 policy的独立运行入口。

如果想了解官方权重为什么不能直接用于L20，以及我是如何修正这一判断的，可以阅读这个分支。

## 推荐阅读顺序

```text
portfolio-showcase
└── 先了解整个项目、环境、训练流程和通用失败复盘
    └── official-model-personal-review
        └── 再阅读官方 model.pt 的专项排错过程
```

## 当前结论

我完成了项目核心工程流程和官方模型加载路径的复现，但没有在论文完整数据集和评估协议上验证benchmark，也不报告未经验证的成功率。两个分支保留了不同阶段的实验记录，目前不相互覆盖。