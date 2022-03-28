##倍帧，转8bit，低开销（高于32帧的源自动忽略）

import vapoursynth as vs
core = vs.core
clip = video_in

vden = 1000
dden = 1000

if (container_fps < 32):
    clip = clip.resize.Point(format=vs.YUV420P8)
    vfps = container_fps*vden
    dfps = container_fps*2*dden

    clip = core.std.AssumeFPS(clip, fpsnum=int(vfps), fpsden=vden)
    super = core.mv.Super(clip, pel=1, sharp=0, rfilter=2)
    mvfw = core.mv.Analyse(super, blksize=32, isb=False, search=2, searchparam=2)
    mvbw = core.mv.Analyse(super, blksize=32, isb=True, search=2, searchparam=2)
    mvfw = core.mv.Recalculate(super, mvfw, blksize=16, search=2, searchparam=1, thsad=200)
    mvbw = core.mv.Recalculate(super, mvbw, blksize=16, search=2, searchparam=1, thsad=200)
    clip = core.mv.BlockFPS(clip, super, mvbw, mvfw, num=dfps, den=dden)
    
    ##num/den=目标帧率
    
    clip.set_output()
