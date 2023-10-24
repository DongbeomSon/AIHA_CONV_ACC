import torch
import torch.nn as nn
import numpy as np
import sys
import math
import torch.nn.functional as F

group_num = sys.argv[1]
group_num = int(group_num)

if len(sys.argv) != 2:
    print("Insufficient arguments")
    sys.exit()
    
if type(group_num) is not int:
    print("Inappropriate arguments")
    sys.exit()

print("TB geneartor GROUP_NUM : ", group_num)

ic = 64
ih = 112
iw = 112

oc = 64
oh = 112
ow = 112

kk = 3

pe_row = 14

tile_row = math.ceil(oh/pe_row)

conv2d = nn.Conv2d(in_channels=ic, out_channels=oc, kernel_size=kk, padding=1, bias=False)
relu = nn.ReLU(inplace=False)

# randomize input feature map
ifm = []
for i in range (group_num):
    t = torch.rand(1, ic, ih, iw)*255-128
    t = torch.round(t)
    ifm.append(t)
    
#ifm = torch.ones(1, ic, ih, iw)
#ifm = torch.round(ifm)
# randomize weight
weight = []
for i in range (group_num):
    t = torch.rand(oc, ic, kk, kk)*255 - 128
    t = torch.round(t)
    weight.append(t)
# weight = torch.rand(oc, ic, kk, kk)*4
# weight = torch.ones(oc, ic, kk, kk)
# weight = torch.randint(1,4,(oc, ic, kk, kk))
# weight = torch.round(weight)


ofm_relu = []
for i in range (group_num):
    # setting the kernel of conv2d as weight
    conv2d.weight = nn.Parameter(weight[i])

    # computing output feature
    t = conv2d(ifm[i])
    ofm_relu.append(relu(t))


ifm_padded = []
padding_layer = nn.ZeroPad2d(1)

for i in range(group_num):
    padded_ifm = padding_layer(ifm[i])
    ifm_padded.append(padded_ifm)

ifm_np_l = []
weight_np_l = []
ofm_np_l = []

for x in ifm_padded:
    ifm_np_l.append(x.data.numpy().astype(int))

for x in weight:
    weight_np_l.append(x.data.numpy().astype(int))
    
for x in ofm_relu:
    ofm_np_l.append(x.data.numpy().astype(int))


# ifm_np = ifm.data.numpy().astype(int)
# weight_np = weight.data.numpy().astype(int)
# ofm_np = ofm_relu.data.numpy().astype(int)

# write data as a 2's complement binary representation type

tile_length = 14
num_tile = 114//tile_length

ifm_num = 0
with open("ifm.txt", "w") as f:
    for ifm_np in ifm_np_l:
        for ii in range(tile_row):
            for jj in range(num_tile):
                for c in range(ic):
                    for j in range(tile_length + 2):
                        col = jj*tile_length + j
                        for i in range(16):
                            row = ii*14+i
                            # print(row, c, ii)
                            k = ifm_np[0, c, row, col]
                            s = str(k) + " "
                            f.write(s)
                    f.write("\n")    
                f.write("\n")    
            f.write("\n")
        f.write("\n")
    
    
# byte write
with open("ifm.dat", "wb") as f:
    for ifm_np in ifm_np_l:
        for ii in range(tile_row):
            for jj in range(num_tile):
                for c in range(ic):
                    for j in range(tile_length + 2):
                        col = jj*tile_length + j
                        for i in range(16):
                            row = ii*14+i
                            # print(row, c, ii)
                            k = ifm_np[0, c, row, col]
                            f.write(k.astype('int8').tobytes())
                            ifm_num += 1
    
    

print("---ifm_num--- %d" % ifm_num)
ifm_num = 0

with open("wgt.txt", "w") as f:
    for weight_np in weight_np_l:
        for ii in range(tile_row):
            for jj in range(num_tile):
                for j in range(ic):
                    for k in range(kk):
                        for i in range(0, oc , 1):
                            for l in weight_np[i, j, :, k]:
                                s = str(l) + " "
                                f.write(s)
                        f.write("\n")
                    f.write("\n")
                f.write("\n")
            f.write("\n")
        f.write("\n")
        f.write("\n")

with open("wgt.dat", "wb") as f:
    for weight_np in weight_np_l:
        for ii in range(tile_row):
            for jj in range(num_tile):
                for j in range(ic):
                    for k in range(kk):
                        for i in range(0, oc , 1):
                            for l in weight_np[i, j, :, k]:
                                f.write(l.astype('int8').tobytes())
                                ifm_num += 1
print("---wgt_num--- %d" % ifm_num)

ofm = 0
with open("ofm.txt", "w") as f:
    for ofm_np in ofm_np_l:
        for i in range(oc):
            for j in range(oh):
                for k in ofm_np[0, i, j, :]:
                    s = str(k) + ","
                    f.write(s)
                    ofm += 1
                f.write("\n")
            f.write("\n")
        
print("---ofm_num--- %d" % ofm)


# #write byte ver
# with open("ifm_bin.txt", "w") as f:
#     for ifm_np in ifm_np_l:
#         for ii in range(13):
#             for jj in range(num_tile):
#                 for c in range(ic):
#                     for j in range(tile_length + 2):
#                         col = jj*tile_length + j
#                         for i in range(8):
#                             row = ii*5+i
#                             # print(row, c, ii)
#                             k = ifm_np[0, c, row, col] if ((row < 64) and (col < 64))else 0
#                             s = np.binary_repr(k, 8) + " "
#                             f.write(s)
#                             ifm_num += 1
#                         f.write("\n")
#                 f.write("\n")    
#             f.write("\n")
#         f.write("\n")

# print("---ifm_num--- %d" % ifm_num)
# ifm_num = 0

# with open("wgt_bin.txt", "w") as f:
#     for weight_np in weight_np_l:
#         for i in range(oc):
#             for ii in range(13):
#                 for jj in range(num_tile):
#                     for j in range(ic):
#                         for k in range(kk):
#                             for l in weight_np[i, j, :, k]:
#                                 s = np.binary_repr(l, 8) + " "
#                                 f.write(s)
#                                 ifm_num += 1
#                             f.write("\n")
#                         f.write("\n")
#                     f.write("\n")
#                 f.write("\n")
#             f.write("\n")