//------------------------------------------------------------------------------
// File       : ethernet_rgmii_top.v
// Author     : Xilinx Inc.
// -----------------------------------------------------------------------------
// (c) Copyright 2004-2013 Xilinx, Inc. All rights reserved.
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
// -----------------------------------------------------------------------------
// Description:  This is the Verilog example design for the Tri-Mode
//               Ethernet MAC core. It is intended that this example design
//               can be quickly adapted and downloaded onto an FPGA to provide
//               a real hardware test environment.
//
//               This level:
//
//               * Instantiates the FIFO Block wrapper, containing the
//                 block level wrapper and an RX and TX FIFO with an
//                 AXI-S interface;
//
//               * Instantiates a simple AXI-S example design,
//                 providing an address swap and a simple
//                 loopback function;
//
//               * Instantiates transmitter clocking circuitry
//                   -the User side of the FIFOs are clocked at gtx_clk
//                    at all times
//
//               * Instantiates a state machine which drives the AXI Lite
//                 interface to bring the TEMAC up in the correct state
//
//               * Serializes the Statistics vectors to prevent logic being
//                 optimized out
//
//               * Ties unused inputs off to reduce the number of IO
//
//               Please refer to the Datasheet, Getting Started Guide, and
//               the Tri-Mode Ethernet MAC User Gude for further information.
//
//    --------------------------------------------------
//    | EXAMPLE DESIGN WRAPPER                         |
//    |                                                |
//    |                                                |
//    |   -------------------     -------------------  |
//    |   |                 |     |                 |  |
//    |   |    Clocking     |     |     Resets      |  |
//    |   |                 |     |                 |  |
//    |   -------------------     -------------------  |
//    |           -------------------------------------|
//    |           |FIFO BLOCK WRAPPER                  |
//    |           |                                    |
//    |           |                                    |
//    |           |              ----------------------|
//    |           |              | SUPPORT LEVEL       |
//    | --------  |              |                     |
//    | |      |  |              |                     |
//    | | AXI  |->|------------->|                     |
//    | | LITE |  |              |                     |
//    | |  SM  |  |              |                     |
//    | |      |<-|<-------------|                     |
//    | |      |  |              |                     |
//    | --------  |              |                     |
//    |           |              |                     |
//    | --------  |  ----------  |                     |
//    | |      |  |  |        |  |                     |
//    | |      |->|->|        |->|                     |
//    | | PAT  |  |  |        |  |                     |
//    | | GEN  |  |  |        |  |                     |
//    | |(ADDR |  |  |  AXI-S |  |                     |
//    | | SWAP)|  |  |  FIFO  |  |                     |
//    | |      |  |  |        |  |                     |
//    | |      |  |  |        |  |                     |
//    | |      |  |  |        |  |                     |
//    | |      |<-|<-|        |<-|                     |
//    | |      |  |  |        |  |                     |
//    | --------  |  ----------  |                     |
//    |           |              |                     |
//    |           |              ----------------------|
//    |           -------------------------------------|
//    --------------------------------------------------

//------------------------------------------------------

`timescale 1 ps/1 ps


//------------------------------------------------------------------------------
// The module declaration for the example_design level wrapper.
//------------------------------------------------------------------------------

(* DowngradeIPIdentifiedWarnings = "yes" *)
module ethernet_rgmii_top
   (
      // asynchronous reset
//      input         glbl_rst,
      input glbl_rst_intn,

      // 200MHz clock input from board
    //  input         clk_in_p,
    //  input         clk_in_n,
      // 125 MHz clock from MMCM
      input        gtx_clk_bufg,        // 125 MHz
      input        refclk_bufg,         // 200 MHz
      input         s_axi_aclk,         // 100 MHz
      input         dcm_locked,

    //  output        phy_resetn,

      output        rx_reset,
      output        tx_reset,


      input gtx_resetn,
      input s_axi_resetn,
      input chk_resetn,


      // RGMII Interface
      //----------------
      output [3:0]  rgmii_txd,
      output        rgmii_tx_ctl,
      output        rgmii_txc,
      input  [3:0]  rgmii_rxd,
      input         rgmii_rx_ctl,
      input         rgmii_rxc,

      // MDIO Interface
      //---------------
      inout         mdio,
      output        mdc,


      // Serialised statistics vectors
      //------------------------------
      output        tx_statistics_s,
      output        rx_statistics_s,

      // Serialised Pause interface controls
      //------------------------------------
      input         pause_req_s,

      // data from ADC Data fifo
       input       [7:0]                    adc_axis_tdata,
       input                                adc_axis_tvalid,
       input                                adc_axis_tlast,
       input                                adc_axis_tuser,
       output                               adc_axis_tready,

       // data from Peak Detector DSP
        input       [7:0]                    pk_axis_tdata,
        input                                pk_axis_tvalid,
        input                                pk_axis_tlast,
        input                                pk_axis_tuser,
        output                               pk_axis_tready,

       // Decoded Commands from RGMII RX fifo
       output     [31:0] cmd_axis_tdata,
       output           cmd_axis_tvalid,
       output           cmd_axis_tlast,
       output     [31:0]cmd_axis_tuser,
       output      [3:0] cmd_axis_tdest,
       output      [3:0] cmd_axis_tid,
       output      [3:0] cmd_axis_tkeep,
       input            cmd_axis_tready,

      // Main example design controls
      //-----------------------------
      input [7:0] ethernet_ctrl_bus,
      input         update_speed,
      //input         serial_command, // tied to pause_req_s
      input         config_board,
      output        serial_response,

      //input         reset_error,
      output        frame_error,
      output        frame_errorn,
      output        activity_flash,
      output        activity_flashn

    );

   //----------------------------------------------------------------------------
   // internal signals used in this top level wrapper.
   //----------------------------------------------------------------------------

   // example design clocks
   wire                 rx_mac_aclk;
   wire                 tx_mac_aclk;
   // resets (and reset generation)
   //wire                 s_axi_resetn;
   //wire                 chk_resetn;
   //wire                 gtx_resetn;
   //wire                 rx_reset;
   //wire                 tx_reset;

  // wire                 glbl_rst_intn;
  wire         enable_rx_decode;
  wire         enable_adc_pkt;
  wire         gen_tx_data;
  wire         chk_tx_data;
  wire  [1:0]  mac_speed;



   // USER side RX AXI-S interface
   wire                 rx_fifo_clock;
   wire                 rx_fifo_resetn;
   wire  [7:0]          rx_axis_fifo_tdata;
   wire                 rx_axis_fifo_tvalid;
   wire                 rx_axis_fifo_tlast;
   wire                 rx_axis_fifo_tready;

   // USER side TX AXI-S interface
   wire                 tx_fifo_clock;
   wire                 tx_fifo_resetn;
   wire  [7:0]          tx_axis_fifo_tdata;
   wire                 tx_axis_fifo_tvalid;
   wire                 tx_axis_fifo_tlast;
   wire                 tx_axis_fifo_tready;


   // RX Statistics serialisation signals
   wire                 rx_statistics_valid;
   reg                  rx_statistics_valid_reg;
   wire  [27:0]         rx_statistics_vector;
   reg   [27:0]         rx_stats;
   reg   [29:0]         rx_stats_shift;
   reg                  rx_stats_toggle = 0;
   wire                 rx_stats_toggle_sync;
   reg                  rx_stats_toggle_sync_reg = 0;

   // TX Statistics serialisation signals
   wire                 tx_statistics_valid;
   reg                  tx_statistics_valid_reg;
   wire  [31:0]         tx_statistics_vector;
   reg   [31:0]         tx_stats;
   reg   [33:0]         tx_stats_shift;
   reg                  tx_stats_toggle = 0;
   wire                 tx_stats_toggle_sync;
   reg                  tx_stats_toggle_sync_reg = 0;
   wire                 inband_link_status;
   wire  [1:0]          inband_clock_speed;
   wire                 inband_duplex_status;

   // Pause interface DESerialisation
   reg   [18:0]         pause_shift;
   reg                  pause_req;
   reg   [15:0]         pause_val;

   // AXI-Lite interface
   wire  [11:0]         s_axi_awaddr;
   wire                 s_axi_awvalid;
   wire                 s_axi_awready;
   wire  [31:0]         s_axi_wdata;
   wire                 s_axi_wvalid;
   wire                 s_axi_wready;
   wire  [1:0]          s_axi_bresp;
   wire                 s_axi_bvalid;
   wire                 s_axi_bready;
   wire  [11:0]         s_axi_araddr;
   wire                 s_axi_arvalid;
   wire                 s_axi_arready;
   wire  [31:0]         s_axi_rdata;
   wire  [1:0]          s_axi_rresp;
   wire                 s_axi_rvalid;
   wire                 s_axi_rready;

   wire [7:0] config_pkt_tdata;
   wire config_pkt_tvalid;
   wire config_pkt_tready;
   wire config_pkt_tlast;

  wire [7:0] data_pkt_tdata;
   wire data_pkt_tvalid;
   wire data_pkt_tready;
   wire data_pkt_tlast;

  wire [31 : 0] S00_FIFO_DATA_COUNT;
  wire [31 : 0] S01_FIFO_DATA_COUNT;
  wire M00_SPARSE_TKEEP_REMOVED;

   wire     [31:0]  cmd_pkt_axis_tdata;
   wire             cmd_pkt_axis_tvalid;
   wire             cmd_pkt_axis_tlast;
   wire             cmd_pkt_axis_tready;

    wire     [31:0]  cmd_axis_tdata_ila;
   wire  cmd_axis_tvalid_ila;
   wire  cmd_axis_tlast_ila;
   wire  cmd_axis_tready_ila;

   // set board defaults - only updated when reprogrammed
   reg                  enable_address_swap = 0;
   reg                  enable_phy_loopback = 0;

   // signal tie offs
   wire  [7:0]          tx_ifg_delay = 0;    // not used in this example

   assign enable_rx_decode = ethernet_ctrl_bus[5];
   assign enable_adc_pkt = ethernet_ctrl_bus[4];
   assign gen_tx_data = ethernet_ctrl_bus[3];
   assign chk_tx_data = ethernet_ctrl_bus[2];
   assign mac_speed = ethernet_ctrl_bus[1:0];

   assign frame_errorn = !frame_error;
   assign activity_flashn = !activity_flash;


  // when the config_board button is pushed capture and hold the
  // state of the gne/chek tx_data inputs.  These values will persist until the
  // board is reprogrammed or config_board is pushed again
  always @(posedge gtx_clk_bufg)
  begin
     if (config_board) begin
        enable_address_swap   <= gen_tx_data;
     end
  end

  always @(posedge s_axi_aclk)
  begin
     if (config_board) begin
        enable_phy_loopback   <= chk_tx_data;
     end
  end



  //----------------------------------------------------------------------------
  // Generate the user side clocks for the axi fifos
  //----------------------------------------------------------------------------
  assign tx_fifo_clock = gtx_clk_bufg;
  assign rx_fifo_clock = gtx_clk_bufg;


  //----------------------------------------------------------------------------
  // Generate resets required for the fifo side signals etc
  //----------------------------------------------------------------------------



   // generate the user side resets for the axi fifos
   assign tx_fifo_resetn = gtx_resetn;
   assign rx_fifo_resetn = gtx_resetn;

  //----------------------------------------------------------------------------
  // Serialize the stats vectors
  // This is a single bit approach, retimed onto gtx_clk
  // this code is only present to prevent code being stripped..
  //----------------------------------------------------------------------------

  // RX STATS

  // first capture the stats on the appropriate clock
  always @(posedge rx_mac_aclk)
  begin
     rx_statistics_valid_reg <= rx_statistics_valid;
     if (!rx_statistics_valid_reg & rx_statistics_valid) begin
        rx_stats <= rx_statistics_vector;
        rx_stats_toggle <= !rx_stats_toggle;
     end
  end

  ethernet_rgmii_sync_block rx_stats_sync (
     .clk              (gtx_clk_bufg),
     .data_in          (rx_stats_toggle),
     .data_out         (rx_stats_toggle_sync)
  );

  always @(posedge gtx_clk_bufg)
  begin
     rx_stats_toggle_sync_reg <= rx_stats_toggle_sync;
  end

  // when an update is rxd load shifter (plus start/stop bit)
  // shifter always runs (no power concerns as this is an example design)
  always @(posedge gtx_clk_bufg)
  begin
     if (rx_stats_toggle_sync_reg != rx_stats_toggle_sync) begin
        rx_stats_shift <= {1'b1, rx_stats, 1'b1};
     end
     else begin
        rx_stats_shift <= {rx_stats_shift[28:0], 1'b0};
     end
  end

  assign rx_statistics_s = rx_stats_shift[29];

  // TX STATS

  // first capture the stats on the appropriate clock
  always @(posedge tx_mac_aclk)
  begin
     tx_statistics_valid_reg <= tx_statistics_valid;
     if (!tx_statistics_valid_reg & tx_statistics_valid) begin
        tx_stats <= tx_statistics_vector;
        tx_stats_toggle <= !tx_stats_toggle;
     end
  end

  ethernet_rgmii_sync_block tx_stats_sync (
     .clk              (gtx_clk_bufg),
     .data_in          (tx_stats_toggle),
     .data_out         (tx_stats_toggle_sync)
  );

  always @(posedge gtx_clk_bufg)
  begin
     tx_stats_toggle_sync_reg <= tx_stats_toggle_sync;
  end

  // when an update is txd load shifter (plus start bit)
  // shifter always runs (no power concerns as this is an example design)
  always @(posedge gtx_clk_bufg)
  begin
     if (tx_stats_toggle_sync_reg != tx_stats_toggle_sync) begin
        tx_stats_shift <= {1'b1, tx_stats, 1'b1};
     end
     else begin
        tx_stats_shift <= {tx_stats_shift[32:0], 1'b0};
     end
  end

  assign tx_statistics_s = tx_stats_shift[33];

  //----------------------------------------------------------------------------
  // DSerialize the Pause interface
  // This is a single bit approachtimed on gtx_clk
  // this code is only present to prevent code being stripped..
  //----------------------------------------------------------------------------
  // the serialised pause info has a start bit followed by the quanta and a stop bit
  // capture the quanta when the start bit hits the msb and the stop bit is in the lsb
  always @(posedge gtx_clk_bufg)
  begin
     pause_shift <= {pause_shift[17:0], pause_req_s};
  end

  always @(posedge gtx_clk_bufg)
  begin
     if (pause_shift[18] == 1'b0 & pause_shift[17] == 1'b1 & pause_shift[0] == 1'b1) begin
        pause_req <= 1'b1;
        pause_val <= pause_shift[16:1];
     end
     else begin
        pause_req <= 1'b0;
        pause_val <= 0;
     end
  end

  //----------------------------------------------------------------------------
  // Instantiate the AXI-LITE Controller
  //----------------------------------------------------------------------------

   ethernet_rgmii_axi_lite_sm axi_lite_controller (
      .s_axi_aclk                   (s_axi_aclk),
      .s_axi_resetn                 (s_axi_resetn),

      .mac_speed                    (mac_speed),
      .update_speed                 (update_speed),   // may need glitch protection on this..
      .serial_command               (pause_req_s),
      .serial_response              (serial_response),
      .phy_loopback                 (enable_phy_loopback),

      .s_axi_awaddr                 (s_axi_awaddr),
      .s_axi_awvalid                (s_axi_awvalid),
      .s_axi_awready                (s_axi_awready),

      .s_axi_wdata                  (s_axi_wdata),
      .s_axi_wvalid                 (s_axi_wvalid),
      .s_axi_wready                 (s_axi_wready),

      .s_axi_bresp                  (s_axi_bresp),
      .s_axi_bvalid                 (s_axi_bvalid),
      .s_axi_bready                 (s_axi_bready),

      .s_axi_araddr                 (s_axi_araddr),
      .s_axi_arvalid                (s_axi_arvalid),
      .s_axi_arready                (s_axi_arready),

      .s_axi_rdata                  (s_axi_rdata),
      .s_axi_rresp                  (s_axi_rresp),
      .s_axi_rvalid                 (s_axi_rvalid),
      .s_axi_rready                 (s_axi_rready)
   );

  //----------------------------------------------------------------------------
  // Instantiate the TRIMAC core fifo block wrapper
  //----------------------------------------------------------------------------
  ethernet_rgmii_fifo_block trimac_fifo_block (
      .gtx_clk                      (gtx_clk_bufg),
      // asynchronous reset
      .glbl_rstn                    (glbl_rst_intn),
      .rx_axi_rstn                  (1'b1),
      .tx_axi_rstn                  (1'b1),

      // Reference clock for IDELAYCTRL's
      .refclk                       (refclk_bufg),

      // Receiver Statistics Interface
      //---------------------------------------
      .rx_mac_aclk                  (rx_mac_aclk),
      .rx_reset                     (rx_reset),
      .rx_statistics_vector         (rx_statistics_vector),
      .rx_statistics_valid          (rx_statistics_valid),

      // Receiver (AXI-S) Interface
      //----------------------------------------
      .rx_fifo_clock                (rx_fifo_clock),
      .rx_fifo_resetn               (rx_fifo_resetn),
      .rx_axis_fifo_tdata           (rx_axis_fifo_tdata),
      .rx_axis_fifo_tvalid          (rx_axis_fifo_tvalid),
      .rx_axis_fifo_tready          (rx_axis_fifo_tready),
      .rx_axis_fifo_tlast           (rx_axis_fifo_tlast),
      // Transmitter Statistics Interface
      //------------------------------------------
      .tx_mac_aclk                  (tx_mac_aclk),
      .tx_reset                     (tx_reset),
      .tx_ifg_delay                 (tx_ifg_delay),
      .tx_statistics_vector         (tx_statistics_vector),
      .tx_statistics_valid          (tx_statistics_valid),

      // Transmitter (AXI-S) Interface
      //-------------------------------------------
      .tx_fifo_clock                (tx_fifo_clock),
      .tx_fifo_resetn               (tx_fifo_resetn),
      .tx_axis_fifo_tdata           (tx_axis_fifo_tdata),
      .tx_axis_fifo_tvalid          (tx_axis_fifo_tvalid),
      .tx_axis_fifo_tready          (tx_axis_fifo_tready),
      .tx_axis_fifo_tlast           (tx_axis_fifo_tlast),


      // MAC Control Interface
      //------------------------
      .pause_req                    (pause_req),
      .pause_val                    (pause_val),

      // RGMII Interface
      //------------------
      .rgmii_txd                    (rgmii_txd),
      .rgmii_tx_ctl                 (rgmii_tx_ctl),
      .rgmii_txc                    (rgmii_txc),
      .rgmii_rxd                    (rgmii_rxd),
      .rgmii_rx_ctl                 (rgmii_rx_ctl),
      .rgmii_rxc                    (rgmii_rxc),

      // RGMII Inband Status Registers
      //--------------------------------
      .inband_link_status           (inband_link_status),
      .inband_clock_speed           (inband_clock_speed),
      .inband_duplex_status         (inband_duplex_status),

      // MDIO Interface
      //-----------------
      .mdio                         (mdio),
      .mdc                          (mdc),

      // AXI-Lite Interface
      //---------------
      .s_axi_aclk                   (s_axi_aclk),
      .s_axi_resetn                 (s_axi_resetn),

      .s_axi_awaddr                 (s_axi_awaddr),
      .s_axi_awvalid                (s_axi_awvalid),
      .s_axi_awready                (s_axi_awready),

      .s_axi_wdata                  (s_axi_wdata),
      .s_axi_wvalid                 (s_axi_wvalid),
      .s_axi_wready                 (s_axi_wready),

      .s_axi_bresp                  (s_axi_bresp),
      .s_axi_bvalid                 (s_axi_bvalid),
      .s_axi_bready                 (s_axi_bready),

      .s_axi_araddr                 (s_axi_araddr),
      .s_axi_arvalid                (s_axi_arvalid),
      .s_axi_arready                (s_axi_arready),

      .s_axi_rdata                  (s_axi_rdata),
      .s_axi_rresp                  (s_axi_rresp),
      .s_axi_rvalid                 (s_axi_rvalid),
      .s_axi_rready                 (s_axi_rready)

   );


  //----------------------------------------------------------------------------
  //  Instantiate the address swapping module and simple pattern generator
  //----------------------------------------------------------------------------
   ethernet_rgmii_packet_gen packet_gen_inst (
      .axi_tclk                     (tx_fifo_clock),
      .axi_tresetn                  (tx_fifo_resetn),
      .check_resetn                 (chk_resetn),

      .enable_pat_gen               (gen_tx_data),
      .enable_pat_chk               (chk_tx_data),
      .enable_address_swap          (enable_address_swap),
      .speed                        (mac_speed),

//      .rx_axis_tdata                (rx_axis_fifo_tdata),
//      .rx_axis_tvalid               (rx_axis_fifo_tvalid),
//      .rx_axis_tlast                (rx_axis_fifo_tlast),
//      .rx_axis_tuser                (1'b0), // the FIFO drops all bad frames
//      .rx_axis_tready               (rx_axis_fifo_tready),
        .rx_axis_tdata                ('b0),
        .rx_axis_tvalid               ('b0),
        .rx_axis_tlast                ('b0),
        .rx_axis_tuser                (1'b0), // the FIFO drops all bad frames
        .rx_axis_tready               (),

//      .tx_axis_tdata                (tx_axis_fifo_tdata),
//      .tx_axis_tvalid               (tx_axis_fifo_tvalid),
//      .tx_axis_tlast                (tx_axis_fifo_tlast),
//      .tx_axis_tready               (tx_axis_fifo_tready),

      .tx_axis_tdata                (data_pkt_tdata),
      .tx_axis_tvalid               (data_pkt_tvalid),
      .tx_axis_tlast                (data_pkt_tlast),
      .tx_axis_tready               (data_pkt_tready),

      .enable_adc_pkt            (enable_adc_pkt),
      .adc_axis_tdata           (adc_axis_tdata),
      .adc_axis_tvalid          (adc_axis_tvalid),
      .adc_axis_tlast           (adc_axis_tlast),
      .adc_axis_tuser           (adc_axis_tuser),
      .adc_axis_tready          (adc_axis_tready),

      .frame_error                  (frame_error),
      .activity_flash               (activity_flash)
   );

   ethernet_rgmii_axi_rx_decoder #(
     //   parameter                            DEST_ADDR       = 48'hda0102030405,
        .DEST_ADDR       (48'h985aebdb066f),
        .SRC_ADDR        (48'h5a0102030405),
        .MAX_SIZE        (16'd532),
     //   parameter                            MIN_SIZE        = 16'd64,
       .MIN_SIZE         (16'd532),
       .ENABLE_VLAN      (1'b0),
       .VLAN_ID          (12'd2),
       .VLAN_PRIORITY    (3'd2)
    ) rx_cmd_decoder_inst (
        .axi_tclk (rx_fifo_clock),
        .axi_tresetn (rx_fifo_resetn),

        .enable_rx_decode        (enable_rx_decode),
        .speed                  (mac_speed),

      // data from the RX data path
        .rx_axis_tdata       (rx_axis_fifo_tdata),
        .rx_axis_tvalid       (rx_axis_fifo_tvalid),
        .rx_axis_tlast       (rx_axis_fifo_tlast),
        .rx_axis_tready      (rx_axis_fifo_tready),

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
          .tuser       (cmd_axis_tuser),
          .tdest       (cmd_axis_tdest),
          .tid        (cmd_axis_tid),
          .tkeep       (cmd_axis_tkeep),
          .tready      (cmd_axis_tready)
    );


   ethernet_rgmii_axi_packetizer #(
       .DEST_ADDR                 (48'h985aebdb066f),
       .SRC_ADDR                  (48'h5a0102030405),
       .MAX_SIZE                  (32'd84),
       .MIN_SIZE                  (32'd84),
       .ENABLE_VLAN               (0),
       .VLAN_ID                   (12'd2),
       .VLAN_PRIORITY             (3'd2)
    ) config_packetizer_inst (
      //  .axi_tclk                  (axi_tclk),
      //  .axi_tresetn               (axi_tresetn),
       .axi_tclk                  (tx_fifo_clock),
       .axi_tresetn               (tx_fifo_resetn),
       .enable_adc_pkt            (1'b1),
       .speed                     (mac_speed),

        // data from ADC Data fifo
        .adc_axis_tdata           (pk_axis_tdata),
        .adc_axis_tvalid          (pk_axis_tvalid),
        .adc_axis_tlast           (pk_axis_tlast),
        .adc_axis_tuser           (pk_axis_tuser),
        .adc_axis_tready          (pk_axis_tready),

       .tdata                     (config_pkt_tdata),
       .tvalid                    (config_pkt_tvalid),
       .tlast                     (config_pkt_tlast),
       .tready                    (config_pkt_tready)
    );

    ethernet_tx_axis_interconnect ethernet_tx_axis_interconnect_inst (
      .ACLK(tx_fifo_clock),                                          // input wire ACLK
      .ARESETN(tx_fifo_resetn),                                    // input wire ARESETN
      .S00_AXIS_ACLK(tx_fifo_clock),                        // input wire S00_AXIS_ACLK
      .S01_AXIS_ACLK(tx_fifo_clock),                        // input wire S01_AXIS_ACLK
      .S00_AXIS_ARESETN(tx_fifo_resetn),                  // input wire S00_AXIS_ARESETN
      .S01_AXIS_ARESETN(tx_fifo_resetn),                  // input wire S01_AXIS_ARESETN
      .S00_AXIS_TVALID(data_pkt_tvalid),                    // input wire S00_AXIS_TVALID
      .S01_AXIS_TVALID(config_pkt_tvalid),                    // input wire S01_AXIS_TVALID
      .S00_AXIS_TREADY(data_pkt_tready),                    // output wire S00_AXIS_TREADY
      .S01_AXIS_TREADY(config_pkt_tready),                    // output wire S01_AXIS_TREADY
      .S00_AXIS_TDATA(data_pkt_tdata),                      // input wire [7 : 0] S00_AXIS_TDATA
      .S01_AXIS_TDATA(config_pkt_tdata),                      // input wire [7 : 0] S01_AXIS_TDATA
      .S00_AXIS_TLAST(data_pkt_tlast),                      // input wire S00_AXIS_TLAST
      .S01_AXIS_TLAST(config_pkt_tlast),                      // input wire S01_AXIS_TLAST
      .M00_AXIS_ACLK(tx_fifo_clock),                        // input wire M00_AXIS_ACLK
      .M00_AXIS_ARESETN(tx_fifo_resetn),                  // input wire M00_AXIS_ARESETN
      .M00_AXIS_TVALID(tx_axis_fifo_tvalid),                    // output wire M00_AXIS_TVALID
      .M00_AXIS_TREADY(tx_axis_fifo_tready),                    // input wire M00_AXIS_TREADY
      .M00_AXIS_TDATA(tx_axis_fifo_tdata),                      // output wire [7 : 0] M00_AXIS_TDATA
      .M00_AXIS_TLAST(tx_axis_fifo_tlast),                      // output wire M00_AXIS_TLAST
      .S00_ARB_REQ_SUPPRESS(1'b0),                          // input wire S00_ARB_REQ_SUPPRESS
      .S01_ARB_REQ_SUPPRESS(1'b0),                          // input wire S01_ARB_REQ_SUPPRESS
      .S00_FIFO_DATA_COUNT(S00_FIFO_DATA_COUNT),            // output wire [31 : 0] S00_FIFO_DATA_COUNT
      .S01_FIFO_DATA_COUNT(S01_FIFO_DATA_COUNT),            // output wire [31 : 0] S01_FIFO_DATA_COUNT
      .M00_SPARSE_TKEEP_REMOVED(M00_SPARSE_TKEEP_REMOVED)  // output wire M00_SPARSE_TKEEP_REMOVED
    );


//decoder_ila decoder_ila_inst (
//    .clk  (rx_fifo_clock),
//    .probe0         (cmd_pkt_axis_tdata),
//    .probe1          (cmd_pkt_axis_tvalid),
//    .probe2           (cmd_pkt_axis_tlast),
//    .probe3           (cmd_pkt_axis_tready),
//    .probe4          (cmd_axis_tdata_ila),
//   .probe5                     (cmd_axis_tvalid_ila),
//   .probe6                    (cmd_axis_tlast_ila),
//   .probe7                     (cmd_axis_tready_ila),

//     .probe8         (rx_axis_fifo_tdata),
//     .probe9       (rx_axis_fifo_tvalid),
//     .probe10        (rx_axis_fifo_tlast),
//     .probe11       (rx_axis_fifo_tready)
//);

// assign cmd_axis_tdata_ila   =cmd_axis_tdata;
// assign  cmd_axis_tvalid_ila =cmd_axis_tvalid;
// assign  cmd_axis_tlast_ila  =cmd_axis_tlast;
// assign  cmd_axis_tready_ila  =cmd_axis_tready;

endmodule
