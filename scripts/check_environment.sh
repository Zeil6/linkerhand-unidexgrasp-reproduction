#!/usr/bin/env bash
set -euo pipefail

echo '[1/5] Python interpreter'
python - <<'PY'
import platform, sys
print('executable:', sys.executable)
print('version:', sys.version.replace('\n', ' '))
print('implementation:', platform.python_implementation())
if platform.python_implementation() != 'CPython':
    raise SystemExit('ERROR: binary wheels in this stack expect CPython, not GraalVM or PyPy')
PY

echo '[2/5] PyTorch and CUDA'
python - <<'PY'
import torch
print('torch:', torch.__version__)
print('torch CUDA runtime:', torch.version.cuda)
print('CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('GPU:', torch.cuda.get_device_name(0))
    print('capability:', torch.cuda.get_device_capability(0))
PY

echo '[3/5] NVIDIA driver'
command -v nvidia-smi >/dev/null && nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader || echo 'WARN: nvidia-smi unavailable'

echo '[4/5] Project paths'
ROOT="${UNIDEX_ROOT:-$(pwd)}"
for p in dexgrasp_generation_forlinker dexgrasp_policy_l20hand; do
    test -d "$ROOT/$p" || { echo "ERROR: missing $ROOT/$p"; exit 1; }
done

echo '[5/5] Optional native modules'
python - <<'PY'
import importlib.util
for name in ('isaacgym', 'pointnet2_ops'):
    print(f'{name}:', 'found' if importlib.util.find_spec(name) else 'NOT FOUND')
PY

echo 'Environment smoke check finished. Run an Isaac Gym official example before project training.'