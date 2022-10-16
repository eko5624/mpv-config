### svpflow补60帧，一般消耗，补偿帧为8位

import vapoursynth as vs
from vapoursynth import core

smoothfps_params = "{rate:{num:60,den:1,abs:true},algo:21,gpuid:0,mask:{area:100},scene:{limits:{m1:1800,m2:3600,scene:5200,zero:100,blocks:45}}}"
## rate后设定目标帧率，num/den的结果(分子分母最好使用整数，计算结果最好也是整数)：当abs:true时指定为具体帧数值，当abs:false时为补帧倍率（vfr视频请使用倍帧来避免报错弹出）
## gpuid用于指定哪张显卡辅助CPU加速，可用数值为 (默认)0/11/12/21。双显卡笔记本在使用外屏时若掉帧则尝试改为21

super_params = "{pel:2,gpu:1,scale:{up:2,down:4}}"
analyse_params = "{block:{w:32,h:32,overlap:2},main:{levels:4,search:{type:4,distance:-8,coarse:{type:4,distance:-5,bad:{range:0}}},penalty:{plevel:1.3,pzero:110,pnbour:75}},refine:[{thsad:200,search:{type:4,distance:2}}]}"

if container_fps > 32 :
	raise Warning("源帧率超过限制的范围，已临时禁用该脚本。")

def interpolate(clip) :
	clip_f = clip.resize.Bilinear(format=vs.YUV420P8)

	super = core.svp1.Super(clip_f, super_params)
	vectors = core.svp1.Analyse(super["clip"], super["data"], clip_f, analyse_params)
	smooth = core.svp2.SmoothFps(clip, super["clip"], super["data"], vectors["clip"], vectors["data"], smoothfps_params, src=clip_f, fps=container_fps)
	assume = core.std.AssumeFPS(smooth, fpsnum=smooth.fps_num, fpsden=smooth.fps_den)

	return assume

interpolate(video_in).set_output()
