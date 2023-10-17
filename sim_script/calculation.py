import math
import copy
import matplotlib.pyplot as plt
import numpy as np

def bench_mark(pe_util, o_util):
    return pe_util*o_util*o_util


def cal_mem_usage(i_usage, o_usage):
    return i_usage * o_usage


plot_pe_util = []
plot_o_util = []
plot_config = []

plot_all_pe_util = []
plot_all_o_util = []


def layer_calculation(network: tuple, configuration: tuple) -> tuple:
    global k, ov
    global clk, i_rate, o_rate
    global ic_oc_block_mapping
    
    
    if(ic_oc_block_mapping):
        t, r, sp = configuration
    else:
        sp = 1
        t, r, s, p = configuration
    ow, ci, co, l = network

#    print('calcuation : {0}'.format(configuration))
    #band_width calcuation
    
    input_band_width = INPUT_IF_RATE*MEM_IF_CLK*i_rate  # MB/s
#    weight_band_width = clk*64*i_rate
    output_band_width = OUTPUT_IF_RATE*MEM_IF_CLK*o_rate

    
    layer_cycle = []
    layer_pe_util = []
    layer_pe_overhead = []
    layer_i_usage = []
    layer_o_usage = []
    layer_sp_config = []
    layer_o_util = []
    
    total_cycles = 0

    for i in range(len(ow)):
        layer = l[i] if l is not None else 1
        r_op = layer*ow[i]*ow[i]*ci[i]*co[i]*k*k
        
        if(ic_oc_block_mapping):
            s = int(sp/4)
            p = 4
            max_bench = 0
            max_s = 0
            max_p = 0
            while s <= sp:
                i_usage = clk*(r+2)*p + clk*(s*k*k*p)/(t+ov)
                i_usage = i_usage/input_band_width
                
                o_usage = clk*(OUTPUT_BYTE_SIZE*r*t*s)/((t+ov)*math.ceil(ci[i]/p))
                o_usage = o_usage/output_band_width
                stall_rate = max(i_usage, o_usage)
                stall_rate = stall_rate if stall_rate > 1 else 1
                
                i_usage = i_usage/stall_rate
                o_usage = o_usage/stall_rate
                
                # i_usage = 1 if i_usage > 1 else i_usage
                # o_usage = 1 if o_usage > 1 else o_usage
                
                mem_usage = cal_mem_usage(i_usage, o_usage)
                
                cycle = math.ceil(layer*((t+ov)*math.ceil(ci[i]/p)*math.ceil(co[i]/s)*math.ceil(ow[i]/t)*math.ceil(ow[i]/r))*stall_rate)
                ops = r_op/cycle*clk
                num_pe = k*s*r*p
                idle_ops = k*num_pe*clk
                idle_cycle = r_op/(k*num_pe)
                pe_util = ops/idle_ops
                pe_overhead = (cycle-idle_cycle)/(idle_cycle)
                
                
                total_output_size = OUTPUT_BYTE_SIZE*t*math.ceil(ow[i]/t)*r*math.ceil(ow[i]/r)*s*math.ceil(co[i]/s)
                ideal_output_size = OUTPUT_BYTE_SIZE*ow[i]*ow[i]*co[i]
                o_util_ratio = ideal_output_size/total_output_size
                o_util = o_usage*o_util_ratio
                
                # bench = pe_util*mem_usage
                # bench = pe_util/cycle
                # bench = pe_util*o_usage
                # bench = pe_util*o_util*o_util
                bench = bench_mark(pe_util, o_util)
                
                if(bench >= max_bench):
                    max_bench = bench
                    max_s = s
                    max_p = p
                s *= 2
                p = int(p/2)
            
            s = max_s
            p = max_p
            
        i_usage = clk*(r+2)*p + clk*(s*k*k*p)/(t+ov)
        i_usage = i_usage/input_band_width
        o_usage = clk*(OUTPUT_BYTE_SIZE*r*t*s)/((t+ov)*math.ceil(ci[i]/p))
        o_usage = o_usage/output_band_width       

        
        stall_rate = max(i_usage, o_usage)
        stall_rate = stall_rate if stall_rate > 1 else 1

        i_usage = i_usage/stall_rate
        o_usage = o_usage/stall_rate
        
        total_output_size = OUTPUT_BYTE_SIZE*t*math.ceil(ow[i]/t)*r*math.ceil(ow[i]/r)*s*math.ceil(co[i]/s)
        ideal_output_size = OUTPUT_BYTE_SIZE*ow[i]*ow[i]*co[i]
        o_util_ratio = ideal_output_size/total_output_size
        o_util = o_usage*o_util_ratio

        # i_usage = 1 if i_usage > 1 else i_usage
        # o_usage = 1 if o_usage > 1 else o_usage

        layer_i_usage.append(i_usage)
        layer_o_usage.append(o_usage)
        layer_o_util.append(o_util)
        
        cycle = math.ceil(layer*((t+ov)*math.ceil(ci[i]/p)*math.ceil(co[i]/s)*math.ceil(ow[i]/t)*math.ceil(ow[i]/r))*stall_rate)
        ops = r_op/cycle*clk
        num_pe = k*s*r*p
        idle_ops = k*num_pe*clk
        idle_cycle = r_op/(k*num_pe)
        pe_util = ops/idle_ops
        pe_overhead = (cycle-idle_cycle)/(idle_cycle)
        
        layer_cycle.append(cycle)
        layer_pe_util.append(pe_util)
        layer_pe_overhead.append(pe_overhead)
        layer_sp_config.append((s,p))
        total_cycles += cycle
    # print(temp)
    
    i_usage = 0
    o_usage = 0
    o_util = 0
    pe_util = 0
    layer_cycle_portion = []
    pe_overhead = 0
    for i in range(len(layer_cycle)):
        layer_portion = layer_cycle[i]/total_cycles
        layer_cycle_portion.append('{0:.2%}'.format(layer_portion))
        i_usage += layer_portion*layer_i_usage[i]
        o_usage += layer_portion*layer_o_usage[i]
        o_util += layer_portion*layer_o_util[i]
        pe_util += layer_portion*layer_pe_util[i]
        # pe_overhead += layer_portion*layer_pe_overhead[i]
    pe_overhead = 1/pe_util-1
    num_pe = k*r*s*p
    
    total_info = (total_cycles, num_pe , pe_util, pe_overhead, i_usage, o_usage, o_util)
    layer_info = (layer_cycle_portion, layer_pe_util, layer_pe_overhead, layer_i_usage, layer_o_usage, layer_o_util, layer_sp_config)
    
    return (total_info, layer_info)


def explore_design_space(network: tuple) -> tuple:
    global oc_parallelize, ic_parallelize, ic_oc_block_mapping
    ow, ci, co, l = network
    # print(ow)
    design_space_list = []

    max_mem_usage = 0
    max_bench = 0
    max_pe_overhead_ratio = 0
    max_pe_num = -1
    
    # optimal_config={}
    # optimal_config_total_info={}
    # optimal_config_layer_info={}

    
#    for t in range (1, max(ow)+1):
    for t in range (t_step, max(ow)+1, t_step):
        print('calcuation {0}'.format(t))
        # for r in range (1, max(ow)+1):
        for r in range (r_step, max(ow)+1, r_step):
            s = 4
            # for s in range (1, max(co)+1 if oc_parallelize else 2):
            while s <= (max(co)*max(ci) if ic_oc_block_mapping else max(co)):
                p = 1
                #for p in range (1, max(ci)+1 if ic_parallelize else 2):
                while p <= (max(ci) if not ic_oc_block_mapping else 1):
                    
                    config = (t,r,s,p) if not ic_oc_block_mapping else (t, r, s*p)
                    
                    # design_space_list.append(tup)
                    # print(tup)
                    
                    # print('exploring space : {0}'.format(config))
                    total_info, layer_info = layer_calculation(network, config)
                    total_cycles, num_pe, pe_util, pe_overhead, i_usage, o_usage, o_util = total_info
                    
                    plot_all_pe_util.append(pe_util)
                    plot_all_o_util.append(o_util)
                    
                    mem_usage = cal_mem_usage(i_usage, o_usage)
                    bench = bench_mark(pe_util=pe_util,o_util=o_util)
                    
                    if(bench > max_bench):
                        max_bench = bench
                        optimal_config = config
                        optimal_config_total_info = total_info
                        optimal_config_layer_info = layer_info
                        
                        plot_pe_util.append(pe_util)
                        plot_o_util.append(o_util)
                        plot_config.append(config)
                        
                        print(config)
                        
                    
                    if (fast_ch_travel):
                        p = p*2
                    else:
                        p = p+2 if p <= 128 else p*2
                    

                if (fast_ch_travel):
                    s = s*2
                else:
                    s = s+4
        # print(config)
        
                    
    return (optimal_config, optimal_config_total_info, optimal_config_layer_info)
        
        
def network_list() -> dict:
    
    net_dict = {}
    #VGG
    w = [224, 224, 112, 112, 56, 56, 56, 28, 28, 28, 14, 14, 14]
    ci = [64, 64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512]
    co = [64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512, 512]
    l = None
    VGG16=(w,ci,co,l)
    net_dict['VGG16']=VGG16

    #Resnet50
    w = [56, 28, 14, 7]
    ci = [64, 128, 256, 512]
    co = [64, 128, 256, 512]
    l = [3, 4, 6, 3]
    Resnet50=(w, ci, co, l)
    net_dict['Resnet50']=Resnet50
    
    #VGG16+Resnet50
    w = [224, 224, 112, 112, 56, 56, 56, 28, 28, 28, 14, 14, 14, 56, 28, 14, 7]
    ci = [64, 64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512, 64, 128, 256, 512]
    co = [64, 128, 128, 256, 256, 256, 512, 512, 512, 512, 512, 512, 512, 64, 128, 256, 512]
    l = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 6, 3]
    VGG16_Resnet50=(w, ci, co, l)
    net_dict['VGG16+Resnet50']=VGG16_Resnet50
    
    return net_dict


def get_options(calculation_mode) -> dict:
    options={}
    if not calculation_mode:
        # options['VGG16+Resnet50, clk=300, ov=3'] = {'net_tag':'VGG16+Resnet50', 'clk':300, 'ov':3}
        options['VGG16, clk=300, ov=3'] = {'net_tag':'VGG16', 'clk':300, 'ov':3}
        # options['Resnet50, clk=300, ov=3'] = {'net_tag':'Resnet50', 'clk':300, 'ov':3}

        # options['VGG16, clk=300, ov=0'] = {'net_tag':'VGG16', 'clk':300, 'ov':0}
        # options['Resnet50, clk=300, ov=0'] = {'net_tag':'Resnet50', 'clk':300, 'ov':0}
    
        # options['VGG16, clk=500, ov=3'] = {'net_tag':'VGG16', 'clk':500, 'ov':3}
        # options['Resnet50, clk=500, ov=3'] = {'net_tag':'Resnet50', 'clk':500, 'ov':3}
        
        # options['VGG16, clk=500, ov=0'] = {'net_tag':'VGG16', 'clk':500, 'ov':0}
        # options['Resnet50, clk=500, ov=0'] = {'net_tag':'Resnet50', 'clk':500, 'ov':0}
    else:
        options['calcuation_only'] = {'net_tag':'VGG16', 'clk':300, 'ov':3}


    return options

#set hyperparameter
ic_parallelize = True
oc_parallelize = True
ic_oc_block_mapping = True

fast_ch_travel = True # explore channel demension to the power of 2.
t_step=7
r_step=7


ov = None
clk = None #MHz
MEM_IF_CLK = 300 #MHz
IF_RATE = 64
INPUT_IF_RATE = IF_RATE #Byte/cycle
OUTPUT_IF_RATE = IF_RATE

OUTPUT_BYTE_SIZE = 4

k = 3
i_rate=0.45
o_rate=0.45




#calculation only
calculation_mode = False

cal_config = (28, 14, 128) #t, r, sp

#main function
net_dict = network_list()
print('gend net')
#net_tag_list = ['VGG16', 'Resnet50', 'VGG16+Resnet50']
net_tag_list = ['VGG16', 'Resnet50']
#net = net_dict[net_tag]
# design_space = generate_design_space(net)
opt_dict = {}
options = get_options(calculation_mode) # return dict[key] = {'net_tag', 'clk', 'ov'}
print(options)

for key in options:
    #opt_config, opt_total_info, opt_layer_info = explore_design_space(net_dict[key])
    print(key)
    if not calculation_mode:
        net_tag = options[key]['net_tag']
        clk = options[key]['clk']
        ov = options[key]['ov']
        opt_dict[key] = explore_design_space(net_dict[net_tag])
    else:
        net_tag = options[key]['net_tag']
        clk = options[key]['clk']
        ov = options[key]['ov']
        
        total_info, total_layer_info = layer_calculation(net_dict[net_tag], cal_config)
        opt_dict[key] = (cal_config, total_info, total_layer_info)
        

# opt_config, opt_total_info, opt_layer_info = find_optimal_configuration(net, design_space)

print('Network : {0}'.format(net_tag))

f = open("output.csv", "w")


#print outputs
for keys in opt_dict:
    print()
    print('============== CASE : {0} ============='.format(keys))
    opt_config, opt_total_info, opt_layer_info = opt_dict[keys]
    #for key in ['mem_usage', 'util', 'overhead']:
    # for key in ['util']:
    print('------Target_network------')
    s = 'configuration [t, r, s, p] : {0}' if not ic_oc_block_mapping else 'configuration [t, r, s*p] : {0}'
    print(s.format(opt_config))
    total_cycles, num_pe, pe_util, pe_overhead, i_usage, o_usage, o_util = opt_total_info
    print('total_cycle : {0}'.format(total_cycles))
    print('# of PE : {0}'.format(num_pe))
    print('pe_util : {0:.2%}'.format(pe_util))
    print('pe_overhead : {0:.2%}'.format(pe_overhead))
    print('input uasge : {0:.2%}   output uasge : {1:.2%}    output utilization : {2:.2%}  mem_usage : {3:.2%}'.format(i_usage, o_usage, o_util, i_usage*o_usage))
    
    layer_cycle, layer_pe_util, layer_pe_overhead, layer_i_usage, layer_o_usage, layer_o_util, layer_sp_config = opt_layer_info
    layer_mem_usage = ['{0:.2%}'.format(x*y) for x,y in zip(layer_i_usage, layer_o_usage)]


    print('layer_cycle : {0}'.format(layer_cycle))
    print('layer_pe_util : {0}'.format(['{0:.2%}'.format(x) for x in layer_pe_util]))
    print('layer_pe_overhead : {0}'.format(['{0:.2%}'.format(x) for x in layer_pe_overhead]))
    print('layer_i_usage : {0}'.format(['{0:.2%}'.format(x) for x in layer_i_usage]))
    print('layer_o_usage : {0}'.format(['{0:.2%}'.format(x) for x in layer_o_usage]))
    print('layer_o_util : {0}'.format(['{0:.2%}'.format(x) for x in layer_o_util]))
    print('layer_mem_usage : {0}'.format(layer_mem_usage))
    print('layer sp config : {0}'.format(layer_sp_config))
        
    for net_t in net_tag_list:
        if (net_t != options[keys]['net_tag'] or True):

            # net_tag = options[keys]['net_tag']
            net_tag = net_t
            clk = options[keys]['clk']
            ov = options[keys]['ov']

            print()
            print('-----{0}-----'.format(net_t))
            
            print(net_tag)
            print(clk)
            print(ov)
            # total_info, layer_info = layer_calculation(net_dict[net_t], opt_config)
            total_info, layer_info = layer_calculation(net_dict[net_tag], opt_config)

            s = 'configuration [t, r, s, p] : {0}' if not ic_oc_block_mapping else 'configuration [t, r, s*p] : {0}'
            print(s.format(opt_config))
            total_cycles, num_pe, pe_util, pe_overhead, i_usage, o_usage, o_util = total_info
            print('total_cycle : {0}'.format(total_cycles))
            print('# of PE : {0}'.format(num_pe))
            print('pe_util : {0:.2%}'.format(pe_util))
            print('pe_overhead : {0:.2%}'.format(pe_overhead))
            print('input uasge : {0:.2%}   output uasge : {1:.2%}    output utilization : {2:.2%}  mem_usage : {3:.2%}'.format(i_usage, o_usage, o_util, i_usage*o_usage))
            
            layer_cycle, layer_pe_util, layer_pe_overhead, layer_i_usage, layer_o_usage, layer_o_util, layer_sp_config = layer_info
            layer_mem_usage = ['{0:.2%}'.format(x*y) for x,y in zip(layer_i_usage, layer_o_usage)]


            print('computational ratio : {0}'.format(layer_cycle))
            print('layer_pe_util : {0}'.format(['{0:.2%}'.format(x) for x in layer_pe_util]))
            print('layer_pe_overhead : {0}'.format(['{0:.2%}'.format(x) for x in layer_pe_overhead]))
            print('layer_i_usage : {0}'.format(['{0:.2%}'.format(x) for x in layer_i_usage]))
            print('layer_o_usage : {0}'.format(['{0:.2%}'.format(x) for x in layer_o_usage]))
            print('layer_o_util : {0}'.format(['{0:.2%}'.format(x) for x in layer_o_util]))
            print('layer_mem_usage : {0}'.format(layer_mem_usage))
            print('layer sp config : {0}'.format(layer_sp_config))
            
            
            f.write('{0}\n'.format(options[keys]['net_tag']))
            f.write('{0}MHz\n'.format(clk))
            f.write('{0}\n'.format(ov))
            f.write('{0}\n'.format(net_tag))
            f.write('{0}\n'.format(opt_config))
            f.write('{0}\n'.format(total_cycles))
            f.write('{0}\n'.format(num_pe))
            f.write('{0:.2%}\n'.format(pe_util))
            f.write('{0:.2%}\n'.format(pe_overhead))
            f.write('{0:.2%}\n'.format(i_usage*o_usage))
            f.write('{0:.2%}\n'.format(i_usage))
            f.write('{0:.2%}\n'.format(o_usage))
            f.write('{0:.2%}\n'.format(o_util))
            f.write('\n')
            f.write('{0}\n'.format(layer_cycle))
            f.write('{0}\n'.format(['{0:.2%}'.format(x) for x in layer_pe_util]))
            f.write('{0}\n'.format(['{0:.2%}'.format(x) for x in layer_pe_overhead]))
            f.write('{0}\n'.format(layer_mem_usage))
            f.write('{0}\n'.format(['{0:.2%}'.format(x) for x in layer_i_usage]))
            f.write('{0}\n'.format(['{0:.2%}'.format(x) for x in layer_o_usage]))
            f.write('{0}\n'.format(['{0:.2%}'.format(x) for x in layer_o_util]))
            f.write('{0}\n'.format(layer_sp_config))
            f.write('\n')
            f.write('\n')
            f.write('\n')
            
x_axis = np.array(plot_o_util)
y_axis = np.array(plot_pe_util)
x1_axis = np.array(plot_all_o_util)
y1_axis = np.array(plot_all_pe_util)
dot_tag = np.array(plot_config)


plt.xlim([0, 1.0])
plt.ylim([0, 1.0])
plt.scatter(x1_axis,y1_axis, s=1, color='dodgerblue')
plt.scatter(x_axis[:-1],y_axis[:-1], s=16, color='red')
plt.scatter(x_axis[-1],y_axis[-1], s=54, marker='x', color='limegreen')
plt.xlabel('o_util')
plt.ylabel('pe_util')
plt.title('example')
plt.text(x_axis[-1] + 0.02, y_axis[-1] + 0.02, str(dot_tag[-1]), color = 'b', fontsize = 12) # x,
plt.show()

f.close()