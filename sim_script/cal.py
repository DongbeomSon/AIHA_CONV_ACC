import math
import copy

clk500 = False
clk = 0.6 if clk500 else 1
is_VGG = False
if(is_VGG):
    w = [226, 226, 114, 114, 58, 58, 58, 30, 30, 30, 16, 16, 16]
    ci = [64, 64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512]
    co = [64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512, 512]
    l = [2, 2, 3, 3, 3]
else:
    w = [58, 30, 16, 9]
    ci = [64, 128, 256, 512]
    co = [64, 128, 256, 512]
    l = [3, 4, 6, 3]

ops = []
cycles = []

total_ops = 0
total_cycles = 0
overhead = 3

x = 28
r = 14
s = 128

pr = True
lw = not is_VGG
kk = 3
m_c = True

o_rate = 0.85
i_rate = 0.85

input_band_width = clk*64*i_rate
weight_band_width = clk*64*i_rate
output_band_width = clk*64*o_rate

max = 0
for i in range(len(w)):
    # layer = l[i] if lw else 1
    layer = l[i] if lw else 1
    o_t = layer * ((w[i]-2)*(w[i]-2)*ci[i]*co[i]*kk*kk)
    c_t = layer * ((x+overhead)*ci[i]*co[i]*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r)) if not m_c else layer * ((x+overhead)*ci[i]*math.ceil(co[i]/s)*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r))
    c_t = c_t if not pr else c_t + math.ceil(w[i]/x)*math.ceil((w[i]-2)/math.floor(r))*ci[i]*math.ceil(co[i]/s) + x+2 + 3*x + 6   
    ops.append(o_t)
    cycles.append(c_t)
    total_ops += o_t
    total_cycles += c_t
    
    idle_op = 3*3*s*r/clk
    t_max = total_ops/total_cycles/clk
    e_t_max = idle_op/t_max - 1
    ut = t_max/idle_op
    e_util = t_max/idle_op


i_util = r+2
i_util = i_util/input_band_width
w_util = (s*kk*kk)/(x+overhead)
w_util = w_util/weight_band_width
o_util = (4*r*x*s)/((x+overhead)*min(ci))
o_util = o_util/output_band_width



if(t_max >= max):
    if(t_max > max):
        print("maximum ops")
        print('op_x : {x}  op_r : {r}  op_s :{s}'.format(x=x, r=r, s=s))
        max = t_max
        op_oh = e_t_max
        print('avg op/cycle : {max}'.format(max=int(max)))
        print('overhead : {max:.2%}'.format(max=op_oh))
        o_ops = copy.deepcopy(ops)
        o_cycles = copy.deepcopy(cycles)
        print('operations : {o_ops}'.format(o_ops=o_ops))
        print('cycles : {o_cycles}'.format(o_cycles=o_cycles))
        idle_op = 3*3*s*r
        d = [float('{0:.2f}'.format(a/b)) for a,b in zip(o_ops, o_cycles)]
        d2 = ['{0:.2%}'.format(x/idle_op) for x in d]
        print('Layer Utilization : {0}'.format(d2))
        print('Utilization : {0:.2%}'.format(e_util))
        print('i_util : {0:.2%} w_util : {1:.2%} o_util {2:.2%}'.format(i_util, w_util,  o_util))
        print('[{0:.2%}, {1:.2%}, {2:.2%}]'.format(i_util, w_util,  o_util))
        print('{}')
        op_x = x
        op_r = r
        op_s = s
        # op_mr = m_r
        # op_neck = neck
        # print('op_r : {x}  bottle_neck : {r}'.format(x=op_mr, r=op_neck))