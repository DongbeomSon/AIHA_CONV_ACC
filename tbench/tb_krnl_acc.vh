//
//
//# Copyright (C) 2023, Advanced Micro Devices, Inc. All rights reserved.
//# SPDX-License-Identifier: X11
//
//


// Tasks for tb_krnl_cbc

/////////////////////////////////////////////////////////////////////////////////////////////////
// Initial VIPs
task automatic init_vips();
  axi_ready_gen     rgen;

  $display("Starting AXI Control Master: krnl_acc");

  krnl_acc_ctrl = new("krnl_acc_ctrl", tb_krnl_acc.axi_vip_mst_krnl_acc.inst.IF);
  krnl_acc_ctrl.start_master();

  $display("Starting Memory slave: input buffer and output_buffer");

  ifm_buffer = new("ifm_buffer", tb_krnl_acc.axi_vip_slv_ifm_buf.inst.IF);
  ifm_buffer.start_slave();

  wgt_buffer = new("wgt_buffer", tb_krnl_acc.axi_vip_slv_wgt_buf.inst.IF);
  wgt_buffer.start_slave();

  ofm_buffer = new("ofm_buffer", tb_krnl_acc.axi_vip_slv_ofm_buf.inst.IF);
  ofm_buffer.start_slave();


// Applying slv_random_backpressure_wready
  rgen = new("axi_random_backpressure_wready");
  rgen.set_ready_policy(XIL_AXI_READY_GEN_RANDOM);
  rgen.set_low_time_range(0,20);
  rgen.set_high_time_range(1,20);
  rgen.set_event_count_range(3,5);
  ifm_buffer.wr_driver.set_wready_gen(rgen);
  wgt_buffer.wr_driver.set_wready_gen(rgen);
  ofm_buffer.wr_driver.set_wready_gen(rgen);
// Applying slv_random_delay_rvalid  
  ifm_buffer.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  ifm_buffer.mem_model.set_inter_beat_gap_range(0,20);
  wgt_buffer.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  wgt_buffer.mem_model.set_inter_beat_gap_range(0,20);
  ofm_buffer.mem_model.set_inter_beat_gap_delay_policy(XIL_AXI_MEMORY_DELAY_RANDOM);
  ofm_buffer.mem_model.set_inter_beat_gap_range(0,20);


endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking write
// The task will return when the BRESP has been returned from the kernel.
task automatic blocking_write_register (input axi_vip_mst_mst_t ctrl, input bit [31:0] addr_in, input bit [31:0] data);
  axi_transaction   wr_xfer;
  axi_transaction   wr_rsp;
  wr_xfer = ctrl.wr_driver.create_transaction("wr_xfer");
  wr_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  assert(wr_xfer.randomize() with {addr == addr_in;});
  wr_xfer.set_data_beat(0, data);
  ctrl.wr_driver.send(wr_xfer);
  ctrl.wr_driver.wait_rsp(wr_rsp);
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// Control interface blocking read
// The task will return when the BRESP has been returned from the kernel.
task automatic read_register (input axi_vip_mst_mst_t ctrl, input bit [31:0] addr, output bit [31:0] rddata);
  axi_transaction   rd_xfer;
  axi_transaction   rd_rsp;
  bit [31:0] rd_value;
  rd_xfer = ctrl.rd_driver.create_transaction("rd_xfer");
  rd_xfer.set_addr(addr);
  rd_xfer.set_driver_return_item_policy(XIL_AXI_PAYLOAD_RETURN);
  ctrl.rd_driver.send(rd_xfer);
  ctrl.rd_driver.wait_rsp(rd_rsp);
  rd_value = rd_rsp.get_data_beat(0);
  rddata = rd_value;
endtask

/////////////////////////////////////////////////////////////////////////////////////////////////
// CTRL register operation
// This will poll until the DONE flag in the status register is asserted.
task automatic poll_done_register (input axi_vip_mst_mst_t ctrl);
  bit [31:0] rd_value;
  do begin
    read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_DONE_MASK) == 0);
endtask

// This will poll until the IDLE flag in the status register is asserted.
task automatic poll_idle_register (input axi_vip_mst_mst_t ctrl);
  bit [31:0] rd_value;
  do begin
    read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_IDLE_MASK) == 0);
endtask

// This will poll until the READY flag in the status register is asserted.
task automatic poll_ready_register (input axi_vip_mst_mst_t ctrl);
  bit [31:0] rd_value;
  do begin
    read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_READY_MASK) == 0);
endtask

// This will set START flag
task automatic set_start_register (input axi_vip_mst_mst_t ctrl);
  blocking_write_register(ctrl, KRNL_CTRL_REG_ADDR, CTRL_START_MASK);
endtask

// This will set CONTINUE flag
task automatic set_continue_register (input axi_vip_mst_mst_t ctrl);
  blocking_write_register(ctrl, KRNL_CTRL_REG_ADDR, CTRL_CONTINUE_MASK);
endtask

// This will poll the START flag in the status register is DE-asserted.
task automatic poll_start_register (input axi_vip_mst_mst_t ctrl);
  bit [31:0] rd_value;
  do begin
    read_register(ctrl, KRNL_CTRL_REG_ADDR, rd_value);
  end while ((rd_value & CTRL_START_MASK) != 0);
endtask


/////////////////////////////////////////////////////////////////////////////////////////////////
// Backdoor fill the input buffer AXI vip memory model with 512-bit words
function void in_buffer_fill_memory(
  input axi_vip_slv_slv_mem_t mem,      // vip memory model handle
  input bit [63:0] ptr,                 // start address of memory fill, should allign to 16-byte
  input bit [511:0] words_data[$],      // data source to fill memory
  input integer offset,                 // start index of data source
  input integer words                   // number of words to fill
);
  int index;
  bit [511:0] temp;
  int i;
  for (index = 0; index < words; index++) begin
     for (i = 0; i < 64; i = i + 1) begin // endian conversion to emulate general memory little endian behavior
         temp[i*8+7-:8] = words_data[offset+index][(63-i)*8+7-:8];
     end
    mem.mem_model.backdoor_memory_write(ptr + index * 64, words_data[offset+index]);
  end
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// Backdoor dump data from outputt buffer AXI vip memory model with 512-bit words
function void out_buffer_dump_memory(
  input axi_vip_slv_slv_mem_t mem,      // vip memory model handle
  input bit [63:0] ptr,                 // start address of memory fill, should allign to 16-byte
  inout bit [511:0] words_data[$],      // data source to fill memory
  input integer offset,                 // start index of data source
  input integer words                   // number of words to fill
);
  int index;
  bit [511:0] temp;
  int i, j;
  for (index = 0; index < words; index++) begin
    temp = mem.mem_model.backdoor_memory_read(ptr + index * 64);
    for (j = 0; j < 16; j = j + 1) begin
      for (i = 0; i < 4; i = i + 1) begin // endian conversion to emulate general memory little endian behavior
          words_data[offset+index][32*j + i*8+7-:8] = temp[32*j + (3-i)*8+7-:8];
      end
    end
  end
endfunction

/////////////////////////////////////////////////////////////////////////////////////////////////
// compare two 512-bit array of `WORD_NUM words
function int words_compare(
  input bit [511:0] exp_words[$],
  input bit [511:0] act_words[$],
  input integer words,
  input integer mode
);
  int index;
  int success;
  success = 1;
  // {exp_words[index][511:384] + mode, exp_words[index][383:256] + mode, exp_words[index][255:128] + mode, exp_words[index][127:0] + mode}
  for (index = 0; index < words; index++) begin
    if (({exp_words[index][511:384] + mode, exp_words[index][383:256] + mode, exp_words[index][255:128] + mode, exp_words[index][127:0] + mode}) != act_words[index]) begin
      $display("  -- MISMATCH at word %d: exp = %x, act = %x", index, ({exp_words[index][511:384] + mode, exp_words[index][383:256] + mode, exp_words[index][255:128] + mode, exp_words[index][127:0] + mode}), act_words[index]);
      success = 0;
    end else begin
      $display("  -- !MATCH at word %d: input = %x, exp = %x, act = %x", index, exp_words[index], ({exp_words[index][511:384] + mode, exp_words[index][383:256] + mode, exp_words[index][255:128] + mode, exp_words[index][127:0] + mode}), act_words[index]);
    end
  end
  return(success);
endfunction

