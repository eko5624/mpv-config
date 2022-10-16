### rife v2.3 & mvtools blending

import vapoursynth as vs
from vapoursynth import core

input = video_in

GPU = 0
GPU_t = 2

if container_fps > 32 :
	raise Warning("源帧率超过限制的范围，已临时禁用该脚本。")

cut0 = core.misc.SCDetect(clip=input, threshold=0.2)
cut1 = cut0.resize.Bilinear(format=vs.RGBS, matrix_in_s="709")
cut2 = core.rife.RIFE(clip=cut1, model=5, gpu_id=GPU, gpu_thread=GPU_t, tta=False, uhd=False, sc=True)
fin_rife = cut2.resize.Bilinear(format=vs.YUV444P16, matrix_s="709")
if input.get_frame(0).props._ColorRange == 0 :
	fin_rife = fin_rife.resize.Bilinear(range=1)

ref = core.std.AssumeFPS(clip=fin_rife, fpsnum=int(container_fps * 2 * 1000), fpsden=1000)
cut_s = core.mv.Super(clip=ref, pel=1, sharp=0, rfilter=0)
cut_b = core.mv.Analyse(super=cut_s, blksize=128, search=0, searchparam=0, pelsearch=0, search_coarse=0, isb=True)
cut_f = core.mv.Analyse(super=cut_s, blksize=128, search=0, searchparam=0, pelsearch=0, search_coarse=0)
output = core.mv.FlowFPS(clip=ref, super=cut_s, mvbw=cut_b, mvfw=cut_f, num=(display_fps * 1000), den=1000, thscd1=0, thscd2=0)

output.set_output()
