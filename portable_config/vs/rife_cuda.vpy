### rife v4 补帧，性能要求较高，N卡专用

import vapoursynth as vs
from vapoursynth import core
import math
from vsmlrt import RIFE, RIFEModel, Backend

input = video_in
colorlv = input.get_frame(0).props._ColorRange
fmt_fin = input.format.id

L_FHD = False
FPS_num = 2
SCALE_model = 1
GPU = 0
GPU_t = 2
WS_size = 128
# 是否对大于1080P的源进行补帧
# 补帧倍率（整数）
# 预缩放光流模型 <0.25|0.5|1> （以质量交换性能）
# 使用的显卡序号，0为排序一号
# 使用的显卡线程数
# 约束显存大小

if container_fps > 32 :
	raise Exception("源帧率超过限制的范围，已临时禁用该脚本。")
if not L_FHD and (input.width * input.height > 2073600) :
	raise Exception("源分辨率超过限制的范围，已临时禁用该脚本。")

tile_size = 32 / SCALE_model
w_tmp = math.ceil(input.width / tile_size) * tile_size - input.width
h_tmp = math.ceil(input.height / tile_size) * tile_size - input.height

cut0 = core.misc.SCDetect(clip=input, threshold=0.2)

cut1 = cut0.resize.Bilinear(format=vs.RGBS, matrix_in_s="709")
cut2 = cut1.std.AddBorders(right=w_tmp, bottom=h_tmp)
cut3 = RIFE(clip=cut2, multi=FPS_num, scale=SCALE_model, model=RIFEModel.v4_6, backend=Backend.TRT(fp16=True, device_id=GPU, workspace=WS_size, use_cuda_graph=True, num_streams=GPU_t))
fin = cut3.std.Crop(right=w_tmp, bottom=h_tmp)

output = fin.resize.Bilinear(format=fmt_fin, matrix_s="709", range=1 if colorlv==0 else None)
output.set_output()
