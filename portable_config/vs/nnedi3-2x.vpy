### 使用nnedi3算法进行两倍放大
### 追求速度应使用着色器版本，例如 ../shaders/nnedi3-nns128-win8x4.glsl

import vapoursynth as vs
from vapoursynth import core
from nnedi3_resample import nnedi3_resample

input = video_in

edi_nsize = 4
edi_nns = 3
edi_core = "znedi3"
GPU = -1
# 4：8x4 // 5：16x4 // 6：32x4
# 2：64  // 3：128  // 4：256
# "znedi3" // "nnedi3" // "nnedi3cl"
# 仅nnedi3cl支持显卡加速

output = nnedi3_resample(input=input, target_width=input.width * 2, target_height=input.height * 2, nsize=edi_nsize, nns=edi_nns, mode=edi_core, device=GPU)

output.set_output()
