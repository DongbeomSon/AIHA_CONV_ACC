#!/bin/bash

#
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
#

ceil (){
      local a=$1
      local b=$2
      rtn=$[($a+$b-1)/$b]
      return $rtn
}

# number of data groups (packet) to be processed
export CI=0
export CO=0
export IW=64
export IH=64
export OW=62
export OH=62
export PE_ROW=8
export TI=16
export KK=3
export INPUT_BYTE=1
export OUTPUT_BYTE=4
#export TI_FACTOR=$[64/$TI]

ceil $IW $TI
export TI_FACTOR=$?
ceil $IH $PE_ROW
export TI_ROW=$?

export CFG_CI=$[$[$CI+1] * 8]
export CFG_CO=$[$[$CO+1] * 8]
export IFM_LEN=$[$[$TI+($KK-1)]*$CFG_CI*$TI_FACTOR*$[$PE_ROW+($KK-1)]*$TI_ROW*$INPUT_BYTE]
export WGT_LEN=$[$KK*$KK*$CFG_CI*$CFG_CO*$TI_ROW*$TI_FACTOR*$INPUT_BYTE]
export OFM_LEN=$[$OW*$OH*$CFG_CO*$OUTPUT_BYTE]
# export GROUP_NUM=1
export GROUP_NUM=${1:-1}

echo $TI_FACTOR

echo $GROUP_NUM
echo $IFM_LEN
echo $WGT_LEN

xvlog -f ./filelist_krnl_conv.f      \
      -L xilinx_vip                \
      -d GROUP_NUM=$GROUP_NUM \
      --sv # -d DUMP_WAVEFORM
      
xelab tb_krnl_acc glbl     \
      -debug typical        \
      -L unisims_ver        \
      -L xpm                \
      -L xilinx_vip

xsim -t xsim.tcl --wdb work.tb_krnl_acc.wdb work.tb_krnl_acc#work.glbl