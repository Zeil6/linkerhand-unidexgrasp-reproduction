# 逐层技术故障记录

我按实际排查习惯把问题分层记录。这里的“修复”只描述我为推进当前复现做过的处理，不把普通兼容修改写成算法创新。

## 1. wheel 与 Python ABI

- **现象**：`torch_sparse` 的 `cp38` wheel 被判定不支持。
- **我最初的判断**：下载源或包文件损坏。
- **实际检查**：wheel tag 与当前解释器实现、版本不匹配。
- **处理**：恢复 CPython 3.8，使用 `python -m pip` 确保 pip 与解释器一致。
- **反思**：二进制 wheel 的 ABI 约束比镜像源更优先。

## 2. GraalVM 与 `torch/_C`

- **现象**：`Failed to load PyTorch C extensions (torch/_C)`。
- **我最初的判断**：PyTorch 版本本身损坏。
- **实际检查**：Python 一度变成 GraalVM，无法满足 CPython 扩展 ABI。
- **处理**：恢复 CPython，清理错误环境产生的 build、wheel 和 extension 缓存后重装。
- **反思**：Python 能运行纯 Python 代码，不代表能加载 CPython `.so`。

## 3. RTX 4090 与旧 CUDA 栈

- **现象**：本地 CUDA 扩展出现架构和编译问题。
- **我最初的判断**：新驱动应该自动兼容所有旧代码。
- **实际检查**：驱动向后兼容不代表旧 nvcc 和扩展构建脚本认识 Ada 架构。
- **处理**：分开检查 driver、runtime、toolkit、torch 和 compute capability，清理后重编译扩展。
- **反思**：不能用单一的“CUDA 版本”概括整套 GPU 软件栈。

## 4. CSDF 与 PointNet2

- **现象**：editable install 后仍可能导入或运行失败。
- **我最初的判断**：`pip install -e .` 成功即说明依赖完成。
- **实际检查**：扩展可能在错误 torch/CUDA 环境编译，真实 tensor 还可能不满足 shape、dtype、device 和 contiguous 要求。
- **处理**：固定最终环境后重编译，依次完成 import test、minimal op test 和真实输入测试。
- **反思**：扩展安装和数据契约是两个独立验证层。

## 5. Isaac Gym 与 graphics

- **现象**：gymtorch/NumPy 兼容警告，或 `Graphics is nullptr in GymCreateTextureFromFile`。
- **我最初的判断**：显卡驱动异常。
- **实际检查**：问题还可能来自 headless 配置、graphics device、显示环境或纹理路径。
- **处理**：固定 `gym==0.23.1`、`numpy==1.23.5` 等兼容组合，先跑官方 example，再分别检查 physics、graphics 和 asset。
- **反思**：图形错误不应直接归因于 CUDA，也可能是无效资产路径触发的后续错误。

## 6. Tensor 类型

- **现象**：索引、拼接、赋值或 gym tensor API 报 dtype/device 不一致。
- **处理**：在数据入口和 task 边界打印 `shape/dtype/device/is_contiguous`，定位第一次偏离契约的位置。
- **反思**：PyTorch tensor 的接口不是只有 shape，还包括 dtype、device 和 layout。

## 7. 模型与资产路径

- **现象**：换工作目录后找不到 checkpoint、MJCF、纹理或物体。
- **我最初的判断**：文件明明存在，应该是加载代码错误。
- **实际检查**：相对路径依赖当前工作目录，旧代码中还可能残留服务器绝对路径。
- **处理**：以 repo root/config 为基准解析路径，通过环境变量注入并在启动时 fail fast。
- **反思**：路径问题应在任务创建前暴露，而不是等到底层 API 返回空对象。

更完整的时间顺序见 [完整复现与失败复盘](full_reproduction_retrospective.md)。