### Neo f3kdb 动态颗粒去色带

import vapoursynth as vs
from vapoursynth import core

input = video_in
color_lv = input.get_frame(0).props._ColorRange

plug = None
dectect_br = 15
bandY_rth = 48
bandC_rth = 48
grainY = 48
grainC = 48
spl_mode = 4
grain_dy = True
channel_par = True
depth_fin = 8
# 预转换色深插件 "zimg" 或 "fmtc" 或 None
# 色带检测范围
# 色带检测阈值 —— Y平面
# 色带检测阈值 —— CbCr平面
# 最后阶段添加的颗粒数 —— Y平面
# 最后阶段添加的颗粒数 —— CbCr平面
# 采样模式 1=Column // 2=Square // 3=Row // 4=Average(1&3)
# 是否使用动态颗粒
# 是否并行处理各个平面
# 最终输出的色深 8 --- 16 （应该等于你的显示设备输出位深）

if plug == "zimg" :
	cut1 = input.resize.Bilinear(format=vs.YUV444P16)
if plug == "fmtc" :
	cut1 = core.fmtc.bitdepth(clip=input, bits=16)
if plug is None :
	cut1 = input

output = core.neo_f3kdb.Deband(clip=cut1, range=dectect_br, y=bandY_rth, cb=bandC_rth, cr=bandC_rth, grainy=grainY, grainc=grainC, sample_mode=spl_mode, dynamic_grain=grain_dy, mt=channel_par, keep_tv_range=True if color_lv==1 else False, output_depth=depth_fin)

output.set_output()
