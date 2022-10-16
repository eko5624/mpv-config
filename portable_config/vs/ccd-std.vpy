### 降低彩噪，开销中等
### port from jvsfunc (7bed2d843fd513505b209470fd82c71ef8bcc0dd)

import vapoursynth as vs
from vapoursynth import core

input = video_in
colorlv = input.get_frame(0).props._ColorRange
pix_fmt = input.format.id

denoise_lv = 30
fmt_out = vs.YUV444P8
# 彩噪阈值，越高的值降噪效果越明显（涂抹越重）
# 输出格式 vs.YUV420P8（最优化性能） // pix_fmt（同源） // vs.YUV444P16（最小化精度损失）

def ccd(src: vs.VideoNode, threshold: float = 4) -> vs.VideoNode:
    """
    Yet another Camcorder Color Denoise implementation.
    """

    if src.format.color_family != vs.RGB or src.format.sample_type != vs.FLOAT:
        raise ValueError('ccd: only RGBS format is supported')

    thr = threshold**2/195075.0
    r = core.std.ShufflePlanes([src, src, src], [0, 0, 0], vs.RGB)
    g = core.std.ShufflePlanes([src, src, src], [1, 1, 1], vs.RGB)
    b = core.std.ShufflePlanes([src, src, src], [2, 2, 2], vs.RGB)

    ex_ccd = core.akarin.Expr([r, g, b, src],
                              'x[-12,-12] x - 2 pow y[-12,-12] y - 2 pow z[-12,-12] z - 2 pow + + A! '
                              'x[-4,-12] x - 2 pow y[-4,-12] y - 2 pow z[-4,-12] z - 2 pow + + B! '
                              'x[4,-12] x - 2 pow y[4,-12] y - 2 pow z[4,-12] z - 2 pow + + C! '
                              'x[12,-12] x - 2 pow y[12,-12] y - 2 pow z[12,-12] z - 2 pow + + D! '
                              'x[-12,-4] x - 2 pow y[-12,-4] y - 2 pow z[-12,-4] z - 2 pow + + E! '
                              'x[-4,-4] x - 2 pow y[-4,-4] y - 2 pow z[-4,-4] z - 2 pow + + F! '
                              'x[4,-4] x - 2 pow y[4,-4] y - 2 pow z[4,-4] z - 2 pow + + G! '
                              'x[12,-4] x - 2 pow y[12,-4] y - 2 pow z[12,-4] z - 2 pow + + H! '
                              'x[-12,4] x - 2 pow y[-12,4] y - 2 pow z[-12,4] z - 2 pow + + I! '
                              'x[-4,4] x - 2 pow y[-4,4] y - 2 pow z[-4,4] z - 2 pow + + J! '
                              'x[4,4] x - 2 pow y[4,4] y - 2 pow z[4,4] z - 2 pow + + K! '
                              'x[12,4] x - 2 pow y[12,4] y - 2 pow z[12,4] z - 2 pow + + L! '
                              'x[-12,12] x - 2 pow y[-12,12] y - 2 pow z[-12,12] z - 2 pow + + M! '
                              'x[-4,12] x - 2 pow y[-4,12] y - 2 pow z[-4,12] z - 2 pow + + N! '
                              'x[4,12] x - 2 pow y[4,12] y - 2 pow z[4,12] z - 2 pow + + O! '
                              'x[12,12] x - 2 pow y[12,12] y - 2 pow z[12,12] z - 2 pow + + P! '
                              f'A@ {thr} < 1 0 ? B@ {thr} < 1 0 ? C@ {thr} < 1 0 ? D@ {thr} < 1 0 ? '
                              f'E@ {thr} < 1 0 ? F@ {thr} < 1 0 ? G@ {thr} < 1 0 ? H@ {thr} < 1 0 ? '
                              f'I@ {thr} < 1 0 ? J@ {thr} < 1 0 ? K@ {thr} < 1 0 ? L@ {thr} < 1 0 ? '
                              f'M@ {thr} < 1 0 ? N@ {thr} < 1 0 ? O@ {thr} < 1 0 ? P@ {thr} < 1 0 ? '
                              '+ + + + + + + + + + + + + + + 1 + Q! '
                              f'A@ {thr} < a[-12,-12] 0 ? B@ {thr} < a[-4,-12] 0 ? '
                              f'C@ {thr} < a[4,-12] 0 ? D@ {thr} < a[12,-12] 0 ? '
                              f'E@ {thr} < a[-12,-4] 0 ? F@ {thr} < a[-4,-4] 0 ? '
                              f'G@ {thr} < a[4,-4] 0 ? H@ {thr} < a[12,-4] 0 ? '
                              f'I@ {thr} < a[-12,4] 0 ? J@ {thr} < a[-4,4] 0 ? '
                              f'K@ {thr} < a[4,4] 0 ? L@ {thr} < a[12,4] 0 ? '
                              f'M@ {thr} < a[-12,12] 0 ? N@ {thr} < a[-4,12] 0 ? '
                              f'O@ {thr} < a[4,12] 0 ? P@ {thr} < a[12,12] 0 ? '
                              '+ + + + + + + + + + + + + + + a + Q@ /')

    return ex_ccd

cut = input.resize.Bilinear(format=vs.RGBS, matrix_in_s="709")
fin = ccd(src=cut, threshold=denoise_lv)
output = fin.resize.Bilinear(format=fmt_out, matrix_s="709", range=1 if colorlv==0 else None)

output.set_output()
