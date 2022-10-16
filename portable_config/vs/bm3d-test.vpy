### BM3D降噪

import vapoursynth as vs
from vapoursynth import core

input = video_in

bm3d_core = 3
denoise_lv = [5,1,1]
ref_bs = 8
cut2_bs = 7
GPU = 0
# 1=bm3dcpu // 2=bm3dcuda // 3=bm3dcuda_rtc
# 每平面的降噪强度
# block_step 1-8
# 小于等于ref_bs
# 使用cuda的设备（不支持bm3dcpu）

cut1 = core.fmtc.bitdepth(clip=input, bits=32)

if bm3d_core == 1 :
	ref = core.bm3dcpu.BM3D(clip=cut1, sigma=denoise_lv, block_step=ref_bs)
	cut2 = core.bm3dcpu.BM3D(clip=cut1, ref=ref, sigma=denoise_lv, block_step=cut2_bs)
if bm3d_core == 2 :
	ref = core.bm3dcuda.BM3D(clip=cut1, sigma=denoise_lv, block_step=ref_bs, device_id=GPU)
	cut2 = core.bm3dcuda.BM3D(clip=cut1, ref=ref, sigma=denoise_lv, block_step=cut2_bs, device_id=GPU)
if bm3d_core == 3 :
	ref = core.bm3dcuda_rtc.BM3D(clip=cut1, sigma=denoise_lv, block_step=ref_bs, device_id=GPU)
	cut2 = core.bm3dcuda_rtc.BM3D(clip=cut1, ref=ref, sigma=denoise_lv, block_step=cut2_bs, device_id=GPU)

output = core.fmtc.bitdepth(clip=cut2, bits=16)

output.set_output()
