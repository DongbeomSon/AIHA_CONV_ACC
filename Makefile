#
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
#

ECHO=@echo

.PHONY: help

help::
	$(ECHO) "Makefile Usage:"
	$(ECHO) "  make gen_ip"
	$(ECHO) "      Command to generate the IPs used in this design"
	$(ECHO) ""
	$(ECHO) "  make pack_kernel"
	$(ECHO) "      Command to pack the module krnl_acc to Vitis kernel"
	$(ECHO) ""
	$(ECHO) "  make runsim"
	$(ECHO) "      Command to run the simulation"
	$(ECHO) ""
	$(ECHO) "  make build_hw"
	$(ECHO) "      Command to build xclbin files for Alveo platform, including krnl_acc and krnl_aes kernels"
	$(ECHO) ""
	$(ECHO) "  make build_sw"
	$(ECHO) "      Command to build host software for xclbin test"
	$(ECHO) ""
	$(ECHO) "  make clean"
	$(ECHO) "      Command to remove all the generated files."

# PART setting: uncomment the line matching your Alveo card
#PART := xcu200-fsgd2104-2-e
PART := xcu250-figd2104-2L-e
#PART := xcu50-fsvh2104-2-e
#PART := xcu55c-fsvh2892-2L-e
#PART := xcu280-fsvh2892-2L-e

# PLATFORM setting: uncomment the lin matching your Alveo card
#PLATFORM := xilinx_u200_gen3x16_xdma_2_202110_1
PLATFORM := xilinx_u250_gen3x16_xdma_4_1_202210_1
#PLATFORM := xilinx_u50_gen3x16_xdma_5_202210_1
#PLATFORM := xilinx_u55c_gen3x16_xdma_3_202210_1
#PLATFORM := xilinx_u280_gen3x16_xdma_1_202211_1

# TARGET: set the build target, can be hw or hw_emu
TARGET := hw

GROUP_NUM := 1

V_MODE := hw

CI := 7
CO := 7

IW := 112

.phony: clean traces

################## resource generation and simulation 
gen_ip:
	rm -rf ip_generation; mkdir ip_generation; vivado -mode batch -source ./gen_ip.tcl -tclargs $(PART)


pack_kernel:
	rm -rf vivado_pack_krnl_project; mkdir vivado_pack_krnl_project; cd vivado_pack_krnl_project; vivado -mode batch -source ../pack_kernel.tcl -tclargs $(PART)

runsim:
	rm -rf data; mkdir data; cd data; python3 ../script/tb_gen_byte.py $(GROUP_NUM) $(CI) $(CO) $(IW);
	./runsim_krnl_xsim.sh $(GROUP_NUM) $(CI) $(CO) $(IW);
#	cd data; python3 ../script/compare.py;
#	cp ./script/compare.py ./data/t1/compare.py; cp ./script/compare.py ./data/t2/compare.py; cd data/t1; python3 ./compare.py; cd ..; cd t2; python3 ./compare.py;

gen_tb:
	rm -rf data; mkdir data; cd data; python3 ../script/tb_gen_byte.py $(GROUP_NUM) $(CI) $(CO) $(IW);
#	rm ./data/*.txt; cd data; python3 testbench_gen.py


validate:
	cd data; python3 ../script/compare.py $(V_MODE);

runhw:
	rm -rf data; mkdir data; cd data; python3 ../script/tb_gen_byte.py $(GROUP_NUM) $(CI) $(CO) $(IW);
	./host_krnl_acc_test -i $(CI) -o $(CO) -w $(IW);
	cd data; python3 ../script/compare.py $(V_MODE);

################## hardware build 
XOCCFLAGS := --platform $(PLATFORM) -t $(TARGET)  -s -g
XOCCLFLAGS := --link --optimize 3 --report_level 2
# You could uncomment following line and modify the options for hardware debug/profiling
#DEBUG_OPT := --debug.chipscope krnl_aes_1 --debug.chipscope krnl_acc_1 --debug.protocol all --profile_kernel data:all:all:all:all
#DEBUG_OPT := --profile_kernel data:all:all:all:all

build_hw:
	rm -rf vivado_pack_krnl_project; mkdir vivado_pack_krnl_project; cd vivado_pack_krnl_project; vivado -mode batch -source ../pack_kernel.tcl -tclargs $(PART);
	v++ $(XOCCLFLAGS) $(XOCCFLAGS) $(DEBUG_OPT) --config krnl_acc_test.cfg -o krnl_acc_test_$(TARGET).xclbin krnl_acc.xo

all: gen_ip pack_kernel build_hw

################## software build for XRT Native API code
CXXFLAGS := -std=c++17 -Wno-deprecated-declarations
CXXFLAGS += -I$(XILINX_XRT)/include
LDFLAGS := -L$(XILINX_XRT)/lib
LDFLAGS += $(LDFLAGS) -lxrt_coreutil -lssl -lcrypto -lpthread
EXECUTABLE := host_krnl_acc_test

HOST_SRCS := ./host/host_krnl_acc_test.cpp

build_sw: host_krnl_acc_test

$(EXECUTABLE): $(HOST_SRCS)
	$(CXX) -o $(EXECUTABLE) $^ $(CXXFLAGS) $(LDFLAGS)

################## clean up
clean:
	$(RM) -rf ip_generation vivado_pack_krnl_project
	$(RM) -rf *.xo *.xclbin *.xclbin.info *.xclbin.link_summary *.jou *.log *.xo.compile_summary _x
	$(RM) -rf *.dat *.pb xsim.dir *.xml *.ltx *.csv *.json *.protoinst *.wdb *.wcfg host_krnl_acc_test
