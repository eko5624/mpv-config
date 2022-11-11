### fft3d降噪

import vapoursynth as vs
from vapoursynth import core

input = video_in

fft3d_core = 1
denoise_lv = 2.0
channel = [0]
blk_frames = 3
CPU_t = 6
channel_p = False
# fft3d内核 1=FFT3DFilter // 2=Neo FFT3D
# 降噪强度
# 降噪处理的平面
# -1=仅锐化和去光晕 // 0=Temporal Kalman // 1=2D (spatial) Wiener // 2 --- 5 =N帧的3D Wiener
# 使用的处理器线程
# 是否并行处理各个平面

if fft3d_core == 1 :
	output = core.fft3dfilter.FFT3DFilter(clip=input, sigma=denoise_lv, planes=channel, bt=blk_frames, ncpu=CPU_t, mt=channel_p)
if fft3d_core == 2 :
	output = core.neo_fft3d.FFT3D(clip=input, sigma=denoise_lv, planes=channel, bt=blk_frames, ncpu=CPU_t, mt=channel_p)

output.set_output()
