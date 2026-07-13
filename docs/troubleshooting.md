# 技术故障复盘

本复盘统一采用“现象 → 根因 → 排查 → 修复 → 可迁移经验”。其中环境组合与故障类型来自本次工程过程；具体性能数字未在本仓库中验证。

## 1. GraalVM 与 Python ABI

- **现象**：安装成功但导入 PyTorch 时提示无法加载 `torch/_C` 或 C extensions。
- **根因**：环境中的 `python` 曾指向 GraalVM，而 PyTorch wheel 面向 CPython ABI 编译。
- **排查**：检查 `which python`、`python -VV`、`platform.python_implementation()` 与 wheel tag。
- **修复**：恢复 CPython 3.8，清理错误安装，在同一解释器内重新安装 PyTorch 和扩展。
- **可迁移经验**：二进制包导入失败时，解释器实现和 ABI 的优先级高于业务代码。

## 2. PyTorch、CUDA 与 RTX 4090

- **现象**：CUDA 扩展编译失败、kernel 不支持或运行时架构不匹配。
- **根因**：RTX 4090 属于较新的 Ada 架构，而项目固定在旧 PyTorch/CUDA 研究栈。
- **排查**：分开检查 NVIDIA driver、`torch.version.cuda`、GPU capability、nvcc 和扩展编译参数。
- **修复**：保留驱动对旧 runtime 的兼容能力；按扩展要求设置架构列表并重新编译。不能仅靠升级某一个包解决整套依赖。
- **可迁移经验**：驱动、CUDA runtime、toolkit、PyTorch wheel 和目标 GPU 架构是五个不同层次。

## 3. CSDF

- **现象**：`pip install -e .` 后仍导入失败或运行期报本地扩展错误。
- **根因**：扩展在错误解释器/torch 环境下编译，或依赖链不完整。
- **排查**：确认 editable install 指向、构建日志、生成的 `.so` 和其链接依赖。
- **修复**：固定 Python/torch/CUDA 后清理 build 目录并在最终环境重编译。
- **可迁移经验**：本地 CUDA 扩展是环境产物，不能简单跨环境复制。

## 4. PointNet2

- **现象**：安装失败、CUDA op 不可用，或点云输入触发 dtype/shape 错误。
- **根因**：旧 PointNet2 实现依赖特定 torch/CUDA API；输入 tensor 契约也可能不一致。
- **排查**：先做独立 import/op smoke test，再打印 point cloud shape、dtype、device。
- **修复**：从源码在当前环境编译，统一 `float32`、contiguous tensor 和 CUDA device。
- **可迁移经验**：把“扩展能导入”和“真实输入能运行”作为两个测试层次。

## 5. Isaac Gym / gymtorch

- **现象**：gymtorch 编译或加载失败、viewer 黑屏、纹理或 graphics 为空。
- **根因**：Isaac Gym Preview 与 Python、torch、NumPy、显示环境或资产路径不兼容。
- **排查**：先跑官方 examples；再分别测试 headless、viewer、单资产和项目 task。
- **修复**：固定兼容版本，确认显示/无头模式，修复资产路径后再进入策略代码。
- **可迁移经验**：先证明仿真平台可用，再调业务 task，能显著缩小搜索空间。

## 6. PyTorch tensor 类型兼容

- **现象**：索引、拼接、赋值或 gym tensor API 报 dtype/device 不一致。
- **根因**：NumPy 默认类型、CPU tensor 与 CUDA tensor、`int32/int64` 索引混用。
- **排查**：在接口边界打印 shape、dtype、device，定位第一次发生偏差的位置。
- **修复**：在数据入口显式转换，避免在深层函数中被动修补。
- **可迁移经验**：shape/dtype/device 是 tensor API 的完整契约。

## 7. 模型与资产路径

- **现象**：checkpoint、MJCF、纹理或 object asset 找不到；换目录运行后失效。
- **根因**：相对路径依赖当前工作目录，或代码残留 `/home/ubuntu`、`/home/chen` 等绝对路径。
- **排查**：打印 `cwd` 和解析后的绝对路径，逐层检查文件是否存在。
- **修复**：以 repo root/config 为基准解析路径；脚本使用 `UNIDEX_ROOT` 和 `CHECKPOINT`。
- **可迁移经验**：路径应由配置注入，并在程序启动阶段 fail fast。

## 通用排障树

```text
运行失败
├── 解释器层：CPython? 版本? ABI?
├── Python 包层：版本锁定? 安装位置?
├── 二进制扩展层：编译器? CUDA arch? .so?
├── GPU 层：driver? runtime? capability?
├── 仿真层：官方 example? headless/viewer?
├── 数据层：shape? dtype? device? 坐标系?
└── 应用层：配置? 模型结构? 路径?
```