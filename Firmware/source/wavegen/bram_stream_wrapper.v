`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 07:29:14 PM
// Design Name:
// Module Name: bram_stream_wrapper
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module bram_stream_wrapper(
  input aresetn,
  input clk_in1,
  output [7:0]m_axis_mm2s_sts_tdata,
  output [0:0]m_axis_mm2s_sts_tkeep,
  output m_axis_mm2s_sts_tlast,
  input m_axis_mm2s_sts_tready,
  output m_axis_mm2s_sts_tvalid,
  output [31:0]m_axis_mm2s_tdata,
  output [3:0]m_axis_mm2s_tkeep,
  output m_axis_mm2s_tlast,
  input m_axis_mm2s_tready,
  output m_axis_mm2s_tvalid,
  output [7:0]m_axis_s2mm_sts_tdata,
  output [0:0]m_axis_s2mm_sts_tkeep,
  output m_axis_s2mm_sts_tlast,
  input m_axis_s2mm_sts_tready,
  output m_axis_s2mm_sts_tvalid,
  input [71:0]s_axis_mm2s_cmd_tdata,
  output s_axis_mm2s_cmd_tready,
  input s_axis_mm2s_cmd_tvalid,
  input [71:0]s_axis_s2mm_cmd_tdata,
  output s_axis_s2mm_cmd_tready,
  input s_axis_s2mm_cmd_tvalid,
  input [31:0]s_axis_s2mm_tdata,
  input [3:0]s_axis_s2mm_tkeep,
  input s_axis_s2mm_tlast,
  output s_axis_s2mm_tready,
  input s_axis_s2mm_tvalid,
  output mm2s_err,
  output s2mm_err
 );


 wire m_axi_mm2s_aclk;
 wire m_axi_mm2s_aresetn;
 wire m_axis_mm2s_cmdsts_aclk;
 wire m_axis_mm2s_cmdsts_aresetn;

 wire [3 : 0] m_axi_mm2s_arid;
 wire [31 : 0] m_axi_mm2s_araddr;
 wire [7 : 0] m_axi_mm2s_arlen;
 wire [2 : 0] m_axi_mm2s_arsize;
 wire [1 : 0] m_axi_mm2s_arburst;
 wire [2 : 0] m_axi_mm2s_arprot;
 wire [3 : 0] m_axi_mm2s_arcache;
 wire [3 : 0] m_axi_mm2s_aruser;
 wire m_axi_mm2s_arvalid;
 wire m_axi_mm2s_arready;
 wire [31 : 0] m_axi_mm2s_rdata;
 wire [1 : 0] m_axi_mm2s_rresp;
 wire m_axi_mm2s_rlast;
 wire m_axi_mm2s_rvalid;
 wire m_axi_mm2s_rready;

 wire m_axi_s2mm_aclk;
 wire m_axi_s2mm_aresetn;
 wire m_axis_s2mm_cmdsts_awclk;
 wire m_axis_s2mm_cmdsts_aresetn;

 wire [3 : 0] m_axi_s2mm_awid;
 wire [31 : 0] m_axi_s2mm_awaddr;
 wire [7 : 0] m_axi_s2mm_awlen;
 wire [2 : 0] m_axi_s2mm_awsize;
 wire [1 : 0] m_axi_s2mm_awburst;
 wire [2 : 0] m_axi_s2mm_awprot;
 wire [3 : 0] m_axi_s2mm_awcache;
 wire [3 : 0] m_axi_s2mm_awuser;
 wire m_axi_s2mm_awvalid;
 wire m_axi_s2mm_awready;
 wire [31 : 0] m_axi_s2mm_wdata;
 wire [3 : 0] m_axi_s2mm_wstrb;
 wire m_axi_s2mm_wlast;
 wire m_axi_s2mm_wvalid;
 wire m_axi_s2mm_wready;
 wire [1 : 0] m_axi_s2mm_bresp;
 wire m_axi_s2mm_bvalid;
 wire m_axi_s2mm_bready;


wire s_axi_aclk;
wire s_axi_aresetn;

wire s_axi_awlock;
wire [3 : 0] s_axi_bid;
wire s_axi_arlock;
wire [3 : 0] s_axi_rid;

assign s_axi_awlock = 0;    // unused by core
assign s_axi_arlock = 0;    // unused by core

assign s_axi_aclk = clk_in1;
assign s_axi_aresetn = aresetn;
assign m_axi_mm2s_aclk = clk_in1;
assign m_axi_mm2s_aresetn = aresetn;
assign m_axis_mm2s_cmdsts_aclk = clk_in1;
assign m_axis_mm2s_cmdsts_aresetn = aresetn;
assign m_axi_s2mm_aclk = clk_in1;
assign m_axi_s2mm_aresetn = aresetn;
assign m_axis_s2mm_cmdsts_awclk = clk_in1;
assign m_axis_s2mm_cmdsts_aresetn = aresetn;


axi_waveform_bram_ctrl axi_waveform_bram_ctrl_inst (
      .s_axi_aclk(s_axi_aclk),        // input wire s_axi_aclk
      .s_axi_aresetn(s_axi_aresetn),  // input wire s_axi_aresetn
      .s_axi_awid(m_axi_s2mm_awid),        // input wire [3 : 0] s_axi_awid
      .s_axi_awaddr(m_axi_s2mm_awaddr[17:0]),    // input wire [17 : 0] s_axi_awaddr
      .s_axi_awlen(m_axi_s2mm_awlen),      // input wire [7 : 0] s_axi_awlen
      .s_axi_awsize(m_axi_s2mm_awsize),    // input wire [2 : 0] s_axi_awsize
      .s_axi_awburst(m_axi_s2mm_awburst),  // input wire [1 : 0] s_axi_awburst
      .s_axi_awlock(s_axi_awlock),    // input wire s_axi_awlock
      .s_axi_awcache(m_axi_s2mm_awcache),  // input wire [3 : 0] s_axi_awcache
      .s_axi_awprot(m_axi_s2mm_awprot),    // input wire [2 : 0] s_axi_awprot
      .s_axi_awvalid(m_axi_s2mm_awvalid),  // input wire s_axi_awvalid
      .s_axi_awready(m_axi_s2mm_awready),  // output wire s_axi_awready
      .s_axi_wdata(m_axi_s2mm_wdata),      // input wire [31 : 0] s_axi_wdata
      .s_axi_wstrb(m_axi_s2mm_wstrb),      // input wire [3 : 0] s_axi_wstrb
      .s_axi_wlast(m_axi_s2mm_wlast),      // input wire s_axi_wlast
      .s_axi_wvalid(m_axi_s2mm_wvalid),    // input wire s_axi_wvalid
      .s_axi_wready(m_axi_s2mm_wready),    // output wire s_axi_wready
      .s_axi_bid(s_axi_bid),          // output wire [3 : 0] s_axi_bid
      .s_axi_bresp(m_axi_s2mm_bresp),      // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid(m_axi_s2mm_bvalid),    // output wire s_axi_bvalid
      .s_axi_bready(m_axi_s2mm_bready),    // input wire s_axi_bready
      .s_axi_arid(m_axi_mm2s_arid),        // input wire [3 : 0] s_axi_arid
      .s_axi_araddr(m_axi_mm2s_araddr[17:0]),    // input wire [17 : 0] s_axi_araddr
      .s_axi_arlen(m_axi_mm2s_arlen),      // input wire [7 : 0] s_axi_arlen
      .s_axi_arsize(m_axi_mm2s_arsize),    // input wire [2 : 0] s_axi_arsize
      .s_axi_arburst(m_axi_mm2s_arburst),  // input wire [1 : 0] s_axi_arburst
      .s_axi_arlock(s_axi_arlock),    // input wire s_axi_arlock
      .s_axi_arcache(m_axi_mm2s_arcache),  // input wire [3 : 0] s_axi_arcache
      .s_axi_arprot(m_axi_mm2s_arprot),    // input wire [2 : 0] s_axi_arprot
      .s_axi_arvalid(m_axi_mm2s_arvalid),  // input wire s_axi_arvalid
      .s_axi_arready(m_axi_mm2s_arready),  // output wire s_axi_arready
      .s_axi_rid(s_axi_rid),          // output wire [3 : 0] s_axi_rid
      .s_axi_rdata(m_axi_mm2s_rdata),      // output wire [31 : 0] s_axi_rdata
      .s_axi_rresp(m_axi_mm2s_rresp),      // output wire [1 : 0] s_axi_rresp
      .s_axi_rlast(m_axi_mm2s_rlast),      // output wire s_axi_rlast
      .s_axi_rvalid(m_axi_mm2s_rvalid),    // output wire s_axi_rvalid
      .s_axi_rready(m_axi_mm2s_rready)    // input wire s_axi_rready
    );

    axi_waveform_datamover axi_waveform_datamover_inst (
      .m_axi_mm2s_aclk(m_axi_mm2s_aclk),                        // input wire m_axi_mm2s_aclk
      .m_axi_mm2s_aresetn(m_axi_mm2s_aresetn),                  // input wire m_axi_mm2s_aresetn
      .mm2s_err(mm2s_err),                                      // output wire mm2s_err
      .m_axis_mm2s_cmdsts_aclk(m_axis_mm2s_cmdsts_aclk),        // input wire m_axis_mm2s_cmdsts_aclk
      .m_axis_mm2s_cmdsts_aresetn(m_axis_mm2s_cmdsts_aresetn),  // input wire m_axis_mm2s_cmdsts_aresetn
      .s_axis_mm2s_cmd_tvalid(s_axis_mm2s_cmd_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
      .s_axis_mm2s_cmd_tready(s_axis_mm2s_cmd_tready),          // output wire s_axis_mm2s_cmd_tready
      .s_axis_mm2s_cmd_tdata(s_axis_mm2s_cmd_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata
      .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
      .m_axis_mm2s_sts_tready(m_axis_mm2s_sts_tready),          // input wire m_axis_mm2s_sts_tready
      .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
      .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
      .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),            // output wire m_axis_mm2s_sts_tlast
      .m_axi_mm2s_arid(m_axi_mm2s_arid),                        // output wire [3 : 0] m_axi_mm2s_arid
      .m_axi_mm2s_araddr(m_axi_mm2s_araddr),                    // output wire [31 : 0] m_axi_mm2s_araddr
      .m_axi_mm2s_arlen(m_axi_mm2s_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
      .m_axi_mm2s_arsize(m_axi_mm2s_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
      .m_axi_mm2s_arburst(m_axi_mm2s_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
      .m_axi_mm2s_arprot(m_axi_mm2s_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
      .m_axi_mm2s_arcache(m_axi_mm2s_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
      .m_axi_mm2s_aruser(m_axi_mm2s_aruser),                    // output wire [3 : 0] m_axi_mm2s_aruser
      .m_axi_mm2s_arvalid(m_axi_mm2s_arvalid),                  // output wire m_axi_mm2s_arvalid
      .m_axi_mm2s_arready(m_axi_mm2s_arready),                  // input wire m_axi_mm2s_arready
      .m_axi_mm2s_rdata(m_axi_mm2s_rdata),                      // input wire [31 : 0] m_axi_mm2s_rdata
      .m_axi_mm2s_rresp(m_axi_mm2s_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
      .m_axi_mm2s_rlast(m_axi_mm2s_rlast),                      // input wire m_axi_mm2s_rlast
      .m_axi_mm2s_rvalid(m_axi_mm2s_rvalid),                    // input wire m_axi_mm2s_rvalid
      .m_axi_mm2s_rready(m_axi_mm2s_rready),                    // output wire m_axi_mm2s_rready
      .m_axis_mm2s_tdata(m_axis_mm2s_tdata),                    // output wire [31 : 0] m_axis_mm2s_tdata
      .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),                    // output wire [3 : 0] m_axis_mm2s_tkeep
      .m_axis_mm2s_tlast(m_axis_mm2s_tlast),                    // output wire m_axis_mm2s_tlast
      .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),                  // output wire m_axis_mm2s_tvalid
      .m_axis_mm2s_tready(m_axis_mm2s_tready),                  // input wire m_axis_mm2s_tready
      .m_axi_s2mm_aclk(m_axi_s2mm_aclk),                        // input wire m_axi_s2mm_aclk
      .m_axi_s2mm_aresetn(m_axi_s2mm_aresetn),                  // input wire m_axi_s2mm_aresetn
      .s2mm_err(s2mm_err),                                      // output wire s2mm_err
      .m_axis_s2mm_cmdsts_awclk(m_axis_s2mm_cmdsts_awclk),      // input wire m_axis_s2mm_cmdsts_awclk
      .m_axis_s2mm_cmdsts_aresetn(m_axis_s2mm_cmdsts_aresetn),  // input wire m_axis_s2mm_cmdsts_aresetn
      .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
      .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready),          // output wire s_axis_s2mm_cmd_tready
      .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata
      .m_axis_s2mm_sts_tvalid(m_axis_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
      .m_axis_s2mm_sts_tready(m_axis_s2mm_sts_tready),          // input wire m_axis_s2mm_sts_tready
      .m_axis_s2mm_sts_tdata(m_axis_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
      .m_axis_s2mm_sts_tkeep(m_axis_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
      .m_axis_s2mm_sts_tlast(m_axis_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast
      .m_axi_s2mm_awid(m_axi_s2mm_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
      .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr),                    // output wire [31 : 0] m_axi_s2mm_awaddr
      .m_axi_s2mm_awlen(m_axi_s2mm_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
      .m_axi_s2mm_awsize(m_axi_s2mm_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
      .m_axi_s2mm_awburst(m_axi_s2mm_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
      .m_axi_s2mm_awprot(m_axi_s2mm_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
      .m_axi_s2mm_awcache(m_axi_s2mm_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
      .m_axi_s2mm_awuser(m_axi_s2mm_awuser),                    // output wire [3 : 0] m_axi_s2mm_awuser
      .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid),                  // output wire m_axi_s2mm_awvalid
      .m_axi_s2mm_awready(m_axi_s2mm_awready),                  // input wire m_axi_s2mm_awready
      .m_axi_s2mm_wdata(m_axi_s2mm_wdata),                      // output wire [31 : 0] m_axi_s2mm_wdata
      .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb),                      // output wire [3 : 0] m_axi_s2mm_wstrb
      .m_axi_s2mm_wlast(m_axi_s2mm_wlast),                      // output wire m_axi_s2mm_wlast
      .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid),                    // output wire m_axi_s2mm_wvalid
      .m_axi_s2mm_wready(m_axi_s2mm_wready),                    // input wire m_axi_s2mm_wready
      .m_axi_s2mm_bresp(m_axi_s2mm_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
      .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid),                    // input wire m_axi_s2mm_bvalid
      .m_axi_s2mm_bready(m_axi_s2mm_bready),                    // output wire m_axi_s2mm_bready
      .s_axis_s2mm_tdata(s_axis_s2mm_tdata),                    // input wire [31 : 0] s_axis_s2mm_tdata
      .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),                    // input wire [3 : 0] s_axis_s2mm_tkeep
      .s_axis_s2mm_tlast(s_axis_s2mm_tlast),                    // input wire s_axis_s2mm_tlast
      .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),                  // input wire s_axis_s2mm_tvalid
      .s_axis_s2mm_tready(s_axis_s2mm_tready)                  // output wire s_axis_s2mm_tready
    );

endmodule
