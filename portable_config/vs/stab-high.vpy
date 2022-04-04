## mod from HAvsFunc
## 抗源抖动脚本（此类问题常见于胶片转录作品），CPU开销很大

import vapoursynth as vs
core = vs.core
input = video_in

cut1 = input
threshold = 255 << (cut1.format.bits_per_sample - 8)
temp = cut1.focus2.TemporalSoften2(7, threshold, threshold, 25, 2)
inter = core.std.Interleave([core.rgvs.Repair(temp, cut1.focus2.TemporalSoften2(1, threshold, threshold, 25, 2), mode=[1]), cut1])
mdata = inter.mv.DepanEstimate(trust=0, dxmax=4, dymax=4)
cut2 = inter.mv.DepanCompensate(data=mdata, offset=-1, mirror=15)
output = cut2[::2]

output.set_output()
