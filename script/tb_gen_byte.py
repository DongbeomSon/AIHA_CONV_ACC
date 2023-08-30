import torch
import torch.nn as nn
import numpy as np


ic = 8
ih = 64
iw = 64

oc = 8
oh = 61
ow = 61

kk = 4

conv2d = nn.Conv2d(in_channels=ic, out_channels=oc, kernel_size=kk, padding=0, bias=False)
relu = nn.ReLU(inplace=False)

# randomize input feature map
ifm = torch.rand(1, ic, ih, iw)*255-128
#ifm = torch.ones(1, ic, ih, iw)
ifm = torch.round(ifm)
# randomize weight
weight = torch.rand(oc, ic, kk, kk)*255 - 128
# weight = torch.rand(oc, ic, kk, kk)*4
# weight = torch.ones(oc, ic, kk, kk)
# weight = torch.randint(1,4,(oc, ic, kk, kk))
weight = torch.round(weight)

# setting the kernel of conv2d as weight
conv2d.weight = nn.Parameter(weight)

# computing output feature
ofm = conv2d(ifm)
ofm_relu = relu(ofm)

ifm_np = ifm.data.numpy().astype(int)
weight_np = weight.data.numpy().astype(int)
ofm_np = ofm_relu.data.numpy().astype(int)

# write data as a 2's complement binary representation type

tile_length = 16
num_tile = 64//tile_length

ifm_num = 0
with open("ifm.txt", "w") as f:
    for ii in range(13):
        for jj in range(num_tile):
            for c in range(ic):
                for j in range(tile_length + 3):
                    col = jj*tile_length + j
                    for i in range(8):
                        row = ii*5+i
                        # print(row, c, ii)
                        k = ifm_np[0, c, row, col] if ((row < 64) and (col < 64)) else 0
                        s = str(k) + " "
                        f.write(s)
                    f.write("\n")
            f.write("\n")    
        f.write("\n")
    f.write("\n")
    
    
# byte write
with open("ifm.dat", "wb") as f:
    for ii in range(13):
        for jj in range(num_tile):
            for c in range(ic):
                for j in range(tile_length + 3):
                    col = jj*tile_length + j
                    for i in range(8):
                        row = ii*5+i
                        # print(row, c, ii)
                        k = ifm_np[0, c, row, col] if ((row < 64) and (col < 64)) else np.int64(0)
                        f.write(k.astype('int8').tobytes())
                        ifm_num += 1
    
    

print("---ifm_num--- %d" % ifm_num)
ifm_num = 0

with open("wgt.txt", "w") as f:
    for i in range(oc):
        for ii in range(13):
            for jj in range(num_tile):
                for j in range(ic):
                    for k in range(kk):
                        for l in weight_np[i, j, :, k]:
                            s = str(l) + " "
                            f.write(s)
                        f.write("\n")
                    f.write("\n")
                f.write("\n")
            f.write("\n")
        f.write("\n")
        
with open("wgt.dat", "wb") as f:
    for i in range(oc):
        for ii in range(13):
            for jj in range(num_tile):
                for j in range(ic):
                    for k in range(kk):
                        for l in weight_np[i, j, :, k]:
                            f.write(l.astype('int8').tobytes())
                            ifm_num += 1
print("---wgt_num--- %d" % ifm_num)

ofm = 0
with open("ofm.txt", "w") as f:
    for i in range(oc):
        for j in range(oh):
            for k in ofm_np[0, i, j, :]:
                s = str(k) + ","
                f.write(s)
                ofm += 1
            f.write("\n")
        f.write("\n")
print("---ofm_num--- %d" % ofm)


#write byte ver
with open("ifm_bin.txt", "w") as f:
    for ii in range(13):
        for jj in range(num_tile):
            for c in range(ic):
                for j in range(tile_length + 3):
                    col = jj*tile_length + j
                    for i in range(8):
                        row = ii*5+i
                        # print(row, c, ii)
                        k = ifm_np[0, c, row, col] if ((row < 64) and (col < 64))else 0
                        s = np.binary_repr(k, 8) + " "
                        f.write(s)
                        ifm_num += 1
                    f.write("\n")
            f.write("\n")    
        f.write("\n")
    f.write("\n")

print("---ifm_num--- %d" % ifm_num)
ifm_num = 0

with open("wgt_bin.txt", "w") as f:
    for i in range(oc):
        for ii in range(13):
            for jj in range(num_tile):
                for j in range(ic):
                    for k in range(kk):
                        for l in weight_np[i, j, :, k]:
                            s = np.binary_repr(l, 8) + " "
                            f.write(s)
                            ifm_num += 1
                        f.write("\n")
                    f.write("\n")
                f.write("\n")
            f.write("\n")
        f.write("\n")