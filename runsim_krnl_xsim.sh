#!/bin/bash

#
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
#

# number of data groups (packet) to be processed
# export CI=0
# export CO=0
export GROUP_NUM=$1
export CI=$2
export CO=$3
export TI=16
export TI_FACTOR=$[64/$TI]
export CFG_CI=$[$[$CI+1] * 8]
export CFG_CO=$[$[$CO+1] * 8]
export IFM_LEN=$[$[$TI+3]*$CFG_CI*$TI_FACTOR*13*8]
export WGT_LEN=$[4*4*$CFG_CI*$CFG_CO*13*$TI_FACTOR]
export OFM_LEN=$[61*61*$CFG_CO*4]
export IW=64
# export GROUP_NUM=1


echo $GROUP_NUM
echo $CI
echo $IFM_LEN
echo $WGT_LEN

rm -f ifm.dat wgt.dat
for ((i = 0; i < $GROUP_NUM; i++))
do
  ./script/plain_gen.pl $IFM_LEN ./ifm_temp.dat
  cat ./ifm_temp.dat >> ifm.dat
  ./script/plain_gen.pl $WGT_LEN ./wgt_temp.dat
  cat ./wgt_temp.dat >> wgt.dat
done

xvlog -f ./filelist_krnl_conv.f      \
      -L xilinx_vip                \
      -d GROUP_NUM=$GROUP_NUM \
      -d CI=$CI \
      -d CO=$CO \
      -d IW=$IW \
      --sv # -d DUMP_WAVEFORM
      
xelab tb_krnl_acc glbl     \
      -debug typical        \
      -L unisims_ver        \
      -L xpm                \
      -L xilinx_vip

xsim -t xsim.tcl --wdb work.tb_krnl_acc.wdb work.tb_krnl_acc#work.glbl