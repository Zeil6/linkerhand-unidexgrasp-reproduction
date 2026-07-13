# 官方模型复现整理记录

## 本分支的目的

我从 `portfolio-showcase` 单独建立本分支，把仓库改写成个人实验记录，重点整理 `example_model/model.pt` 的身份判断与复现过程。没有修改 `main` 和 `portfolio-showcase`。

## 文档修改

- 重写 `README.md`：以我的动机、过程、判断变化和限制为主。
- 新增 `docs/official_model_reproduction.md`：按时间顺序记录官方模型复现。
- 新增 `docs/debugging_playbook.md`：整理模型—任务—机器人—数据—配置的排错方法。
- 新增本文件，记录本轮修改范围。

## 辅助脚本

- `inspect_checkpoint.py`：检查 checkpoint 容器、参数名和矩阵形状。
- `validate_assets.py`：检查 YAML 对象在多套资产目录中的完整性。
- `inspect_npz_schema.py`：检查 NPZ key、shape、dtype 与预期 schema。
- `run_official_expert.sh`：通过 DAgger `expert_model_dir` 启动 ShadowHand expert。
- `run_l20_policy.sh`：独立启动 L20 PPO policy，避免与官方 expert 混用。

## 关键代码修正记录

实际复现过程中涉及的核心修正包括：

1. 补齐 `datasetv4.1`、`meshdatav3_pc_feat`、`meshdatav3_scaled`。
2. 移除缺失 Car，筛选完整的 cellphone、jar、bowl、bottle。
3. 从 `result.pt` 重新生成 `qpos/scale/plane` ShadowHand 数据。
4. task 构造链补传 `args`。
5. 官方模型改走 DAgger expert 路径。
6. `torch.load(path, map_location=device)` 后再调用 `load_state_dict`。
7. 官方状态 expert 配置与实际观测对齐为 300 维。
8. reset condition 使用 `resets.bool()`。
9. 将桌面纹理缺失标为非阻塞显示问题。

本分支不提交上游源码副本、权重、数据集、日志或服务器备份。