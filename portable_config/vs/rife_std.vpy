### rife v4 补帧，性能要求非常高

import vapoursynth as vs
from vapoursynth import core

input = video_in
colorlv = input.get_frame(0).props._ColorRange
fmt_fin = input.format.id

FPS_num = 2
FPS_den = 1
GPU = 0
GPU_t = 2
# FPS_num/FPS_den 的值即帧率倍数（分子分母必须为整数，计算结果可为浮点；只支持 v4 模型）
# .
# 使用的显卡序号，0为排序一号
# 使用的显卡线程数

if container_fps > 32 :
	raise Exception("源帧率超过限制的范围，已临时禁用该脚本。")

cut0 = core.misc.SCDetect(clip=input, threshold=0.2)

cut1 = cut0.resize.Bilinear(format=vs.RGBS, matrix_in_s="709")
cut2 = core.rife.RIFE(clip=cut1, model=9, factor_num=FPS_num, factor_den=FPS_den, gpu_id=GPU, gpu_thread=GPU_t, sc=True, skip=True, skip_threshold=60.0)

output = cut2.resize.Bilinear(format=fmt_fin, matrix_s="709", range=1 if colorlv==0 else None)

output.set_output()
