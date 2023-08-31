#
# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
# SPDX-License-Identifier: X11
#

##################################### Step 1: create vivado project and add design sources

# create ip project with part name in command line argvs
create_project krnl_acc ./krnl_acc -part [lindex $argv 0]

# add design sources into project
#              ../rtl/cbc_engine.v 
add_files -norecurse \
       {                                         \
                            ../rtl/axi_master_counter.sv       \
                            ../rtl/axi_read_master.sv          \
                            ../rtl/axi_write_master.sv         \
                            ../rtl/TPSR.v \
                            ../rtl/FifoCtlType0.v \
                            ../rtl/FifoType0.v \

                            ../rtl_acc/PSUM_ADD.v \
                            ../rtl_acc/PSUM_BUFF.v       \
                            ../rtl_acc/SYNCH_FIFO.v      \
                            ../rtl_acc/WRITE_BACK.v      \
                            ../rtl_acc/PE.v       \
                            ../rtl_acc/IFM_BUF.v  \
                            ../rtl_acc/WGT_BUF.v  \
                            ../rtl_acc/PE_FSM.v   \
                            ../rtl_acc/CONV_ACC.v  \
                            ../rtl_acc/acc_eng_ctrl.v \
                            ../rtl_acc/Flatter.v \
                            ../rtl_acc/krnl_acc_axi_ctrl_slave.v \
                            ../rtl_acc/krnl_acc.v \
                            ../rtl_acc/parser.v \
                            ../rtl_acc/switch_buffer.v \
                            ../rtl_acc/conv_engine.v \
       }

update_compile_order -fileset sources_1

# create IP packaging project
ipx::package_project -root_dir ./krnl_acc_ip -vendor xilinx.com -library user -taxonomy /UserIP -import_files -set_current true


##################################### Step 2: Inference clock, reset, AXI interfaces and associate them with clock

# inference clock and reset signals
ipx::infer_bus_interface ap_clk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface ap_rst_n xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]

# associate AXI/AXIS interface with clock
ipx::associate_bus_interfaces -busif s_axi_control  -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m_ofm       -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m_ifm       -clock ap_clk [ipx::current_core]
ipx::associate_bus_interfaces -busif m_wgt      -clock ap_clk [ipx::current_core]

# associate reset signal with clock
ipx::associate_bus_interfaces -clock ap_clk -reset ap_rst_n [ipx::current_core]


##################################### Step 3: Set the definition of AXI control slave registers, including CTRL and user kernel arguments

# Add RTL kernel registers
ipx::add_register CTRL         [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register CFG_CI         [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register CFG_CO     [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register IFM_ADDR_BASE        [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register WGT_ADDR_BASE        [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]
ipx::add_register OFM_ADDR_BASE        [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]


# Set RTL kernel registers property
set_property description    {Control Signals}   [ipx::get_registers CTRL    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x000}             [ipx::get_registers CTRL    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {32}                [ipx::get_registers CTRL    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

set_property description    {parameter CI}      [ipx::get_registers CFG_CI    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x010}             [ipx::get_registers CFG_CI    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {32}                [ipx::get_registers CFG_CI    -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

set_property description    {parameter CO}      [ipx::get_registers CFG_CO -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x018}             [ipx::get_registers CFG_CO -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {32}                [ipx::get_registers CFG_CO -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

set_property description    {ifm addr} [ipx::get_registers IFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x020}             [ipx::get_registers IFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {64}                [ipx::get_registers IFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

set_property description    {wgt addr} [ipx::get_registers WGT_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x028}             [ipx::get_registers WGT_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {64}                [ipx::get_registers WGT_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

set_property description    {ofm addr} [ipx::get_registers OFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property address_offset {0x030}             [ipx::get_registers OFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property size           {64}                [ipx::get_registers OFM_ADDR_BASE  -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]

##################################### Step 4: associate AXI master port to pointer argument and set data width

# define association between pointer arguments (ADDR_BASE) and axi masters (m_ifm, m_wgt, m_ofm)
ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers IFM_ADDR_BASE -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property value          {m_ifm}          [ipx::get_register_parameters ASSOCIATED_BUSIF     \
                                    -of_objects [ipx::get_registers IFM_ADDR_BASE                      \
                                    -of_objects [ipx::get_address_blocks reg0                      \
                                    -of_objects [ipx::get_memory_maps s_axi_control                 \
                                    -of_objects [ipx::current_core]]]]]

ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers WGT_ADDR_BASE -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property value          {m_wgt}          [ipx::get_register_parameters ASSOCIATED_BUSIF     \
                                    -of_objects [ipx::get_registers WGT_ADDR_BASE                      \
                                    -of_objects [ipx::get_address_blocks reg0                      \
                                    -of_objects [ipx::get_memory_maps s_axi_control                 \
                                    -of_objects [ipx::current_core]]]]]

ipx::add_register_parameter ASSOCIATED_BUSIF [ipx::get_registers OFM_ADDR_BASE -of_objects [ipx::get_address_blocks reg0 -of_objects [ipx::get_memory_maps s_axi_control -of_objects [ipx::current_core]]]]
set_property value          {m_ofm}          [ipx::get_register_parameters ASSOCIATED_BUSIF     \
                                    -of_objects [ipx::get_registers OFM_ADDR_BASE                      \
                                    -of_objects [ipx::get_address_blocks reg0                      \
                                    -of_objects [ipx::get_memory_maps s_axi_control                 \
                                    -of_objects [ipx::current_core]]]]]

ipx::add_bus_parameter DATA_WIDTH [ipx::get_bus_interfaces m_ifm -of_objects [ipx::current_core]]
set_property value          {512} [ipx::get_bus_parameters DATA_WIDTH -of_objects [ipx::get_bus_interfaces m_ifm -of_objects [ipx::current_core]]]

ipx::add_bus_parameter DATA_WIDTH [ipx::get_bus_interfaces m_wgt -of_objects [ipx::current_core]]
set_property value          {512} [ipx::get_bus_parameters DATA_WIDTH -of_objects [ipx::get_bus_interfaces m_wgt -of_objects [ipx::current_core]]]

ipx::add_bus_parameter DATA_WIDTH [ipx::get_bus_interfaces m_ofm -of_objects [ipx::current_core]]
set_property value          {512} [ipx::get_bus_parameters DATA_WIDTH -of_objects [ipx::get_bus_interfaces m_ofm -of_objects [ipx::current_core]]]


#### Step 5: Package Vivado IP and generate Vitis kernel file

# Set required property for Vitis kernel
set_property sdx_kernel true [ipx::current_core]
set_property sdx_kernel_type rtl [ipx::current_core]

# Packaging Vivado IP
ipx::update_source_project_archive -component [ipx::current_core]
ipx::save_core [ipx::current_core]

# Generate Vitis Kernel from Vivado IP
package_xo -force -xo_path ../krnl_acc.xo -kernel_name krnl_acc -ctrl_protocol ap_ctrl_chain -ip_directory ./krnl_acc_ip -output_kernel_xml ./krnl_acc.xml
