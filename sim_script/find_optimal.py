import math
import copy
import matplotlib.pyplot as plt
import numpy as np

def mem_util(x, r, s):
    global clk, i_rate, o_rate
    input_band_width = clk*64*i_rate
    weight_band_width = clk*64*i_rate
    output_band_width = clk*64*o_rate
    i_util = r+2
    i_util = i_util/input_band_width
    w_util = (s*kk*kk)/(x+overhead)
    w_util = w_util/weight_band_width
    o_util = (4*r*x*s)/((x+overhead)*min(ci))
    o_util = o_util/output_band_width
    o_list = []
    o_list.append('{0:.2%}'.format(i_util))
    o_list.append('{0:.2%}'.format(w_util))
    o_list.append('{0:.2%}'.format(o_util))
    return o_list

clk500 = True
clk = 0.6 if clk500 else 1
m_c = True
is_VGG = True
#overhead의 영향을 적게 고려할것이면 True
ud_over=False
show_figure=False
pr = False
lw = not is_VGG
pallel = True
overhead=3
if(is_VGG):
    w = [226, 114, 58, 30, 16]
    # ci = [64, 128, 256, 512, 512]
    # co = [64, 128, 256, 512, 512]
    w = [226, 226, 114, 114, 58, 58, 58, 30, 30, 30, 16, 16, 16]
    ci = [64, 64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512]
    co = [64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512, 512]
    l = [2, 2, 3, 3, 3]
else:
    w = [58, 30, 16, 9]
    ci = [64, 128, 256, 512]
    co = [64, 128, 256, 512]
    l = [3, 4, 6, 3]

max = 0
op_x = 0
op_r = 0
op_s = 0
op_mr = 0
op_neck = ""
op_oh = 0
kk=3
o_ops=[]
o_cycles=[]
e_ops=[]
e_cycles=[]
e_x = 0
e_r = 0
e_max=999
e_neck = ""
e_mr = 0
e_oh = 999

o1_ops = []
o1_cycles = []
o2_ops = []
o2_cycles = []

max_r = 300
max_x = 300
max_s = 1145

o_rate = 0.65
i_rate = 0.8

bt_neck = ""

o_max = 0
ox=[]
oy=[]
orr=[]
oxx=[]
oss=[]
ob=[]

o2_max = 0
o2x=[]
o2y=[]
o2rr=[]
o2xx=[]
o2ss=[]
o2b=[]


out = np.zeros((max_s, max_r, max_x))
e_out = np.zeros((max_s, max_r, max_x))

for x in range(1,max_x+1):
    max_s = int(64 * (x+overhead) * clk * i_rate/ (kk*kk))
    for s in range(1, max_s+1 if m_c else 2):
        # bt_neck = "output" if int(64*o_rate*64*(x+overhead)/(4*s*x)) < int(64*i_rate)-2 else "input"
        o_b_neck = int(round(64*o_rate)*64*(x+overhead)/(4*s*x) * clk)
        i_b_neck = int(round((64*i_rate) * clk - 2)) if pallel else int(round((64*i_rate)) * clk -2 - kk*kk*s/(x+overhead))
        m_r = min(o_b_neck,i_b_neck)
        if(m_r == 0):
            break
        # print('m_r : {0}'.format(m_r))
        for r in range(1, m_r+1):
            t_max = 0
            e_t_max = 0
            # op_list_temp=[]
            total_ops=0
            total_cycles=0
            ops = []
            cycles = []
            idle_op = 3*3*s*r
            for i in range(len(w)):
                # layer = l[i] if lw else 1
                # o_t = layer * ((w[i]-2)*(w[i]-2)*c[i]*c[i]*kk*kk)
                # c_t = layer * ((x+overhead)*c[i]*c[i]*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r)) if not m_c else layer * ((x+overhead)*c[i]*math.ceil(c[i]/s)*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r))
                # c_t = c_t if not pr else c_t + math.ceil(w[i]/x)*math.ceil((w[i]-2)/math.floor(r))*c[i]*math.ceil(c[i]/s) + x+2 + 3*x + 6
                # layer = l[i] if lw else 1
                layer = l[i] if lw else 1
                o_t = layer * ((w[i]-2)*(w[i]-2)*ci[i]*co[i]*kk*kk)
                c_t = layer * ((x+overhead)*ci[i]*co[i]*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r)) if not m_c else layer * ((x+overhead)*ci[i]*math.ceil(co[i]/s)*math.ceil(w[i]/x)*math.ceil((w[i]-2)/r))
                c_t = c_t if not pr else c_t + math.ceil(w[i]/x)*math.ceil((w[i]-2)/math.floor(r))*ci[i]*math.ceil(co[i]/s) + x+2 + 3*x + 6
                ops.append(o_t)
                cycles.append(c_t)
                total_ops += o_t
                total_cycles += c_t
                
            
            total_cycles = total_cycles * clk
            idle_op = idle_op / clk
            
            t_max = total_ops/total_cycles
            e_t_max = idle_op/t_max - 1
            out[s-1, r-1,x-1] = t_max
            e_out[s-1, r-1,x-1] = e_t_max
            util = t_max/idle_op
            
            # e_t_max = e_t_max + int(ud_over)
            ot_max = t_max/e_t_max
            
            o2_t_max = t_max/(e_t_max + 1)
            
            if(r == m_r):
                neck = "output" if o_b_neck < i_b_neck else "input"
            else:
                neck = "not bounded"
            if(t_max >= max):
                if(t_max > max):
                    print("maximum ops")
                    print('op_x : {x}  op_r : {r}  op_s :{s}'.format(x=x, r=r, s=s))
                    max = t_max
                    op_oh = e_t_max
                    print('avg op/cycle : {max}'.format(max=max))
                    print('overhead : {max}'.format(max=op_oh))
                    o_ops = copy.deepcopy(ops)
                    o_cycles = copy.deepcopy(cycles)
                    print('operations : {o_ops}'.format(o_ops=o_ops))
                    print('cycles : {o_cycles}'.format(o_cycles=o_cycles))
                    op_x = x
                    op_r = r
                    op_s = s
                    op_mr = m_r
                    op_neck = neck
                    op_util = util
                    print('op_r : {x}  bottle_neck : {r}'.format(x=op_mr, r=op_neck))

                if(e_t_max < e_oh):
                    print("minimum overhead")
                    print('op_x : {x}  op_r : {r}  op_s :{s}'.format(x=x, r=r, s=s))
                    e_max = t_max
                    e_oh = e_t_max
                    print("avg op/cycle : {0}".format(e_max))
                    print('overhead : {max}'.format(max=e_oh))
                    e_ops = copy.deepcopy(ops)
                    e_cycles = copy.deepcopy(cycles)
                    print('operations : {o_ops}'.format(o_ops=e_ops))
                    print('cycles : {o_cycles}'.format(o_cycles=e_cycles))
                    e_x = x
                    e_r = r
                    e_s = s
                    e_mr = m_r
                    e_neck = neck
                    e_util = util
                    
                print('op_r : {x}  bottle_neck : {r}'.format(x=e_mr, r=e_neck))
               
            if(o_max < ot_max):
                print(t_max)
                print(r)
                print(x)
                print(s)
                o_max = ot_max
                ox.append(e_t_max)
                oy.append(t_max)
                orr.append(r)
                oxx.append(x)
                oss.append(s)
                ob.append(neck)
                o1_ops = copy.deepcopy(ops)
                o1_cycles = copy.deepcopy(cycles)
                o1_util = util

            if(o2_max < o2_t_max):
                print(t_max)
                print(r)
                print(x)
                print(s)
                o2_max = o2_t_max
                o2x.append(e_t_max)
                o2y.append(t_max)
                o2rr.append(r)
                o2xx.append(x)
                o2ss.append(s)
                o2b.append(neck)
                o2_ops = copy.deepcopy(ops)
                o2_cycles = copy.deepcopy(cycles)
                o2_util = util
                
            # if(r == 42 and t_max > e_max):
            #     print('e_op_x : {x}  e_op_r : {r}'.format(x=x, r=r))
            #     e_max = t_max
            #     print('eff op/cycle : {max}'.format(max=e_max))
            #     e_o_ops = copy.deepcopy(ops)
            #     e_o_cycles = copy.deepcopy(cycles)
            #     print('operations : {o_ops}'.format(o_ops=e_o_ops))
            #     print('cycles : {o_cycles}'.format(o_cycles=e_o_cycles))
            #     e_op_x = x
            #     e_op_r = r
                
            # if(temp_effcost > effpcost_max):
            #     print('ef_x : {x}  ef_r : {r}'.format(x=x, r=r))
            #     effpcost_max = temp_effcost
            #     print('avg op/cycle*pe : {max}'.format(max=effpcost_max))
            #     ef_x = x
            #     ef_r = r

# print("final result")

# print('op_x : {x}  op_r : {r}  op_s : {s}'.format(x=op_x, r=op_r, s=op_s))
# print('max_r : {x}  bottle_neck : {r}'.format(x=op_mr, r=op_neck))
# print('avg op/cycle : {max}'.format(max=max))
# print('overhead : {max}'.format(max=op_oh))
# print('operations : {o_ops}'.format(o_ops=o_ops))
# print('cycles : {o_cycles}'.format(o_cycles=o_cycles))
# d = [float('{0:.2f}'.format(a/b)) for a,b in zip(o_ops, o_cycles)]
# print('op/cyc : {x}'.format(x=d))

out[out==0] = np.nan
x=np.arange(1,max_x+1,1)
for y in range(op_mr):
    if(y == op_mr-1):
        plt.scatter(x, out[op_s-1][y], s=1, label='r={0}'.format(y+1), marker='o')
    elif(y == 0):
        plt.scatter(x, out[op_s-1][y], s=1, label='r=1')
    #elif(y == 41):
        # plt.scatter(x, out[y], marker='x', label='r=42')
    else:
        plt.scatter(x, out[op_s-1][y], s=1)
plt.scatter(x, out[op_s-1][op_r-1], color='black', marker='x', label='r={op_r}'.format(op_r=op_r))
plt.xlabel('Tile_length')
plt.ylabel('OPs/cycle')
plt.title('set # : {0}'.format(op_s))
plt.legend()

print()
print("-----------------------------------------")
print()

print("Fastest result")
print('e_x , e_r, e_s [{x}, {r}, {s}]'.format(x=op_x, r=op_r, s=op_s))
print('maxe_r : {x}  bottle_neck : {r}'.format(x=op_mr, r=op_neck))
print('avg op/cycle : {max}'.format(max=int(max)))
print('overhead : {max:.2%}'.format(max=op_oh))
print('operations : {o_ops}'.format(o_ops=o_ops))
print('cycles : {o_cycles}'.format(o_cycles=o_cycles))
d = [float('{0:.2f}'.format(a/b)) for a,b in zip(o_ops, o_cycles)]
print('op/cyc : {x}'.format(x=d))
idle_op = 3*3*op_s*op_r
d2 = ['{0:.2%}'.format(x/idle_op) for x in d]
print('Layer Utilization : {0}'.format(d2))
print('Utilization : {0:.2%}'.format(op_util))
d3 = mem_util(op_x, op_r, op_s)
print(d3)


print()
print("-----------------------------------------")
print()

print("Fastest result2")
print('e_x , e_r, e_s [{x}, {r}, {s}]'.format(x=e_x, r=e_r, s=e_s))
print('maxe_r : {x}  bottle_neck : {r}'.format(x=e_mr, r=e_neck))
print('avg op/cycle : {max}'.format(max=int(e_max)))
print('overhead : {max:.2%}'.format(max=e_oh))
print('operations : {o_ops}'.format(o_ops=e_ops))
print('cycles : {o_cycles}'.format(o_cycles=e_cycles))
d = [float('{0:.2f}'.format(a/b)) for a,b in zip(e_ops, e_cycles)]
print('op/cyc : {x}'.format(x=d))
idle_op = 3*3*e_s*e_r
d2 = ['{0:.2%}'.format(x/idle_op) for x in d]
print('Layer Utilization : {0}'.format(d2))
print('Utilization : {0:.2%}'.format(e_util))
d3 = mem_util(e_x, e_r, e_s)
print(d3)


plt.figure()
e_out[e_out==0] = np.nan
e_out[e_out>1]=np.nan
x=np.arange(1,max_x+1,1)
for y in range(e_mr):
    if(y == e_mr-1):
        plt.scatter(x, e_out[e_s-1][y], s=1, label='r={0}'.format(y+1), marker='o')
    elif(y == 0):
        plt.scatter(x, e_out[e_s-1][y], s=1, label='r=1')
    #elif(y == 41):
        # plt.scatter(x, out[y], marker='x', label='r=42')
    else:
        plt.scatter(x, e_out[e_s-1][y], s=1)
plt.scatter(x, e_out[e_s-1][e_r-1], color='black', marker='x', label='r={op_r}'.format(op_r=e_r))
plt.xlabel('Tile_length')
plt.ylabel('overhead')
plt.title('overhead/set # : {0}'.format(e_s))
plt.legend()


print()
print("-----------------------------------------")
print()

print("Optimal result")
print("overhead : {0:.2%}  OPs/cycle : {1}".format(ox[-1],int(oy[-1])))
print("config // [{0}, {1}, {2}]".format(oxx[-1],orr[-1],oss[-1]))
print("bottle_neck : {0}".format(ob[-2]))
d = [float('{0:.2f}'.format(a/b)) for a,b in zip(o1_ops, o1_cycles)]
idle_op = 3*3*orr[-1]*oss[-1]
d2 = ['{0:.2%}'.format(x/idle_op) for x in d]
print('Layer Utilization : {0}'.format(d2))
print('Utilization : {0:.2%}'.format(o1_util))
d3 = mem_util(oxx[-1], orr[-1], oss[-1])
print(d3)

plt.figure()
plt.scatter(ox,oy, s=2)
plt.scatter(ox[-1],oy[-1], marker='x')
plt.xlabel('overhead')
plt.ylabel('OPs/cycle')
plt.title('(estimated overhead as +1)' if ud_over else '')

print()
print("-----------------------------------------")
print()

print("Optimal_2_ result [Overhead+1]")
print("overhead : {0:.2%}  OPs/cycle : {1}".format(o2x[-1],int(o2y[-1])))
print("config // [{0}, {1}, {2}]".format(o2xx[-1],o2rr[-1],o2ss[-1]))
print("bottle_neck : {0}".format(o2b[-2]))
d = [float('{0:.2f}'.format(a/b)) for a,b in zip(o2_ops, o2_cycles)]
idle_op = 3*3*o2rr[-1]*o2ss[-1]
d2 = ['{0:.2%}'.format(x/idle_op) for x in d]
print('Layer Utilization : {0}'.format(d2))
print('Utilization : {0:.2%}'.format(o2_util))
d3 = mem_util(o2xx[-1], o2rr[-1], o2ss[-1])
print(d3)

plt.figure()
plt.scatter(o2x,o2y, s=2)
plt.scatter(o2x[-1],o2y[-1], marker='x')
plt.xlabel('1/utilization')
plt.ylabel('OPs/cycle')
plt.title('(estimated overhead as +1)' if ud_over else '')

if(show_figure):
    plt.show()


# print('e_op_x : {x}  e_op_r : {r}'.format(x=e_op_x, r=e_op_r))
# print('eff op/cycle : {max:.2f}'.format(max=e_max))
# print('operations : {o_ops}'.format(o_ops=e_o_ops))
# print('cycles : {o_cycles}'.format(o_cycles=e_o_cycles))
# d = [float('{0:.2f}'.format(a/b)) for a,b in zip(e_o_ops, e_o_cycles)]
# print('op/cyc : {x}'.format(x=d))
# print('ef_x : {x}  ef_r : {r}'.format(x=ef_x, r=ef_r))
# print('avg op/cycle*pe : {max}'.format(max=effpcost_max))