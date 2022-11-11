### nnedi3作参考，进行反交错（倍帧模式）

import vapoursynth as vs
from vapoursynth import core

input = video_in

edi_core = 2
GPU = -1
deint_core = 3
# 使用的参考核心 1=nnedi3 // 2=znedi3 // 3=nnedi3cl
# 使用OpenCL加速的设备（仅支持 nnedi3cl）
# 去隔行的执行核心 1=tdm // 2=yadifmod // 3=bwdif

if edi_core == 1 :
	ref = core.nnedi3.nnedi3(clip=input, field=3)
if edi_core == 2 :
	ref = core.znedi3.nnedi3(clip=input, field=3)
if edi_core == 3 :
	ref = core.nnedi3cl.NNEDI3CL(clip=input, field=3, device=GPU)

if deint_core == 1 :
	output = core.tdm.TDeintMod(clip=input, order=1, mode=1, length=6, ttype=0, edeint=ref)
if deint_core == 2 :
	output = core.yadifmod.Yadifmod(clip=input, edeint=ref, order=1, mode=1)
if deint_core == 3 :
	output = core.bwdif.Bwdif(clip=input, field=3, edeint=ref)

output.set_output()
