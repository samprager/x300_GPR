//*****************************************************************************
// (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 2.1
//  \   \         Application        : MIG
//  /   /         Filename           : example_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $
// \   \  /  \    Date Created       : Tue Sept 21 2010
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : DDR3 SDRAM
// Purpose          :
//   Top-level  module. This module serves as an example,
//   and allows the user to synthesize a self-contained design,
//   which they can be used to test their hardware.
//   In addition to the memory controller, the module instantiates:
//     1. Synthesizable testbench - used to model user's backend logic
//        and generate different traffic patterns
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module decoder_top #(
  parameter DEST_ADDR       =48'h985aebdb066f,
  parameter SRC_ADDR        = 48'h5a0102030405
)(
input rx_fifo_clock,
input rx_fifo_resetn,

// Decoded Commands from RGMII RX fifo
output     [31:0] cmd_axis_tdata,
output           cmd_axis_tvalid,
output           cmd_axis_tlast,
input            cmd_axis_tready,

input           enable_rx_decode,
input [1:0]     speed,

input       [7:0]                     rx_axis_tdata,
input                                 rx_axis_tvalid,
input                                 rx_axis_tlast,
output                                rx_axis_tready

);



wire     [31:0]  cmd_pkt_axis_tdata;
wire             cmd_pkt_axis_tvalid;
wire             cmd_pkt_axis_tlast;
wire             cmd_pkt_axis_tready;

kc705_ethernet_rgmii_axi_rx_decoder #(
  //   parameter                            DEST_ADDR       = 48'hda0102030405,
     .DEST_ADDR       (DEST_ADDR),
     .SRC_ADDR        (SRC_ADDR),
     .MAX_SIZE        (16'd500),
  //   parameter                            MIN_SIZE        = 16'd64,
    .MIN_SIZE         (16'd500),
    .ENABLE_VLAN      (1'b0),
    .VLAN_ID          (12'd2),
    .VLAN_PRIORITY    (3'd2)
 ) rx_cmd_decoder_inst (
     .axi_tclk (rx_fifo_clock),
     .axi_tresetn (rx_fifo_resetn),

     .enable_rx_decode        (enable_rx_decode),
     .speed                  (speed),

   // data from the RX data path
     .rx_axis_tdata       (rx_axis_tdata),
     .rx_axis_tvalid       (rx_axis_tvalid),
     .rx_axis_tlast       (rx_axis_tlast),
     .rx_axis_tready      (rx_axis_tready),

   // data TO the TX data path
     .tdata       (cmd_pkt_axis_tdata),
     .tvalid       (cmd_pkt_axis_tvalid),
     .tlast       (cmd_pkt_axis_tlast),
     .tready      (cmd_pkt_axis_tready)
);


 axi_rx_command_gen #(
  ) axi_rx_command_gen_inst (
      .axi_tclk (rx_fifo_clock),
      .axi_tresetn (rx_fifo_resetn),

      .enable_rx_decode        (enable_rx_decode),

    // data from the RX data path
      .cmd_axis_tdata       (cmd_pkt_axis_tdata),
      .cmd_axis_tvalid       (cmd_pkt_axis_tvalid),
      .cmd_axis_tlast       (cmd_pkt_axis_tlast),
      .cmd_axis_tready      (cmd_pkt_axis_tready),

    // data TO the TX data path
      .tdata       (cmd_axis_tdata),
      .tvalid       (cmd_axis_tvalid),
      .tlast       (cmd_axis_tlast),
      .tready      (cmd_axis_tready)
);

endmodule
