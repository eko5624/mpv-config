### mvtools倍帧，一般开销

import vapoursynth as vs
from vapoursynth import core

input = video_in

recal = True
Block_mode = True
# 优化首次分析 True // False
# Block补偿模式 True // False

if container_fps > 32 :
	raise Exception("源帧率超过限制的范围，已临时禁用该脚本。")

cut1 = core.std.AssumeFPS(clip=input, fpsnum=int(container_fps * 1000), fpsden=1000)
cut_s = core.mv.Super(clip=cut1, pel=1, sharp=0)
cut_b = core.mv.Analyse(super=cut_s, blksize=32, isb=True, search=2)
cut_f = core.mv.Analyse(super=cut_s, blksize=32, search=2)

if recal == True :
	cut_b = core.mv.Recalculate(super=cut_s, vectors=cut_b, blksize=16, search=2, searchparam=1, thsad=200)
	cut_f = core.mv.Recalculate(super=cut_s, vectors=cut_f, blksize=16, search=2, searchparam=1, thsad=200)
else :
	cut_b, cut_f = cut_b, cut_f

if Block_mode == True :
	output = core.mv.BlockFPS(clip=cut1, super=cut_s, mvbw=cut_b, mvfw=cut_f, num=container_fps * 2 * 1000, den=1000)
else :
	output = core.mv.FlowFPS(clip=cut1, super=cut_s, mvbw=cut_b, mvfw=cut_f, num=container_fps * 2 * 1000, den=1000, mask=1)

output.set_output()
