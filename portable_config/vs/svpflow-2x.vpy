##中等消耗。默认设置为倍帧，倍帧操作适合动态帧率VFR视频时补帧，不会出现后期大幅度的音画不同步现象

import vapoursynth as vs
core = vs.core
clip = video_in
fps = container_fps if container_fps > 0.1 else 23.976

if clip.format.id == vs.YUV420P8:
    clip8 = clip
elif clip.format.id == vs.YUV420P10:
    clip8 = clip.resize.Point(format=vs.YUV420P8)
else:
    clip = clip.resize.Point(
        format=vs.YUV420P10, dither_type="random")
    clip8 = clip.resize.Point(format=vs.YUV420P8)

super_params = "{pel:2,gpu:1,scale:{up:2,down:4}}"

##此版gpu:1勿修改为0（关闭显卡加速），会造成无法正确10bit输出。如异常使用核显加速，参见下方gpuid的说明

analyse_params = "{block:{w:32,h:16,overlap:2},main:{levels:4,search:{type:4,distance:-8,coarse:{type:2,distance:-5,bad:{range:0}}},penalty:{lambda:10.0,plevel:1.5,pzero:110,pnbour:65}},refine:[{thsad:200,search:{type:4,distance:2}}]}"
smoothfps_params = "{rate:{num:2,den:1,abs:false},algo:21,gpuid:0,mask:{area:100},scene:{mode:0,limits:{m1:1800,m2:3600,scene:5200,zero:100,blocks:45}}}"

##rate后设定目标帧率，num/den的结果(分子分母最好使用整数，计算结果最好也是整数)：当abs:true时指定为具体帧数值，当abs:false时为补帧倍率（vfr视频请使用倍帧来避免报错弹出）
##gpuid用于指定哪张显卡辅助CPU加速，可用数值为 (默认)0/11/12/21。双显卡笔记本在使用外屏时若掉帧则尝试改为21

svps = core.svp1.Super(clip8, super_params)
svpv = core.svp1.Analyse(svps["clip"], svps["data"], clip, analyse_params)
clip = core.svp2.SmoothFps(clip, svps["clip"], svps["data"], svpv["clip"], svpv["data"],
                           smoothfps_params, src=clip, fps=fps)

clip.set_output()
