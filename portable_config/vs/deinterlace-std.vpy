## znedi3参考，进行反交错

from vapoursynth import core

input=video_in

ref=core.znedi3.nnedi3(clip=input, field=3)
fin=core.yadifmod.Yadifmod(clip=input, edeint=ref, order=1, mode=1)

fin.set_output()
