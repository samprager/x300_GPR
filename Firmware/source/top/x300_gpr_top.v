//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 04:32:51 PM
// Design Name:
// Module Name: x300_gpr_top
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
`timescale 1ps/1ps

module x300_gpr_top #
  (

   //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   parameter BEGIN_ADDRESS         = 32'h00000000,
   parameter END_ADDRESS           = 32'h00ffffff,

   parameter PRBS_EADDR_MASK_POS   = 32'hff000000,
   parameter ENFORCE_RD_WR         = 0,
   parameter ENFORCE_RD_WR_CMD     = 8'h11,
   parameter ENFORCE_RD_WR_PATTERN = 3'b000,
   parameter C_EN_WRAP_TRANS       = 0,
   parameter C_AXI_NBURST_TEST     = 0

   )
  (
// Memory interface ports
    // Inouts
    inout [63:0]                         ddr3_dq,
    inout [7:0]                        ddr3_dqs_n,
    inout [7:0]                        ddr3_dqs_p,

    // Outputs
    output [13:0]                       ddr3_addr,
    output [2:0]                        ddr3_ba,
    output                                       ddr3_ras_n,
    output                                       ddr3_cas_n,
    output                                       ddr3_we_n,
    output                                       ddr3_reset_n,
    output [0:0]                        ddr3_ck_p,
    output [0:0]                        ddr3_ck_n,
    output [0:0]                       ddr3_cke,
    output [0:0]                        ddr3_cs_n,
    output [7:0]                        ddr3_dm,
    output [0:0]                       ddr3_odt,

    // Inputs

    // Differential system clocks
  //  input                                        ddr3_clk1_p,
  //  input                                        ddr3_clk1_n,
    //  output                                       tg_compare_error,
    // output                                       init_calib_complete,

    //  input                                        cpu_reset,



    // --x300 Resources - from fmc150 example design
    input cpu_reset,       // : in    std_logic; -- CPU RST button, SW7 on KC705
    input sysclk_p,        // : in    std_logic;
    input sysclk_n,        // : in    std_logic;
    output [7:0]  gpio_led,        // : out   std_logic_vector(7 downto 0);
    input [7:0]  gpio_dip_sw,   //   : in    std_logic_vector(7 downto 0);

    output gpio_led_c,        //       : out   std_logic;
    output gpio_led_e,        //       : out   std_logic;
    output gpio_led_n,       //       : out   std_logic;
    output gpio_led_s,        //       : out   std_logic;
    output gpio_led_w,        //              : out   std_logic;
    input gpio_sw_c,        //               : in    std_logic;
    input gpio_sw_e,        //               : in    std_logic;
    input gpio_sw_n,        //               : in    std_logic;
    input gpio_sw_s,        //               : in    std_logic;
    input gpio_sw_w,        //               : in    std_logic;

    // --Clock/Data connection to ADC on FMC150 (ADS62P49)
    input clk_ab_p,        //                : in    std_logic;
    input clk_ab_n,        //                : in    std_logic;
    input[6:0] cha_p,        //                   : in    std_logic_vector(6 downto 0);
    input[6:0] cha_n,        //                   : in    std_logic_vector(6 downto 0);
    input[6:0] chb_p,        //                   : in    std_logic_vector(6 downto 0);
    input[6:0] chb_n,        //                   : in    std_logic_vector(6 downto 0);

    //  --Clock/Data connection to DAC on FMC150 (DAC3283)
    output dac_dclk_p,        //              : out   std_logic;
    output dac_dclk_n,        //              : out   std_logic;
    output[7:0] dac_data_p,        //              : out   std_logic_vector(7 downto 0);
    output[7:0] dac_data_n,        //              : out   std_logic_vector(7 downto 0);
    output dac_frame_p,        //             : out   std_logic;
    output dac_frame_n,        //             : out   std_logic;
    output txenable,        //                : out   std_logic;

    // --Clock/Trigger connection to FMC150
    // --clk_to_fpga_p    : in    std_logic;
    // --clk_to_fpga_n    : in    std_logic;
    // --ext_trigger_p    : in    std_logic;
    // --ext_trigger_n    : in    std_logic;

    //  --Serial Peripheral Interface (SPI)
    output spi_sclk,        //                : out   std_logic; -- Shared SPI clock line
    output spi_sdata,        //               : out   std_logic; -- Shared SPI sata line

    //  -- ADC specific signals
    output adc_n_en,        //                : out   std_logic; -- SPI chip select
    input adc_sdo,        //                 : in    std_logic; -- SPI data out
    output adc_reset,        //               : out   std_logic; -- SPI reset

    // -- CDCE specific signals
    output cdce_n_en,        //               : out   std_logic; -- SPI chip select
    input cdce_sdo,        //                : in    std_logic; -- SPI data out
    output cdce_n_reset,        //            : out   std_logic;
    output cdce_n_pd,        //               : out   std_logic;
    output ref_en,        //                  : out   std_logic;
    input pll_status,        //             : in    std_logic;

    //  -- DAC specific signals
    output dac_n_en,        //                : out   std_logic; -- SPI chip select
    input dac_sdo,        //                 : in    std_logic; -- SPI data out

    //  -- Monitoring specific signals
    output mon_n_en,        //                : out   std_logic; -- SPI chip select
    input mon_sdo,        //                 : in    std_logic; -- SPI data out
    output mon_n_reset,        //             : out   std_logic;
    input mon_n_int,        //               : in    std_logic;

    // --FMC Present status
    input prsnt_m2c_l,        //             : in    std_logic


    // System reset - Default polarity of sys_rst pin is Active Low.
    // System reset polarity will change based on the option
    // selected in GUI.

    // Ethernet RGMII Interface I/)
    // asynchronous reset
  //  input         glbl_rst,

    // 200MHz clock input from board
  //  input         clk_in_p,
  //  input         clk_in_n,
    // 125 MHz clock from MMCM
    output        gtx_clk_bufg_out,

    output        phy_resetn,

    // Serialised statistics vectors
    //------------------------------
    output        tx_statistics_s,  // output conflicts with adc serial pin ak25 - moved to hpc c30
    output        rx_statistics_s,  // output conflicts with adc serial pin ae25 - moved to hp g27
    output        serial_response,  // output conflicts with adc serial pin aj24 - moded to hpc d29



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
    output        mdc

    );

function integer clogb2 (input integer size);
    begin
      size = size - 1;
      for (clogb2=1; size>1; clogb2=clogb2+1)
        size = size >> 1;
    end
  endfunction // clogb2

  function integer STR_TO_INT;
    input [7:0] in;
    begin
      if(in == "8")
        STR_TO_INT = 8;
      else if(in == "4")
        STR_TO_INT = 4;
      else
        STR_TO_INT = 0;
    end
  endfunction


  localparam MIG_AXI_DATA_WIDTH = 512;

// Virtual Fifo Read Channel (axi-4 mm to axis) prog full thresholds
// Depends on 1m2s axis-interconnect FIFO depth and channel weight (AR) for each master channel
// Must ensure that space available in fifo is >= 2*AR*vfifo burst size
  localparam FIFO_M00_DEPTH = 16;//256;                     //data words
  localparam FIFO_M01_DEPTH = 1024;                     //data words
  localparam FIFO_M00_WIDTH = 64;                        // bytes - determined by width of interconnect switch
  localparam FIFO_M01_WIDTH = 64;                        // bytes - determined by width of interconnect switch
  localparam VFIFO_CH0_AR_WEIGHT = 4;
  localparam VFIFO_CH1_AR_WEIGHT = 8;
  localparam VFIFO_BURST_SIZE = 1024;                   // bytes
  localparam VFIFO_CH0_AR_BURST = VFIFO_CH0_AR_WEIGHT*VFIFO_BURST_SIZE;
  localparam VFIFO_CH1_AR_BURST = VFIFO_CH1_AR_WEIGHT*VFIFO_BURST_SIZE;
  // Space available in FIFO must be at least 2*AR_Burst before Programmable Full is deasserted
  localparam FIFO_M00_THRESHOLD = FIFO_M00_DEPTH - (2*VFIFO_CH0_AR_BURST)/FIFO_M00_WIDTH;
  localparam FIFO_M01_THRESHOLD = FIFO_M01_DEPTH - (2*VFIFO_CH1_AR_BURST)/FIFO_M01_WIDTH;

// TODO: once weights and widths are finalize, replace int comparison with binary comparison:
// for M00: (AR = 4, Burst = 1024 Bytes, Depth = 256, Width = 64 Bytes)
//          thresh = 16 KB - 2*4 KB = 8 KB
//      ->  count <=  128
//      or  prog_full = |counter[31:7]
// for M01: (AR = 8, Burst = 1024 Bytes, Depth = 1024, Width = 64 Bytes)
//          thresh = 64 KB - 2*8 KB = 48 KB
//      ->  count <=  768
//      or  prog_full =  (|counter[31:10]) || (&counter[9:8])

  localparam ADC_AXI_DATA_WIDTH = 512;//64;
  localparam ADC_AXI_TID_WIDTH = 1;
  localparam ADC_AXI_TDEST_WIDTH = 1;
  localparam ADC_AXI_TUSER_WIDTH = 1;
  localparam ADC_AXI_STREAM_ID = 1'b0;
  localparam ADC_AXI_STREAM_DEST = 1'b1;

  localparam PK_AXI_DATA_WIDTH = 512;//64;
  localparam PK_AXI_TID_WIDTH = 1;
  localparam PK_AXI_TDEST_WIDTH = 1;
  localparam PK_AXI_TUSER_WIDTH = 1;
  localparam PK_AXI_STREAM_ID = 1'b0;
  localparam PK_AXI_STREAM_DEST = 1'b1;

  localparam RX_WR_CMD_DWIDTH = 224;
  localparam RX_RD_CMD_DWIDTH = 32;
  localparam RX_CMD_ID_WIDTH = 32;

  wire                          clk_245_76MHz;
  wire                          clk_245_rst;
//wire                          clk_491_52MHz;

  wire          fmc150_clk_100Mhz;
  wire          fmc150_clk_100Mhz_rst;

//////////////////////////////////////////
// DDR3 MIG Wires
//////////////////////////////////////////
// full bid and rid outputs from mig -- concatinated for input to vfifo
wire [3:0] s_axi_mig_bid;
wire [3:0] s_axi_mig_rid;

// MIG Application interface ports
wire ui_clk;
wire ui_clk_sync_rst;
wire                              mmcm_locked;
reg                               aresetn;
//wire                              app_sr_req;
//wire                              app_ref_req;
//wire                              app_zq_req;
wire                              app_sr_active;
wire                              app_ref_ack;
wire                              app_zq_ack;

wire                                      tg_compare_error;
wire                                    init_calib_complete;

// DDR3 Debug Ports
wire [119:0]                            ddr3_ila_basic_w;
reg  [119:0]                            ddr3_ila_basic;
wire [390:0]                            ddr3_ila_wrpath_w;
reg  [390:0]                            ddr3_ila_wrpath;
wire [1023:0]                           ddr3_ila_rdpath_w;
reg  [1023:0]                           ddr3_ila_rdpath;
wire [13:0]                             ddr3_vio_sync_out;
wire [5:0]    dbg_pi_counter_read_val;
wire          dbg_sel_pi_incdec;
wire [8:0]    dbg_po_counter_read_val;
wire          dbg_sel_po_incdec;
wire [3:0]    dbg_byte_sel;
wire          dbg_pi_f_inc;
wire          dbg_pi_f_dec;
wire          dbg_po_f_inc;
wire          dbg_po_f_stg23_sel;
wire          dbg_po_f_dec;
(* mark_debug = "TRUE" *) wire [4:0]    dbg_dqs;
(* mark_debug = "TRUE" *) wire [8:0]    dbg_bit;

//////////////////////////////////////////
// Ethernet Controller wrapper signals
//////////////////////////////////////////
wire                 gtx_clk_bufg;
wire                 refclk_bufg;
wire                 sysclk_bufg;
wire                 clk250_bufg;
wire                 s_axi_aclk;
wire                 dcm_locked;

wire                 refclk_resetn;
wire                 sysclk_resetn;
wire                 clk250_resetn;

reg                  sysclk_reset;

wire [7:0]          adc_pkt_axis_tdata;
wire                adc_pkt_axis_tvalid;
wire                adc_pkt_axis_tlast;
wire                adc_pkt_axis_tuser;
wire                adc_pkt_axis_tready;
wire [0:0]          adc_pkt_axis_tstrb;
wire [0:0]          adc_pkt_axis_tkeep;
wire [0:0]          adc_pkt_axis_tid;
wire [0:0]          adc_pkt_axis_tdest;

wire        rx_reset;
wire        tx_reset;

wire glbl_rst_intn;
wire gtx_resetn;
wire s_axi_resetn;
wire chk_resetn;

// Serialised Pause interface controls
//------------------------------------
wire         pause_req_s;      //input gpio switch s

// Main example design controls
//-----------------------------
wire         update_speed;     //input gpio switch c
wire         config_board;     //input gpio switch w
wire         reset_error;      //input gpio switch n
wire        frame_error;      //output gpio led 0
wire        frame_errorn;      //output gpio led 1
wire        activity_flash;     //output gpio led 2
wire        activity_flashn;     //output gpio led 3

 // --ADC AXI-Stream Data Out Signals from fmc150_dac_adc module
wire [ADC_AXI_DATA_WIDTH-1:0]   axis_adc_tdata;
wire                            axis_adc_tvalid;
wire                            axis_adc_tlast;
wire [ADC_AXI_DATA_WIDTH/8-1:0] axis_adc_tkeep;
wire [ADC_AXI_TID_WIDTH-1:0]    axis_adc_tid;
wire [ADC_AXI_TDEST_WIDTH-1:0]  axis_adc_tdest;
wire [ADC_AXI_TUSER_WIDTH-1:0]  axis_adc_tuser;
wire                            axis_adc_tready;
wire [ADC_AXI_DATA_WIDTH/8-1:0] axis_adc_tstrb;

 // --ADC AXI-Stream Data Out Signals from fmc150_dac_adc module
wire [PK_AXI_DATA_WIDTH-1:0]   axis_pk_tdata;
wire                            axis_pk_tvalid;
wire                            axis_pk_tlast;
wire [PK_AXI_DATA_WIDTH/8-1:0] axis_pk_tkeep;
wire [PK_AXI_TID_WIDTH-1:0]    axis_pk_tid;
wire [PK_AXI_TDEST_WIDTH-1:0]  axis_pk_tdest;
wire [PK_AXI_TUSER_WIDTH-1:0]  axis_pk_tuser;
wire                            axis_pk_tready;
wire [PK_AXI_DATA_WIDTH/8-1:0] axis_pk_tstrb;

wire [7:0]                      pk_axis_tdata;
wire                            pk_axis_tvalid;
wire                            pk_axis_tlast;
wire                            pk_axis_tuser;
wire                            pk_axis_tready;

wire [7:0]                      dwout_axis_tdata;
wire                            dwout_axis_tvalid;
wire                            dwout_axis_tlast;
wire                            dwout_axis_tuser;
wire                            dwout_axis_tready;

// Control Module Signals
wire [3:0] fmc150_status_vector;
wire chirp_ready;          // continuous high when dac ready
wire chirp_active;         // continuous high while chirping
wire chirp_done;           // single pulse when chirp finished
wire chirp_init;          // single pulse to initiate chirp
wire chirp_enable;        // continuous high while chirp enabled
wire adc_enable;          // high while adc samples saved


wire [67:0] fmc150_spi_ctrl_bus_in;
wire [47:0] fmc150_spi_ctrl_bus_out;

wire [7:0] fmc150_ctrl_bus;
wire [7:0] fmc150_ctrl_bus_bypass;
//fmc150_ctrl_bus = {3'b0,ddc_duc_bypass,digital_mode,adc_out_dac_in,external_clock,gen_adc_test_pattern};

wire [7:0] ethernet_ctrl_bus;
wire [7:0] ethernet_ctrl_bus_bypass;
// ethernet_ctrl_bus = {3'b0,enable_adc_pkt,gen_tx_data,chk_tx_data,mac_speed};

wire [127:0] chirp_parameters;
// chirp_parameters = {chirp_control_word,chirp_freq_offset,chirp_tuning_word_coeff,chirp_count_max};


wire [31:0]   cmd_pkt_s_axis_tdata;
wire          cmd_pkt_s_axis_tvalid;
wire          cmd_pkt_s_axis_tlast;
wire          cmd_pkt_s_axis_tready;
wire   [31:0] cmd_pkt_s_axis_tuser;
wire    [3:0] cmd_pkt_s_axis_tdest;
wire    [3:0] cmd_pkt_s_axis_tid;
wire    [3:0] cmd_pkt_s_axis_tkeep;


//////////////////////////////////////////
// 1m4s CMD AXIS Interconnect Wires
//////////////////////////////////////////

//`include "../../source/include/rx_cmd_1s4m_ic.v"
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tdata;
wire                            ch_wr_cmd_axis_tvalid;
wire                            ch_wr_cmd_axis_tlast;
wire                            ch_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]   ch_wr_cmd_axis_tkeep;
wire [3:0]                      ch_wr_cmd_axis_tdest;
wire [3:0]                      ch_wr_cmd_axis_tid;

wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_wr_cmd_axis_tdata;
wire                            sp_wr_cmd_axis_tvalid;
wire                            sp_wr_cmd_axis_tlast;
wire                            sp_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_wr_cmd_axis_tkeep;
wire [3:0]                      sp_wr_cmd_axis_tdest;
wire [3:0]                      sp_wr_cmd_axis_tid;

//////////////////////////////////////////
// Waveform Data from Network  wires
//////////////////////////////////////////

wire [31:0]                     wfrm_wr_data_axis_tdata;
wire                            wfrm_wr_data_axis_tvalid;
wire                            wfrm_wr_data_axis_tlast;
wire                            wfrm_wr_data_axis_tready;
wire [31:0]                     wfrm_wr_data_axis_tuser;
wire [3:0]                      wfrm_wr_data_axis_tkeep;
wire [3:0]                      wfrm_wr_data_axis_tdest;
wire [3:0]                      wfrm_wr_data_axis_tid;

wire       [31:0]                    wfin_axis_tdata;
wire                                 wfin_axis_tvalid;
wire                                 wfin_axis_tlast;
wire       [31:0]                    wfin_axis_tuser;
wire       [3:0]                    wfin_axis_tkeep;
wire       [3:0]                    wfin_axis_tdest;
wire       [3:0]                    wfin_axis_tid;
wire                                wfin_axis_tready;

wire       [31:0]                    wfout_axis_tdata;
wire                                 wfout_axis_tvalid;
wire                                 wfout_axis_tlast;
wire       [3:0]                     wfout_axis_tkeep;
wire                                wfout_axis_tready;

wire [127:0] waveform_parameters;
wire init_wf_write;
wire wf_write_ready;
wire wf_read_ready;


wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_rd_cmd_axis_tdata;
wire                            ch_rd_cmd_axis_tvalid;
wire                            ch_rd_cmd_axis_tlast;
wire                            ch_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    ch_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  ch_rd_cmd_axis_tkeep;
wire [3:0]                      ch_rd_cmd_axis_tdest;
wire [3:0]                      ch_rd_cmd_axis_tid;

wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_rd_cmd_axis_tdata;
wire                            sp_rd_cmd_axis_tvalid;
wire                            sp_rd_cmd_axis_tlast;
wire                            sp_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_rd_cmd_axis_tkeep;
wire [3:0]                      sp_rd_cmd_axis_tdest;
wire [3:0]                      sp_rd_cmd_axis_tid;


wire S00_CMD_DECODE_ERR;           // output wire S00_DECODE_ERR
wire [31:0] S00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] S00_FIFO_DATA_COUNT
wire [31:0] M00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M00_FIFO_DATA_COUNT
wire [31:0] M01_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M01_FIFO_DATA_COUNT
wire [31:0] M02_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M02_FIFO_DATA_COUNT
wire [31:0] M03_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M03_FIFO_DATA_COUNT


//////////////////////////////////////////
// 1m2s AXIS Interconnect Unconnected wires
//////////////////////////////////////////
// S01 AXIS Connection to Ethernet RX Module
wire S01_AXIS_TVALID=   1'b0;
wire S01_AXIS_TREADY;
wire [7 : 0] S01_AXIS_TDATA = 'b0;
wire [0 : 0] S01_AXIS_TSTRB = 1'b0;
wire [0 : 0] S01_AXIS_TKEEP = 1'b0;
wire S01_AXIS_TLAST = 1'b0;
wire [0 : 0] S01_AXIS_TID = 1'b1;
wire [0 : 0] S01_AXIS_TDEST = 1'b0;

//Non-AXIS Signals
wire S00_ARB_REQ_SUPPRESS;
wire S01_ARB_REQ_SUPPRESS;
reg S00_ARB_REQ_SUPPRESS_Reg = 1'b0;
reg S01_ARB_REQ_SUPPRESS_Reg = 1'b1;
wire S00_DECODE_ERR;
wire S01_DECODE_ERR;
wire [31 : 0] S00_FIFO_DATA_COUNT;
wire [31 : 0] S01_FIFO_DATA_COUNT;

// 1s2m AXIS Interconnect Unconnected wires
//////////////////////////////////////////
// M00 AXIS Connection to DAC Module
wire M00_AXIS_TVALID;
wire M00_AXIS_TREADY = 1'b1;
wire [63 : 0] M00_AXIS_TDATA;
wire [7 : 0] M00_AXIS_TSTRB;
wire [7 : 0] M00_AXIS_TKEEP;
wire M00_AXIS_TLAST;
wire [0 : 0] M00_AXIS_TID;
wire [0 : 0] M00_AXIS_TDEST;
//Non-AXIS Signals
wire [31 : 0] M00_FIFO_DATA_COUNT;
wire [31 : 0] M01_FIFO_DATA_COUNT;
wire vfifo_S00_DECODE_ERR;

//////////////////////////////////////////
// Virtual Fifo Connected AXI-Stream wires
//////////////////////////////////////////
wire s_axis_vfifo_tvalid;
wire s_axis_vfifo_tready;
wire [MIG_AXI_DATA_WIDTH-1 : 0] s_axis_vfifo_tdata;
wire [MIG_AXI_DATA_WIDTH/8-1 : 0] s_axis_vfifo_tstrb;
wire [MIG_AXI_DATA_WIDTH/8-1 : 0] s_axis_vfifo_tkeep;
wire s_axis_vfifo_tlast;
wire [0 : 0] s_axis_vfifo_tid;
wire [0 : 0] s_axis_vfifo_tdest;

wire m_axis_vfifo_tvalid;
wire m_axis_vfifo_tready;
wire [MIG_AXI_DATA_WIDTH-1 : 0] m_axis_vfifo_tdata;
wire [MIG_AXI_DATA_WIDTH/8-1 : 0] m_axis_vfifo_tstrb;
wire [MIG_AXI_DATA_WIDTH/8-1 : 0] m_axis_vfifo_tkeep;
wire m_axis_vfifo_tlast;
wire [0 : 0] m_axis_vfifo_tid;
wire [0 : 0] m_axis_vfifo_tdest;

//Virtual Fifo AXI-4 Memory Mapped Wires
wire [0 : 0] m_axi_vfifo_awid;
wire [31 : 0] m_axi_vfifo_awaddr;
wire [7 : 0] m_axi_vfifo_awlen;
wire [2 : 0] m_axi_vfifo_awsize;
wire [1 : 0] m_axi_vfifo_awburst;
wire [0 : 0] m_axi_vfifo_awlock;
wire [3 : 0] m_axi_vfifo_awcache;
wire [2 : 0] m_axi_vfifo_awprot;
wire [3 : 0] m_axi_vfifo_awqos;
wire [3 : 0] m_axi_vfifo_awregion;
wire [0 : 0] m_axi_vfifo_awuser;
wire m_axi_vfifo_awvalid;
wire m_axi_vfifo_awready;
wire [MIG_AXI_DATA_WIDTH-1: 0] m_axi_vfifo_wdata;
wire [MIG_AXI_DATA_WIDTH/8-1: 0] m_axi_vfifo_wstrb;
wire m_axi_vfifo_wlast;
wire [0 : 0] m_axi_vfifo_wuser;
wire m_axi_vfifo_wvalid;
wire m_axi_vfifo_wready;
wire [0 : 0] m_axi_vfifo_bid;
wire [1 : 0] m_axi_vfifo_bresp;
wire [0 : 0] m_axi_vfifo_buser;
wire m_axi_vfifo_bvalid;
wire m_axi_vfifo_bready;
wire [0 : 0] m_axi_vfifo_arid;
wire [31 : 0] m_axi_vfifo_araddr;
wire [7 : 0] m_axi_vfifo_arlen;
wire [2 : 0] m_axi_vfifo_arsize;
wire [1 : 0] m_axi_vfifo_arburst;
wire [0 : 0] m_axi_vfifo_arlock;
wire [3 : 0] m_axi_vfifo_arcache;
wire [2 : 0] m_axi_vfifo_arprot;
wire [3 : 0] m_axi_vfifo_arqos;
wire [3 : 0] m_axi_vfifo_arregion;
wire [0 : 0] m_axi_vfifo_aruser;
wire m_axi_vfifo_arvalid;
wire m_axi_vfifo_arready;
wire [0 : 0] m_axi_vfifo_rid;
wire [MIG_AXI_DATA_WIDTH-1 : 0] m_axi_vfifo_rdata;
wire [1 : 0] m_axi_vfifo_rresp;
wire m_axi_vfifo_rlast;
wire [0 : 0] m_axi_vfifo_ruser;
wire m_axi_vfifo_rvalid;
wire m_axi_vfifo_rready;

wire [1 : 0] vfifo_mm2s_channel_full;        // input to vfifo
wire [1 : 0] vfifo_s2mm_channel_full;        // output from vfifo
wire [1 : 0] vfifo_mm2s_channel_empty;       // output from vfifo
wire [1 : 0] vfifo_idle;                     // output from vfifo

reg     vfifo_mm2s_ch0_full;
reg     vfifo_mm2s_ch1_full;

wire     vfifo_mm2s_ch1_full_sync;
reg     vfifo_mm2s_ch1_full_r;
reg     vfifo_mm2s_ch1_full_rr;
reg     vfifo_mm2s_ch1_full_gtxclk;
reg     vfifo_mm2s_ch1_full_gtxclk_r;
reg     vfifo_mm2s_ch1_full_gtxclk_rr;
reg     vfifo_mm2s_ch1_full_gtxclk_en = 0;
reg [1:0]     vfifo_mm2s_ch1_full_gtxclk_ctr = 2'b0;

// AXI Top Level DMA Signals
//wire dma_start;
//wire dma_done;
//wire dma_status;

//reg dma_start_r;

// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************


control_module #(
    .RX_WR_CMD_DWIDTH (RX_WR_CMD_DWIDTH),
    .RX_RD_CMD_DWIDTH (RX_RD_CMD_DWIDTH)
)control_module_inst(
  .s_axi_aclk   (s_axi_aclk),
  .s_axi_resetn  (s_axi_resetn),
// for future use

  // input                               eth_ctrl_en,
  // input [8:0]                         axis_eth_ctrl_tdata,
  // input [8:0]                         axis_eth_ctrl_tkeep,
  // input                               axis_eth_ctrl_tvalid,
  // output                              axis_eth_ctrl_tready,

  .gpio_dip_sw                         (gpio_dip_sw),
  .gpio_led                         (gpio_led),

//  input clk_mig,              // 200 MHZ OR 100 MHz
//  input mig_init_calib_complete,
  .clk_fmc150 (clk_245_76MHz),           // 245.76 MHz
  .resetn_fmc150(!clk_245_rst),

//input clk_mig,              // 200 MHZ OR 100 MHz
//input mig_init_calib_complete (init_calib_complete),
  .fmc150_status_vector (fmc150_status_vector), // {pll_status, mmcm_adac_locked, mmcm_locked, ADC_calibration_good};
  .chirp_ready (chirp_ready),
  .chirp_done (chirp_done),
  .chirp_active (chirp_active),
  .chirp_init  (chirp_init),
  .chirp_enable  (chirp_enable),
  .adc_enable   (adc_enable),

  .chirp_parameters                   (chirp_parameters),
  //chirp_parameters = {32'b0,chirp_freq_offset,chirp_tuning_word_coeff,chirp_count_max};

  // Decoded Commands from RGMII RX fifo
  .ch_wr_cmd_axis_tdata        (ch_wr_cmd_axis_tdata[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:RX_CMD_ID_WIDTH]),
  .ch_wr_cmd_axis_tvalid       (ch_wr_cmd_axis_tvalid),
  .ch_wr_cmd_axis_tlast        (ch_wr_cmd_axis_tlast),
  .ch_wr_cmd_axis_tkeep        (ch_wr_cmd_axis_tkeep[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:RX_CMD_ID_WIDTH/8]),
  .ch_wr_cmd_axis_tready       (ch_wr_cmd_axis_tready),

  // Decoded Commands from RGMII RX fifo
  .sp_wr_cmd_axis_tdata        (sp_wr_cmd_axis_tdata[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:RX_CMD_ID_WIDTH]),
  .sp_wr_cmd_axis_tvalid       (sp_wr_cmd_axis_tvalid),
  .sp_wr_cmd_axis_tlast        (sp_wr_cmd_axis_tlast),
  .sp_wr_cmd_axis_tkeep        (sp_wr_cmd_axis_tkeep[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:RX_CMD_ID_WIDTH/8]),
  .sp_wr_cmd_axis_tready       (sp_wr_cmd_axis_tready),

  .fmc150_spi_ctrl_bus_in (fmc150_spi_ctrl_bus_in),
  .fmc150_spi_ctrl_bus_out (fmc150_spi_ctrl_bus_out),
  //fmc150_ctrl_bus = {3'b0,ddc_duc_bypass,digital_mode,adc_out_dac_in,external_clock,gen_adc_test_pattern};
  .fmc150_ctrl_bus (fmc150_ctrl_bus),
  // output reg ddc_duc_bypass                         = 1'b1, // dip_sw(3)
  // output reg digital_mode                           = 1'b0,
  // output reg adc_out_dac_in                         = 1'b0,
  // output reg external_clock                         = 1'b0,
  // output reg gen_adc_test_pattern                   = 1'b0,
  // Ethernet Control Signals

  .gtx_clk_bufg (gtx_clk_bufg),
  .gtx_resetn       (gtx_resetn),
  .ethernet_ctrl_bus (ethernet_ctrl_bus)
  // output reg enable_rx_decode                         = 1'b1, //dip_sw(1)
  // output reg enable_adc_pkt                         = 1'b1, //dip_sw(1)
  // output reg gen_tx_data                            = 1'b0,
  // output reg chk_tx_data                            = 1'b0,
  // output reg [1:0] mac_speed                        = 2'b10 // {dip_sw(0),~dip_sw(0)}


);

assign ch_rd_cmd_axis_tready = 1;
assign sp_rd_cmd_axis_tready = 1;

rx_cmd_1s4m_axis_interconnect rx_cmd_1s4m_axis_interconnect_inst (
  .ACLK(gtx_clk_bufg),                                // input wire ACLK
  .ARESETN(gtx_resetn),                          // input wire ARESETN
  .S00_AXIS_ACLK(gtx_clk_bufg),              // input wire S00_AXIS_ACLK
  .S00_AXIS_ARESETN(gtx_resetn),        // input wire S00_AXIS_ARESETN
  .S00_AXIS_TVALID(cmd_pkt_s_axis_tvalid),          // input wire S00_AXIS_TVALID
  .S00_AXIS_TREADY(cmd_pkt_s_axis_tready),          // output wire S00_AXIS_TREADY
  .S00_AXIS_TDATA(cmd_pkt_s_axis_tdata),            // input wire [31 : 0] S00_AXIS_TDATA
  .S00_AXIS_TKEEP(cmd_pkt_s_axis_tkeep),            // input wire [3 : 0] S00_AXIS_TKEEP
  .S00_AXIS_TLAST(cmd_pkt_s_axis_tlast),            // input wire S00_AXIS_TLAST
  .S00_AXIS_TID(cmd_pkt_s_axis_tid),                // input wire [3 : 0] S00_AXIS_TID
  .S00_AXIS_TDEST(cmd_pkt_s_axis_tdest),            // input wire [3 : 0] S00_AXIS_TDEST
  .S00_AXIS_TUSER(cmd_pkt_s_axis_tuser),            // input wire [31 : 0] S00_AXIS_TUSER
  .M00_AXIS_ACLK(s_axi_aclk),              // input wire M00_AXIS_ACLK
  .M01_AXIS_ACLK(s_axi_aclk),              // input wire M01_AXIS_ACLK
  //.M02_AXIS_ACLK(s_axi_aclk),              // input wire M02_AXIS_ACLK
  .M02_AXIS_ACLK(clk_245_76MHz),              // input wire M02_AXIS_ACLK
  .M03_AXIS_ACLK(s_axi_aclk),              // input wire M03_AXIS_ACLK
  .M00_AXIS_ARESETN(s_axi_resetn),        // input wire M00_AXIS_ARESETN
  .M01_AXIS_ARESETN(s_axi_resetn),        // input wire M01_AXIS_ARESETN
//  .M02_AXIS_ARESETN(s_axi_resetn),        // input wire M02_AXIS_ARESETN
  .M02_AXIS_ARESETN(!clk_245_rst),        // input wire M02_AXIS_ARESETN
  .M03_AXIS_ARESETN(s_axi_resetn),        // input wire M03_AXIS_ARESETN
  .M00_AXIS_TVALID(ch_wr_cmd_axis_tvalid),          // output wire M00_AXIS_TVALID
  .M01_AXIS_TVALID(sp_wr_cmd_axis_tvalid),          // output wire M01_AXIS_TVALID
  .M02_AXIS_TVALID(wfrm_wr_data_axis_tvalid),          // output wire M02_AXIS_TVALID
//  .M02_AXIS_TVALID(ch_rd_cmd_axis_tvalid),          // output wire M02_AXIS_TVALID
  .M03_AXIS_TVALID(sp_rd_cmd_axis_tvalid),          // output wire M03_AXIS_TVALID
  .M00_AXIS_TREADY(ch_wr_cmd_axis_tready),          // input wire M00_AXIS_TREADY
  .M01_AXIS_TREADY(sp_wr_cmd_axis_tready),          // input wire M01_AXIS_TREADY
  .M02_AXIS_TREADY(wfrm_wr_data_axis_tready),          // input wire M02_AXIS_TREADY
  //  .M02_AXIS_TREADY(ch_rd_cmd_axis_tready),          // input wire M02_AXIS_TREADY
  .M03_AXIS_TREADY(sp_rd_cmd_axis_tready),          // input wire M03_AXIS_TREADY
  .M00_AXIS_TDATA(ch_wr_cmd_axis_tdata),            // output wire [223 : 0] M00_AXIS_TDATA
  .M01_AXIS_TDATA(sp_wr_cmd_axis_tdata),            // output wire [223 : 0] M01_AXIS_TDATA
  .M02_AXIS_TDATA(wfrm_wr_data_axis_tdata),            // output wire [63 : 0] M02_AXIS_TDATA
//  .M02_AXIS_TDATA(ch_rd_cmd_axis_tdata),            // output wire [63 : 0] M02_AXIS_TDATA
  .M03_AXIS_TDATA(sp_rd_cmd_axis_tdata),            // output wire [63 : 0] M03_AXIS_TDATA
  .M00_AXIS_TKEEP(ch_wr_cmd_axis_tkeep),            // output wire [27 : 0] M00_AXIS_TKEEP
  .M01_AXIS_TKEEP(sp_wr_cmd_axis_tkeep),            // output wire [27 : 0] M01_AXIS_TKEEP
  .M02_AXIS_TKEEP(wfrm_wr_data_axis_tkeep),            // output wire [7 : 0] M02_AXIS_TKEEP
//  .M02_AXIS_TKEEP(ch_rd_cmd_axis_tkeep),            // output wire [7 : 0] M02_AXIS_TKEEP
  .M03_AXIS_TKEEP(sp_rd_cmd_axis_tkeep),            // output wire [7 : 0] M03_AXIS_TKEEP
  .M00_AXIS_TLAST(ch_wr_cmd_axis_tlast),            // output wire M00_AXIS_TLAST
  .M01_AXIS_TLAST(sp_wr_cmd_axis_tlast),            // output wire M01_AXIS_TLAST
  .M02_AXIS_TLAST(wfrm_wr_data_axis_tlast),            // output wire M02_AXIS_TLAST
//  .M02_AXIS_TLAST(ch_rd_cmd_axis_tlast),            // output wire M02_AXIS_TLAST
  .M03_AXIS_TLAST(sp_rd_cmd_axis_tlast),            // output wire M03_AXIS_TLAST
  .M00_AXIS_TID(ch_wr_cmd_axis_tid),                // output wire [3 : 0] M00_AXIS_TID
  .M01_AXIS_TID(sp_wr_cmd_axis_tid),                // output wire [3 : 0] M01_AXIS_TID
  .M02_AXIS_TID(wfrm_wr_data_axis_tid),                // output wire [3 : 0] M02_AXIS_TID
//  .M02_AXIS_TID(ch_rd_cmd_axis_tid),                // output wire [3 : 0] M02_AXIS_TID
  .M03_AXIS_TID(sp_rd_cmd_axis_tid),                // output wire [3 : 0] M03_AXIS_TID
  .M00_AXIS_TDEST(ch_wr_cmd_axis_tdest),            // output wire [3 : 0] M00_AXIS_TDEST
  .M01_AXIS_TDEST(sp_wr_cmd_axis_tdest),            // output wire [3 : 0] M01_AXIS_TDEST
  .M02_AXIS_TDEST(wfrm_wr_data_axis_tdest),            // output wire [3 : 0] M02_AXIS_TDEST
//  .M02_AXIS_TDEST(ch_rd_cmd_axis_tdest),            // output wire [3 : 0] M02_AXIS_TDEST
  .M03_AXIS_TDEST(sp_rd_cmd_axis_tdest),            // output wire [3 : 0] M03_AXIS_TDEST
  .M00_AXIS_TUSER(ch_wr_cmd_axis_tuser),            // output wire [223 : 0] M00_AXIS_TUSER
  .M01_AXIS_TUSER(sp_wr_cmd_axis_tuser),            // output wire [223 : 0] M01_AXIS_TUSER
  .M02_AXIS_TUSER(wfrm_wr_data_axis_tuser),            // output wire [63 : 0] M02_AXIS_TUSER
//  .M02_AXIS_TUSER(ch_rd_cmd_axis_tuser),            // output wire [63 : 0] M02_AXIS_TUSER
  .M03_AXIS_TUSER(sp_rd_cmd_axis_tuser),            // output wire [63 : 0] M03_AXIS_TUSER
  .S00_DECODE_ERR(S00_CMD_DECODE_ERR),            // output wire S00_DECODE_ERR
  .S00_FIFO_DATA_COUNT(S00_CMD_FIFO_DATA_COUNT),  // output wire [31 : 0] S00_FIFO_DATA_COUNT
  .M00_FIFO_DATA_COUNT(M00_CMD_FIFO_DATA_COUNT),  // output wire [31 : 0] M00_FIFO_DATA_COUNT
  .M01_FIFO_DATA_COUNT(M01_CMD_FIFO_DATA_COUNT),  // output wire [31 : 0] M01_FIFO_DATA_COUNT
  .M02_FIFO_DATA_COUNT(M02_CMD_FIFO_DATA_COUNT),  // output wire [31 : 0] M02_FIFO_DATA_COUNT
  .M03_FIFO_DATA_COUNT(M03_CMD_FIFO_DATA_COUNT)  // output wire [31 : 0] M03_FIFO_DATA_COUNT
);

assign fmc150_ctrl_bus_bypass = {3'b0,gpio_dip_sw[3],1'b0,1'b0,1'b0,1'b0};
//fmc150_ctrl_bus = {3'b0,ddc_duc_bypass,digital_mode,adc_out_dac_in,external_clock,gen_adc_test_pattern};

assign ethernet_ctrl_bus_bypass = {2'b0,1'b1,gpio_dip_sw[1],1'b0,1'b0,gpio_dip_sw[0],~gpio_dip_sw[0]};
// ethernet_ctrl_bus = {2'b0,enable_rx_decode,enable_adc_pkt,gen_tx_data,chk_tx_data,mac_speed};

ethernet_rgmii_top ethernet_rgmii_wrapper
(
  // asynchronous reset
  .glbl_rst_intn         (glbl_rst_intn),

  // 200MHz clock input from board
  //.clk_in_p         (ddr3_clk1_p),
  //.clk_in_n         (ddr3_clk1_n),
  // 125 MHz clock from MMCM
  .gtx_clk_bufg     (gtx_clk_bufg),
  .refclk_bufg      (refclk_bufg),
  .s_axi_aclk       (s_axi_aclk),

  .dcm_locked       (dcm_locked),


  // reset outputs
  .rx_reset (rx_reset),
  .tx_reset (tx_reset),

  // synchronous reset inputs
  .gtx_resetn       (gtx_resetn),
  .s_axi_resetn     (s_axi_resetn),
  .chk_resetn       (chk_resetn),


  // RGMII Interface
  //----------------
  .rgmii_txd        (rgmii_txd),    //[3:0]
  .rgmii_tx_ctl        (rgmii_tx_ctl),
  .rgmii_txc        (rgmii_txc),
  .rgmii_rxd         (rgmii_rxd), //[3:0]
  .rgmii_rx_ctl         (rgmii_rx_ctl),
  .rgmii_rxc         (rgmii_rxc),

  // MDIO Interface
  //---------------
  .mdio         (mdio),
  .mdc        (mdc),


  // Serialised statistics vectors
  //------------------------------
  .tx_statistics_s        (tx_statistics_s),
  .rx_statistics_s        (rx_statistics_s),

  // Serialised Pause interface controls
  //------------------------------------
  .pause_req_s         (pause_req_s),

  // Decoded Commands from RGMII RX fifo
  .cmd_axis_tdata        (cmd_pkt_s_axis_tdata),
  .cmd_axis_tvalid       (cmd_pkt_s_axis_tvalid),
  .cmd_axis_tlast        (cmd_pkt_s_axis_tlast),
  .cmd_axis_tuser         (cmd_pkt_s_axis_tuser),
  .cmd_axis_tdest         (cmd_pkt_s_axis_tdest),
  .cmd_axis_tid           (cmd_pkt_s_axis_tid),
  .cmd_axis_tkeep        (cmd_pkt_s_axis_tkeep),
  .cmd_axis_tready       (cmd_pkt_s_axis_tready),

  // connections to adc data ports
  .adc_axis_tdata           (adc_pkt_axis_tdata),
  .adc_axis_tvalid          (adc_pkt_axis_tvalid),
  .adc_axis_tlast           (adc_pkt_axis_tlast),
  .adc_axis_tuser           (adc_pkt_axis_tuser),
  .adc_axis_tready          (adc_pkt_axis_tready),

  .pk_axis_tdata           (pk_axis_tdata),
  .pk_axis_tvalid          (pk_axis_tvalid),
  .pk_axis_tlast           (pk_axis_tlast),
  .pk_axis_tuser           (pk_axis_tuser),
  .pk_axis_tready          (pk_axis_tready),


  // Main example design controls
  //-----------------------------
 // .ethernet_ctrl_bus (ethernet_ctrl_bus),
  .ethernet_ctrl_bus (ethernet_ctrl_bus_bypass),
  .update_speed         (update_speed),
  //input         serial_command, // tied to pause_req_s
  .config_board         (config_board),
  .serial_response        (serial_response),
 // .reset_error         (reset_error),
  .frame_error        (frame_error),
  .frame_errorn        (frame_errorn),
  .activity_flash        (activity_flash),
  .activity_flashn        (activity_flashn)
);


assign pause_req_s = gpio_sw_s;      //input gpio switch s
assign update_speed = gpio_sw_c;      //input gpio switch c
assign config_board = gpio_sw_w;      //input gpio switch w
assign reset_error = gpio_sw_n;      //input gpio switch n

assign adc_pkt_axis_tuser = 'b0;
//----------------------------------------------------------------------------
// Clock logic to generate required clocks from the 200MHz on board
// if 125MHz is available directly this can be removed
//----------------------------------------------------------------------------
design_clocks example_clocks
 (
    // differential clock inputs - 200 MHz
    .clk_in_p         (sysclk_p),
    .clk_in_n         (sysclk_n),

    // asynchronous control/resets
    .glbl_rst         (cpu_reset),
    .dcm_locked       (dcm_locked),

    // clock outputs
    .gtx_clk_bufg     (gtx_clk_bufg),       // 125 MHz (5*clk_in_p/8)
    .refclk_bufg      (refclk_bufg),        // 200 MHz (clk_in_p)
    .sysclk_bufg      (sysclk_bufg),        // 200 MHz (clk_in_p)
    .clk250_bufg      (clk250_bufg),        // 250 MHz (5*clk_in_p/4)
    .s_axi_aclk       (s_axi_aclk)          // 100 MHz (clk_in_p/2)
 );

 //----------------------------------------------------------------------------
 // Clock logic to generate required clocks from the 200MHz on board
 // if 125MHz is available directly this can be removed
 //----------------------------------------------------------------------------

   // Pass the GTX clock to the Test Bench
 assign gtx_clk_bufg_out = gtx_clk_bufg;

 design_resets example_resets
 (
    // clocks
    .s_axi_aclk       (s_axi_aclk),
    .gtx_clk          (gtx_clk_bufg),
    .refclk           (refclk_bufg),
    .sysclk           (sysclk_bufg),
    .clk250           (clk250_bufg),

    // asynchronous resets
    .glbl_rst         (cpu_reset),
    .reset_error      (reset_error),
    .rx_reset         (rx_reset),
    .tx_reset         (tx_reset),

    .dcm_locked       (dcm_locked),

    // synchronous reset outputs
    .glbl_rst_intn    (glbl_rst_intn),
    .gtx_resetn       (gtx_resetn),
    .s_axi_resetn     (s_axi_resetn),
    .refclk_resetn    (refclk_resetn),
    .sysclk_resetn    (sysclk_resetn),
    .clk250_resetn    (clk250_resetn),
    .phy_resetn       (phy_resetn),
    .chk_resetn       (chk_resetn)
 );

fmc150_dac_adc  #
(
    .ADC_AXI_DATA_WIDTH(ADC_AXI_DATA_WIDTH),
    .ADC_AXI_TID_WIDTH(ADC_AXI_TID_WIDTH),
    .ADC_AXI_TDEST_WIDTH(ADC_AXI_TDEST_WIDTH),
    .ADC_AXI_TUSER_WIDTH(ADC_AXI_TUSER_WIDTH),
    .ADC_AXI_STREAM_ID(ADC_AXI_STREAM_ID),
    .ADC_AXI_STREAM_DEST(ADC_AXI_STREAM_DEST),
    .PK_AXI_DATA_WIDTH(PK_AXI_DATA_WIDTH),
    .PK_AXI_TID_WIDTH(PK_AXI_TID_WIDTH),
    .PK_AXI_TDEST_WIDTH(PK_AXI_TDEST_WIDTH),
    .PK_AXI_TUSER_WIDTH(PK_AXI_TUSER_WIDTH),
    .PK_AXI_STREAM_ID(PK_AXI_STREAM_ID),
    .PK_AXI_STREAM_DEST(PK_AXI_STREAM_DEST)
)
fmc150_dac_adc_inst
(
    .aclk (ui_clk),
    .aresetn (aresetn),
    //.aclk(sysclk_bufg),
    //.aresetn (sysclk_resetn),
     // --KC705 Resources - from fmc150 example design
     .axis_adc_tdata                      (axis_adc_tdata),
     .axis_adc_tvalid                     (axis_adc_tvalid),
     .axis_adc_tlast                      (axis_adc_tlast),
     .axis_adc_tkeep                      (axis_adc_tkeep),
     .axis_adc_tid                        (axis_adc_tid),
     .axis_adc_tdest                      (axis_adc_tdest),
     .axis_adc_tuser                      (axis_adc_tuser),
     .axis_adc_tready                     (axis_adc_tready),
     .axis_adc_tstrb                      (axis_adc_tstrb),

     .axis_pk_tdata                      (axis_pk_tdata),
     .axis_pk_tvalid                     (axis_pk_tvalid),
     .axis_pk_tlast                      (axis_pk_tlast),
     .axis_pk_tkeep                      (axis_pk_tkeep),
     .axis_pk_tid                        (axis_pk_tid),
     .axis_pk_tdest                      (axis_pk_tdest),
     .axis_pk_tuser                      (axis_pk_tuser),
     .axis_pk_tready                     (axis_pk_tready),
     .axis_pk_tstrb                      (axis_pk_tstrb),

     .fmc150_status_vector                (fmc150_status_vector),
     .chirp_ready                         (chirp_ready),
     .chirp_done                          (chirp_done),
     .chirp_active                        (chirp_active),
     .chirp_init                          (chirp_init),
     .chirp_enable                        (chirp_enable),
     .adc_enable                          (adc_enable),

     .wf_read_ready(wf_read_ready),
     .wfrm_axis_tdata(wfout_axis_tdata),
     .wfrm_axis_tvalid(wfout_axis_tvalid),
     .wfrm_axis_tlast(wfout_axis_tlast),
     .wfrm_axis_tready(wfout_axis_tready),

     .chirp_control_word         (chirp_parameters[127:96]),
     .chirp_freq_offset          (chirp_parameters[95:64]),
     .chirp_tuning_word_coeff    (chirp_parameters[63:32]),
     .chirp_count_max            (chirp_parameters[31:0]),

    //  .clk_100Mhz (fmc150_clk_100Mhz),
    //  .clk_100Mhz_rst (fmc150_clk_100Mhz_rst),
     .clk_100Mhz (s_axi_aclk),
     .clk_200Mhz (refclk_bufg),
     .mmcm_locked (dcm_locked),

     .clk_out_245_76MHz                        (clk_245_76MHz),
     .clk_245_rst                               (clk_245_rst),
  //   .clk_out_491_52MHz                       (clk_491_52MHz),


    .cpu_reset (cpu_reset),       // : in    std_logic; -- CPU RST button, SW7 on KC705
//    .sysclk_p (sysclk_p),        // : in    std_logic;
//    .sysclk_n (sysclk_n),        // : in    std_logic;
//    .cpu_reset (sysclk_reset),
    .sysclk_bufg (sysclk_bufg),
//    .gpio_led (gpio_led),        // : out   std_logic_vector(7 downto 0);
//    .gpio_dip_sw (gpio_dip_sw),   //   : in    std_logic_vector(7 downto 0);
    .gpio_led_c (gpio_led_c),        //       : out   std_logic;
     .gpio_led_e (gpio_led_e),        //       : out   std_logic;
     .gpio_led_n (gpio_led_n),       //       : out   std_logic;
     .gpio_led_s (gpio_led_s),        //       : out   std_logic;
     .gpio_led_w (gpio_led_w),        //              : out   std_logic;
     .gpio_sw_c (gpio_sw_c),        //               : in    std_logic;
     .gpio_sw_e (gpio_sw_e),        //               : in    std_logic;
     .gpio_sw_n (gpio_sw_n),        //               : in    std_logic;
     .gpio_sw_s (gpio_sw_s),        //               : in    std_logic;
     .gpio_sw_w (gpio_sw_w),        //               : in    std_logic;

    // .fmc150_ctrl_bus (fmc150_ctrl_bus),
      .fmc150_ctrl_bus (fmc150_ctrl_bus_bypass),
      .fmc150_spi_ctrl_bus_in (fmc150_spi_ctrl_bus_in),
      .fmc150_spi_ctrl_bus_out (fmc150_spi_ctrl_bus_out),

    // --Clock/Data connection to ADC on FMC150 (ADS62P49)
     .clk_ab_p (clk_ab_p),        //                : in    std_logic;
     .clk_ab_n (clk_ab_n),        //                : in    std_logic;
     .cha_p (cha_p),        //                   : in    std_logic_vector(6 downto 0);
     .cha_n (cha_n),        //                   : in    std_logic_vector(6 downto 0);
     .chb_p (chb_p),        //                   : in    std_logic_vector(6 downto 0);
     .chb_n (chb_n),        //                   : in    std_logic_vector(6 downto 0);

    //  --Clock/Data connection to DAC on FMC150 (DAC3283)
     .dac_dclk_p (dac_dclk_p),        //              : out   std_logic;
     .dac_dclk_n (dac_dclk_n),        //              : out   std_logic;
     .dac_data_p (dac_data_p),        //              : out   std_logic_vector(7 downto 0);
     .dac_data_n (dac_data_n),        //              : out   std_logic_vector(7 downto 0);
     .dac_frame_p (dac_frame_p),        //             : out   std_logic;
     .dac_frame_n (dac_frame_n),        //             : out   std_logic;
     .txenable (txenable),        //                : out   std_logic;

    // --Clock/Trigger connection to FMC150
    // --clk_to_fpga_p    : in    std_logic;
    // --clk_to_fpga_n    : in    std_logic;
    // --ext_trigger_p    : in    std_logic;
    // --ext_trigger_n    : in    std_logic;

    //  --Serial Peripheral Interface (SPI)
     .spi_sclk (spi_sclk),        //                : out   std_logic; -- Shared SPI clock line
     .spi_sdata (spi_sdata),        //               : out   std_logic; -- Shared SPI sata line

    //  -- ADC specific signals
     .adc_n_en (adc_n_en),        //                : out   std_logic; -- SPI chip select
     .adc_sdo (adc_sdo),        //                 : in    std_logic; -- SPI data out
     .adc_reset (adc_reset),        //               : out   std_logic; -- SPI reset

    // -- CDCE specific signals
     .cdce_n_en (cdce_n_en),        //               : out   std_logic; -- SPI chip select
     .cdce_sdo (cdce_sdo),        //                : in    std_logic; -- SPI data out
     .cdce_n_reset (cdce_n_reset),        //            : out   std_logic;
     .cdce_n_pd (cdce_n_pd),        //               : out   std_logic;
     .ref_en (ref_en),        //                  : out   std_logic;
     .pll_status (pll_status),        //             : in    std_logic;

    //  -- DAC specific signals
     .dac_n_en (dac_n_en),        //                : out   std_logic; -- SPI chip select
     .dac_sdo (dac_sdo),        //                 : in    std_logic; -- SPI data out

    //  -- Monitoring specific signals
      .mon_n_en (mon_n_en),        //                : out   std_logic; -- SPI chip select
      .mon_sdo (mon_sdo),        //                 : in    std_logic; -- SPI data out
      .mon_n_reset (mon_n_reset),        //             : out   std_logic;
      .mon_n_int (mon_n_int),        //               : in    std_logic;

    // --FMC Present status
     .prsnt_m2c_l (prsnt_m2c_l)        //             : in    std_logic

);

waveform_formatter waveform_formatter_inst (
    .axi_tclk(clk_245_76MHz),
    .axi_tresetn(!clk_245_rst),
    .wf_write_ready(wf_write_ready),
    .init_wf_write(init_wf_write),
    .waveform_parameters(waveform_parameters),
    .wfrm_axis_tdata(wfrm_wr_data_axis_tdata),
    .wfrm_axis_tvalid(wfrm_wr_data_axis_tvalid),
    .wfrm_axis_tlast(wfrm_wr_data_axis_tlast),
    .wfrm_axis_tkeep(wfrm_wr_data_axis_tkeep),
    .wfrm_axis_tdest(wfrm_wr_data_axis_tdest),
    .wfrm_axis_tid(wfrm_wr_data_axis_tid),
    .wfrm_axis_tuser(wfrm_wr_data_axis_tuser),
    .wfrm_axis_tready(wfrm_wr_data_axis_tready),

    .tdata(wfin_axis_tdata),
    .tvalid(wfin_axis_tvalid),
    .tlast(wfin_axis_tlast),
    .tkeep(wfin_axis_tkeep),
    .tdest(wfin_axis_tdest),
    .tid(wfin_axis_tid),
    .tuser(wfin_axis_tuser),
    .tready(wfin_axis_tready)
);

waveform_stream #(
   .WRITE_BEFORE_READ(1'b1)
) waveform_stream_inst(
    .clk_in1(clk_245_76MHz),
    .aresetn(!clk_245_rst),
    .waveform_parameters(waveform_parameters),
    .init_wf_write (init_wf_write),
    .wf_write_ready (wf_write_ready),
    .wf_read_ready (wf_read_ready),
    // data from ADC Data fifo
    .wfin_axis_tdata (wfin_axis_tdata),
    .wfin_axis_tvalid(wfin_axis_tvalid),
    .wfin_axis_tlast(wfin_axis_tlast),
    .wfin_axis_tkeep(wfin_axis_tkeep),
    .wfin_axis_tready(wfin_axis_tready),

    // data from ADC Data fifo
    .wfout_axis_tdata(wfout_axis_tdata),
    .wfout_axis_tvalid(wfout_axis_tvalid),
    .wfout_axis_tlast(wfout_axis_tlast),
    .wfout_axis_tkeep(wfout_axis_tkeep),
    .wfout_axis_tready(wfout_axis_tready)
);

peak_axis_dwidth_converter peak_axis_dwidth_converter_inst (
  .aclk(clk_245_76MHz),                    // input wire aclk
  .aresetn(!clk_245_rst),              // input wire aresetn
  .s_axis_tvalid(axis_pk_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(axis_pk_tready),  // output wire s_axis_tready
  .s_axis_tdata(axis_pk_tdata),    // input wire [511 : 0] s_axis_tdata
  .s_axis_tlast(axis_pk_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(dwout_axis_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(dwout_axis_tready),  // input wire m_axis_tready
  .m_axis_tdata(dwout_axis_tdata),    // output wire [7 : 0] m_axis_tdata
  .m_axis_tlast(dwout_axis_tlast)    // output wire m_axis_tlast
);
 peak_axis_clock_converter peak_axis_clock_converter_inst (
     .s_axis_aresetn(!clk_245_rst),  // input wire s_axis_aresetn
     .m_axis_aresetn(gtx_resetn),  // input wire m_axis_aresetn
     .s_axis_aclk(clk_245_76MHz),        // input wire s_axis_aclk
     .s_axis_tvalid(dwout_axis_tvalid),    // input wire s_axis_tvalid
     .s_axis_tready(dwout_axis_tready),    // output wire s_axis_tready
     .s_axis_tdata(dwout_axis_tdata),      // input wire [7 : 0] s_axis_tdata
     .s_axis_tlast(dwout_axis_tlast),      // input wire s_axis_tlast
     .m_axis_aclk(gtx_clk_bufg),        // input wire m_axis_aclk
     .m_axis_tvalid(pk_axis_tvalid),    // output wire m_axis_tvalid
     .m_axis_tready(pk_axis_tready),    // input wire m_axis_tready
     .m_axis_tdata(pk_axis_tdata),      // output wire [511 : 0] m_axis_tdata
     .m_axis_tlast(pk_axis_tlast)      // output wire m_axis_tlast
   );
   assign pk_axis_tuser = 1'b0;

axi_vfifo_ctrl_0 u_axi_vfifo_ctrl_0(
    .aclk(ui_clk),                                          // input wire aclk
    .aresetn(aresetn),                                    // input wire aresetn

    .s_axis_tvalid(s_axis_vfifo_tvalid),                        // input wire s_axis_tvalid
    .s_axis_tready(s_axis_vfifo_tready),                        // output wire s_axis_tready
    .s_axis_tdata(s_axis_vfifo_tdata),                          // input wire [511 : 0] s_axis_tdata
    .s_axis_tstrb(s_axis_vfifo_tstrb),                          // input wire [63 : 0] s_axis_tstrb
    .s_axis_tkeep(s_axis_vfifo_tkeep),                          // input wire [63 : 0] s_axis_tkeep
    .s_axis_tlast(s_axis_vfifo_tlast),                          // input wire s_axis_tlast
    .s_axis_tid(s_axis_vfifo_tid),                              // input wire [0 : 0] s_axis_tid
    .s_axis_tdest(s_axis_vfifo_tdest),                          // input wire [0 : 0] s_axis_tdest

    .m_axis_tvalid(m_axis_vfifo_tvalid),                        // output wire m_axis_tvalid
    .m_axis_tready(m_axis_vfifo_tready),                        // input wire m_axis_tready
    .m_axis_tdata(m_axis_vfifo_tdata),                          // output wire [511 : 0] m_axis_tdata
    .m_axis_tstrb(m_axis_vfifo_tstrb),                          // output wire [63 : 0] m_axis_tstrb
    .m_axis_tkeep(m_axis_vfifo_tkeep),                          // output wire [63 : 0] m_axis_tkeep
    .m_axis_tlast(m_axis_vfifo_tlast),                          // output wire m_axis_tlast
    .m_axis_tid(m_axis_vfifo_tid),                              // output wire [0 : 0] m_axis_tid
    .m_axis_tdest(m_axis_vfifo_tdest),                          // output wire [0 : 0] m_axis_tdest

    .m_axi_awid(m_axi_vfifo_awid),                              // output wire [0 : 0] m_axi_awid
    .m_axi_awaddr(m_axi_vfifo_awaddr),                          // output wire [31 : 0] m_axi_awaddr
    .m_axi_awlen(m_axi_vfifo_awlen),                            // output wire [7 : 0] m_axi_awlen
    .m_axi_awsize(m_axi_vfifo_awsize),                          // output wire [2 : 0] m_axi_awsize
    .m_axi_awburst(m_axi_vfifo_awburst),                        // output wire [1 : 0] m_axi_awburst
    .m_axi_awlock(m_axi_vfifo_awlock),                          // output wire [0 : 0] m_axi_awlock
    .m_axi_awcache(m_axi_vfifo_awcache),                        // output wire [3 : 0] m_axi_awcache
    .m_axi_awprot(m_axi_vfifo_awprot),                          // output wire [2 : 0] m_axi_awprot
    .m_axi_awqos(m_axi_vfifo_awqos),                            // output wire [3 : 0] m_axi_awqos
    .m_axi_awregion(m_axi_vfifo_awregion),                      // output wire [3 : 0] m_axi_awregion
    .m_axi_awuser(m_axi_vfifo_awuser),                          // output wire [0 : 0] m_axi_awuser
    .m_axi_awvalid(m_axi_vfifo_awvalid),                        // output wire m_axi_awvalid
    .m_axi_awready(m_axi_vfifo_awready),                        // input wire m_axi_awready
    .m_axi_wdata(m_axi_vfifo_wdata),                            // output wire [511 : 0] m_axi_wdata
    .m_axi_wstrb(m_axi_vfifo_wstrb),                            // output wire [63 : 0] m_axi_wstrb
    .m_axi_wlast(m_axi_vfifo_wlast),                            // output wire m_axi_wlast
    .m_axi_wuser(m_axi_vfifo_wuser),                            // output wire [0 : 0] m_axi_wuser
    .m_axi_wvalid(m_axi_vfifo_wvalid),                          // output wire m_axi_wvalid
    .m_axi_wready(m_axi_vfifo_wready),                          // input wire m_axi_wready
    .m_axi_bid(m_axi_vfifo_bid),                                // input wire [0 : 0] m_axi_bid
    .m_axi_bresp(m_axi_vfifo_bresp),                            // input wire [1 : 0] m_axi_bresp
    .m_axi_buser(m_axi_vfifo_buser),                            // input wire [0 : 0] m_axi_buser
    .m_axi_bvalid(m_axi_vfifo_bvalid),                          // input wire m_axi_bvalid
    .m_axi_bready(m_axi_vfifo_bready),                          // output wire m_axi_bready
    .m_axi_arid(m_axi_vfifo_arid),                              // output wire [0 : 0] m_axi_arid
    .m_axi_araddr(m_axi_vfifo_araddr),                          // output wire [31 : 0] m_axi_araddr
    .m_axi_arlen(m_axi_vfifo_arlen),                            // output wire [7 : 0] m_axi_arlen
    .m_axi_arsize(m_axi_vfifo_arsize),                          // output wire [2 : 0] m_axi_arsize
    .m_axi_arburst(m_axi_vfifo_arburst),                        // output wire [1 : 0] m_axi_arburst
    .m_axi_arlock(m_axi_vfifo_arlock),                          // output wire [0 : 0] m_axi_arlock
    .m_axi_arcache(m_axi_vfifo_arcache),                        // output wire [3 : 0] m_axi_arcache
    .m_axi_arprot(m_axi_vfifo_arprot),                          // output wire [2 : 0] m_axi_arprot
    .m_axi_arqos(m_axi_vfifo_arqos),                            // output wire [3 : 0] m_axi_arqos
    .m_axi_arregion(m_axi_vfifo_arregion),                      // output wire [3 : 0] m_axi_arregion
    .m_axi_aruser(m_axi_vfifo_aruser),                          // output wire [0 : 0] m_axi_aruser
    .m_axi_arvalid(m_axi_vfifo_arvalid),                        // output wire m_axi_arvalid
    .m_axi_arready(m_axi_vfifo_arready),                        // input wire m_axi_arready
    .m_axi_rid(m_axi_vfifo_rid),                                // input wire [0 : 0] m_axi_rid
    .m_axi_rdata(m_axi_vfifo_rdata),                            // input wire [511 : 0] m_axi_rdata
    .m_axi_rresp(m_axi_vfifo_rresp),                            // input wire [1 : 0] m_axi_rresp
    .m_axi_rlast(m_axi_vfifo_rlast),                            // input wire m_axi_rlast
    .m_axi_ruser(m_axi_vfifo_ruser),                            // input wire [0 : 0] m_axi_ruser
    .m_axi_rvalid(m_axi_vfifo_rvalid),                          // input wire m_axi_rvalid
    .m_axi_rready(m_axi_vfifo_rready),                          // output wire m_axi_rready
    .vfifo_mm2s_channel_full(vfifo_mm2s_channel_full),    // input wire [1 : 0] vfifo_mm2s_channel_full
    .vfifo_s2mm_channel_full(vfifo_s2mm_channel_full),    // output wire [1 : 0] vfifo_s2mm_channel_full
    .vfifo_mm2s_channel_empty(vfifo_mm2s_channel_empty),  // output wire [1 : 0] vfifo_mm2s_channel_empty
    .vfifo_idle(vfifo_idle)                              // output wire [1 : 0] vfifo_idle
);
assign m_axi_vfifo_buser = 'b0;
assign m_axi_vfifo_ruser = 'b0;
// Master - 512 bits
// Slave0 - 64 bits
// Slave1 - 8 bits
axis_interconnect_1m2s u_axis_interconnect_1m2s(
    .ACLK(ui_clk),                                  // input wire ACLK
    .ARESETN(aresetn),                            // input wire ARESETN
    //  .ACLK(sysclk_bufg),                                  // input wire ACLK
    //  .ARESETN(sysclk_resetn),                            // input wire ARESETN

// S00 AXIS Connection to ADC Module
    .S00_AXIS_ACLK(ui_clk),                // input wire S00_AXIS_ACLK
    .S00_AXIS_ARESETN(aresetn),          // input wire S00_AXIS_ARESETN
    //.S00_AXIS_ACLK(sysclk_bufg),
    //.S00_AXIS_ARESETN (sysclk_resetn),
    .S00_AXIS_TVALID(axis_adc_tvalid),            // input wire S00_AXIS_TVALID
    .S00_AXIS_TREADY(axis_adc_tready),            // output wire S00_AXIS_TREADY
    .S00_AXIS_TDATA(axis_adc_tdata),              // input wire [63 : 0] S00_AXIS_TDATA
    .S00_AXIS_TSTRB(axis_adc_tstrb),              // input wire [7 : 0] S00_AXIS_TSTRB
    .S00_AXIS_TKEEP(axis_adc_tkeep),              // input wire [7 : 0] S00_AXIS_TKEEP
    .S00_AXIS_TLAST(axis_adc_tlast),              // input wire S00_AXIS_TLAST
    .S00_AXIS_TID(axis_adc_tid),                  // input wire [0 : 0] S00_AXIS_TID
    .S00_AXIS_TDEST(axis_adc_tdest),              // input wire [0 : 0] S00_AXIS_TDEST

// S01 AXIS Connection to RGMII Ethernet RX Module
    .S01_AXIS_ACLK(gtx_clk_bufg),                // input wire S01_AXIS_ACLK
    .S01_AXIS_ARESETN(gtx_resetn),          // input wire S01_AXIS_ARESETN
    .S01_AXIS_TVALID(S01_AXIS_TVALID),            // input wire S01_AXIS_TVALID
    .S01_AXIS_TREADY(S01_AXIS_TREADY),            // output wire S01_AXIS_TREADY
    .S01_AXIS_TDATA(S01_AXIS_TDATA),              // input wire [7 : 0] S01_AXIS_TDATA
    .S01_AXIS_TSTRB(S01_AXIS_TSTRB),              // input wire [0 : 0] S01_AXIS_TSTRB
    .S01_AXIS_TKEEP(S01_AXIS_TKEEP),              // input wire [0 : 0] S01_AXIS_TKEEP
    .S01_AXIS_TLAST(S01_AXIS_TLAST),              // input wire S01_AXIS_TLAST
    .S01_AXIS_TID(S01_AXIS_TID),                  // input wire [0 : 0] S01_AXIS_TID
    .S01_AXIS_TDEST(S01_AXIS_TDEST),              // input wire [0 : 0] S01_AXIS_TDEST

// M00 AXIS Connection to input (axis slave) of Virtual FIFO
    .M00_AXIS_ACLK(ui_clk),                // input wire M00_AXIS_ACLK
    .M00_AXIS_ARESETN(aresetn),          // input wire M00_AXIS_ARESETN
    .M00_AXIS_TVALID(s_axis_vfifo_tvalid),            // output wire M00_AXIS_TVALID
    .M00_AXIS_TREADY(s_axis_vfifo_tready),            // input wire M00_AXIS_TREADY
    .M00_AXIS_TDATA(s_axis_vfifo_tdata),              // output wire [63 : 0] M00_AXIS_TDATA
    .M00_AXIS_TSTRB(s_axis_vfifo_tstrb),              // output wire [7 : 0] M00_AXIS_TSTRB
    .M00_AXIS_TKEEP(s_axis_vfifo_tkeep),              // output wire [7 : 0] M00_AXIS_TKEEP
    .M00_AXIS_TLAST(s_axis_vfifo_tlast),              // output wire M00_AXIS_TLAST
    .M00_AXIS_TID(s_axis_vfifo_tid),                  // output wire [0 : 0] M00_AXIS_TID
    .M00_AXIS_TDEST(s_axis_vfifo_tdest),              // output wire [0 : 0] M00_AXIS_TDEST

// Non-AXIS Signals
    .S00_ARB_REQ_SUPPRESS(S00_ARB_REQ_SUPPRESS),  // input wire S00_ARB_REQ_SUPPRESS
    .S01_ARB_REQ_SUPPRESS(S01_ARB_REQ_SUPPRESS),  // input wire S01_ARB_REQ_SUPPRESS
    .S00_DECODE_ERR(S00_DECODE_ERR),              // output wire S00_DECODE_ERR
    .S01_DECODE_ERR(S01_DECODE_ERR),              // output wire S01_DECODE_ERR
    .S00_FIFO_DATA_COUNT(S00_FIFO_DATA_COUNT),    // output wire [31 : 0] S00_FIFO_DATA_COUNT
    .S01_FIFO_DATA_COUNT(S01_FIFO_DATA_COUNT)    // output wire [31 : 0] S01_FIFO_DATA_COUNT

  );
  assign S00_ARB_REQ_SUPPRESS = S00_ARB_REQ_SUPPRESS_Reg;
  assign S01_ARB_REQ_SUPPRESS = S01_ARB_REQ_SUPPRESS_Reg;

  // Master0 - 64 bits
  // Master1 - 8 bits
  // Slave - 512 bits
  axis_interconnect_1s2m u_axis_interconnect_1s2m(
      .ACLK(ui_clk),                                // input wire ACLK
      .ARESETN(aresetn),                          // input wire ARESETN

// S00 AXIS Connection to output (axis master) of Virtual FIFO
      .S00_AXIS_ACLK(ui_clk),              // input wire S00_AXIS_ACLK
      .S00_AXIS_ARESETN(aresetn),        // input wire S00_AXIS_ARESETN
      .S00_AXIS_TVALID(m_axis_vfifo_tvalid),          // input wire S00_AXIS_TVALID
      .S00_AXIS_TREADY(m_axis_vfifo_tready),          // output wire S00_AXIS_TREADY
      .S00_AXIS_TDATA(m_axis_vfifo_tdata),            // input wire [63 : 0] S00_AXIS_TDATA
      .S00_AXIS_TSTRB(m_axis_vfifo_tstrb),            // input wire [7 : 0] S00_AXIS_TSTRB
      .S00_AXIS_TKEEP(m_axis_vfifo_tkeep),            // input wire [7 : 0] S00_AXIS_TKEEP
      .S00_AXIS_TLAST(m_axis_vfifo_tlast),            // input wire S00_AXIS_TLAST
      .S00_AXIS_TID(m_axis_vfifo_tid),                // input wire [0 : 0] S00_AXIS_TID
      .S00_AXIS_TDEST(m_axis_vfifo_tdest),            // input wire [0 : 0] S00_AXIS_TDEST

// M00 AXIS Connection to DAC Module
      .M00_AXIS_ACLK(ui_clk),              // input wire M00_AXIS_ACLK
      .M00_AXIS_ARESETN(aresetn),        // input wire M00_AXIS_ARESETN
      //.M00_AXIS_ACLK(sysclk_bufg),              // input wire M00_AXIS_ACLK
      //.M00_AXIS_ARESETN(sysclk_resetn),        // input wire M00_AXIS_ARESETN

      .M00_AXIS_TVALID(M00_AXIS_TVALID),          // output wire M00_AXIS_TVALID
      .M00_AXIS_TREADY(M00_AXIS_TREADY),          // input wire M00_AXIS_TREADY
      .M00_AXIS_TDATA(M00_AXIS_TDATA),            // output wire [63 : 0] M00_AXIS_TDATA
      .M00_AXIS_TSTRB(M00_AXIS_TSTRB),            // output wire [7 : 0] M00_AXIS_TSTRB
      .M00_AXIS_TKEEP(M00_AXIS_TKEEP),            // output wire [7 : 0] M00_AXIS_TKEEP
      .M00_AXIS_TLAST(M00_AXIS_TLAST),            // output wire M00_AXIS_TLAST
      .M00_AXIS_TID(M00_AXIS_TID),                // output wire [0 : 0] M00_AXIS_TID
      .M00_AXIS_TDEST(M00_AXIS_TDEST),            // output wire [0 : 0] M00_AXIS_TDEST
      .M00_FIFO_DATA_COUNT(M00_FIFO_DATA_COUNT),  // output wire [31 : 0] M00_FIFO_DATA_COUNT

// M01 AXIS Connection to RGMII Ethernet TX Module
      .M01_AXIS_ACLK(gtx_clk_bufg),              // input wire M01_AXIS_ACLK
      .M01_AXIS_ARESETN(gtx_resetn),        // input wire M01_AXIS_ARESETN
      .M01_AXIS_TVALID(adc_pkt_axis_tvalid),          // output wire M01_AXIS_TVALID
      .M01_AXIS_TREADY(adc_pkt_axis_tready),          // input wire M01_AXIS_TREADY
      .M01_AXIS_TDATA(adc_pkt_axis_tdata),            // output wire [7 : 0] M01_AXIS_TDATA
      .M01_AXIS_TSTRB(adc_pkt_axis_tstrb),            // output wire [0 : 0] M01_AXIS_TSTRB
      .M01_AXIS_TKEEP(adc_pkt_axis_tkeep),            // output wire [0 : 0] M01_AXIS_TKEEP
      .M01_AXIS_TLAST(adc_pkt_axis_tlast),            // output wire M01_AXIS_TLAST
      .M01_AXIS_TID(adc_pkt_axis_tid),                // output wire [0 : 0] M01_AXIS_TID
      .M01_AXIS_TDEST(adc_pkt_axis_tdest),            // output wire [0 : 0] M01_AXIS_TDEST
      .M01_FIFO_DATA_COUNT(M01_FIFO_DATA_COUNT),  // output wire [31 : 0] M01_FIFO_DATA_COUNT


//Non-AXIS Signals
      .S00_DECODE_ERR(vfifo_S00_DECODE_ERR)            // output wire S00_DECODE_ERR
);

always @(posedge ui_clk) begin
    vfifo_mm2s_ch0_full <= (M00_FIFO_DATA_COUNT > FIFO_M00_THRESHOLD) ? 1'b1 : 1'b0;
    // vfifo_mm2s_ch0_full <= |M00_FIFO_DATA_COUNT[31:7];
end

// double register prog full in gtx clk domain
always @(posedge gtx_clk_bufg) begin
    vfifo_mm2s_ch1_full_gtxclk <= (M01_FIFO_DATA_COUNT > FIFO_M01_THRESHOLD) ? 1'b1 : 1'b0;
   // vfifo_mm2s_ch1_full_gtxclk_r <= vfifo_mm2s_ch1_full_gtxclk;
    //vfifo_mm2s_ch1_full <= (|M01_FIFO_DATA_COUNT[31:10]) || (&M01_FIFO_DATA_COUNT[9:8]);
end

//// create single bit counter to ensure that any pulses are held for four gtx_clk cycles
always @(posedge gtx_clk_bufg) begin
    if (!gtx_resetn) begin
        vfifo_mm2s_ch1_full_gtxclk_r <= 0;
        vfifo_mm2s_ch1_full_gtxclk_ctr <= 2'b0;
    end
    else if (|vfifo_mm2s_ch1_full_gtxclk_ctr) begin
        vfifo_mm2s_ch1_full_gtxclk_ctr <= vfifo_mm2s_ch1_full_gtxclk_ctr -1;
        vfifo_mm2s_ch1_full_gtxclk_r <= vfifo_mm2s_ch1_full_gtxclk_r;
    end
    else if (vfifo_mm2s_ch1_full_gtxclk_r!=vfifo_mm2s_ch1_full_gtxclk) begin
       vfifo_mm2s_ch1_full_gtxclk_ctr <= 2'b11;
       vfifo_mm2s_ch1_full_gtxclk_r <= vfifo_mm2s_ch1_full_gtxclk;
    end
end
always @(posedge gtx_clk_bufg) begin
    if (!gtx_resetn)
        vfifo_mm2s_ch1_full_gtxclk_en <= 0;
    else
        vfifo_mm2s_ch1_full_gtxclk_en <= !vfifo_mm2s_ch1_full_gtxclk_en;
end

// hold prog full signals for at least four gtx_clk cycles
always @(posedge vfifo_mm2s_ch1_full_gtxclk_en) begin
        vfifo_mm2s_ch1_full_gtxclk_rr = vfifo_mm2s_ch1_full_gtxclk_r;
end

always @(posedge ui_clk) begin
    if (~aresetn) begin
        vfifo_mm2s_ch1_full_rr <= 0;
        vfifo_mm2s_ch1_full_r <= 0;
        vfifo_mm2s_ch1_full <= 0;
    end else begin
        vfifo_mm2s_ch1_full_r <= vfifo_mm2s_ch1_full_gtxclk_rr;
        vfifo_mm2s_ch1_full_rr <= vfifo_mm2s_ch1_full_r;
        if (vfifo_mm2s_ch1_full != vfifo_mm2s_ch1_full_rr)
            vfifo_mm2s_ch1_full <= vfifo_mm2s_ch1_full_rr;
        else
            vfifo_mm2s_ch1_full <= vfifo_mm2s_ch1_full;
    //vfifo_mm2s_ch1_full <= (|M01_FIFO_DATA_COUNT[31:10]) || (&M01_FIFO_DATA_COUNT[9:8]);
    end
end

assign vfifo_mm2s_channel_full = {vfifo_mm2s_ch1_full,vfifo_mm2s_ch0_full};

// Need .SYSCLK_TYPE("NO_BUFFER") for input from top level mmcm and bufgce
mig_7series_1 u_mig_7series_1 (
// Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [13:0]		ddr3_addr
    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
    .ddr3_dq                        (ddr3_dq),  // inout [63:0]		ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [7:0]		ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [7:0]		ddr3_dqs_p
    .init_calib_complete            (init_calib_complete),  // output			init_calib_complete

	.ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n
    .ddr3_dm                        (ddr3_dm),  // output [7:0]		ddr3_dm
    .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt

    // Application interface ports
    .ui_clk                         (ui_clk),  // output			ui_clk
    .ui_clk_sync_rst                (ui_clk_sync_rst),  // output			ui_clk_sync_rst
    .mmcm_locked                    (mmcm_locked),  // output			mmcm_locked
    .aresetn                        (aresetn),  // input			aresetn
    .app_sr_req                     (1'b0),  // input			app_sr_req
    .app_ref_req                    (1'b0),  // input			app_ref_req
    .app_zq_req                     (1'b0),  // input			app_zq_req

    .app_sr_active                  (app_sr_active),  // output			app_sr_active
    .app_ref_ack                    (app_ref_ack),  // output			app_ref_ack
    .app_zq_ack                     (app_zq_ack),  // output			app_zq_ack

    // Slave Interface Write Address Ports
    .s_axi_awid                     ({3'b0,m_axi_vfifo_awid[0]}),  // input [3:0]			s_axi_awid
    //.s_axi_awaddr                   (m_axi_vfifo_awaddr[31:2]),  // input [29:0]			s_axi_awaddr
    .s_axi_awaddr                   (m_axi_vfifo_awaddr[29:0]),  // input [29:0]			s_axi_awaddr
    .s_axi_awlen                    (m_axi_vfifo_awlen),  // input [7:0]			s_axi_awlen
    .s_axi_awsize                   (m_axi_vfifo_awsize),  // input [2:0]			s_axi_awsize
    .s_axi_awburst                  (m_axi_vfifo_awburst),  // input [1:0]			s_axi_awburst
    .s_axi_awlock                   (m_axi_vfifo_awlock),  // input [0:0]			s_axi_awlock
    .s_axi_awcache                  (m_axi_vfifo_awcache),  // input [3:0]			s_axi_awcache
    .s_axi_awprot                   (m_axi_vfifo_awprot),  // input [2:0]			s_axi_awprot
    .s_axi_awqos                    (m_axi_vfifo_awqos),  // input [3:0]			s_axi_awqos
    .s_axi_awvalid                  (m_axi_vfifo_awvalid),  // input			s_axi_awvalid
    .s_axi_awready                  (m_axi_vfifo_awready),  // output			s_axi_awready

    // Slave Interface Write Data Ports
    .s_axi_wdata                    (m_axi_vfifo_wdata),  // input [127:0]			s_axi_wdata
    .s_axi_wstrb                    (m_axi_vfifo_wstrb),  // input [15:0]			s_axi_wstrb
    .s_axi_wlast                    (m_axi_vfifo_wlast),  // input			s_axi_wlast
    .s_axi_wvalid                   (m_axi_vfifo_wvalid),  // input			s_axi_wvalid
    .s_axi_wready                   (m_axi_vfifo_wready),  // output			s_axi_wready

    // Slave Interface Write Response Ports
    .s_axi_bid                      (s_axi_mig_bid),  // output [3:0]			s_axi_bid
    .s_axi_bresp                    (m_axi_vfifo_bresp),  // output [1:0]			s_axi_bresp
    .s_axi_bvalid                   (m_axi_vfifo_bvalid),  // output			s_axi_bvalid
    .s_axi_bready                   (m_axi_vfifo_bready),  // input			s_axi_bready

    // Slave Interface Read Address Ports
    .s_axi_arid                     ({3'b0,m_axi_vfifo_arid[0]}),  // input [3:0]			s_axi_arid
   // .s_axi_araddr                   (m_axi_vfifo_araddr[31:2]),  // input [29:0]			s_axi_araddr
    .s_axi_araddr                   (m_axi_vfifo_araddr[29:0]),  // input [29:0]			s_axi_araddr
    .s_axi_arlen                    (m_axi_vfifo_arlen),  // input [7:0]			s_axi_arlen
    .s_axi_arsize                   (m_axi_vfifo_arsize),  // input [2:0]			s_axi_arsize
    .s_axi_arburst                  (m_axi_vfifo_arburst),  // input [1:0]			s_axi_arburst
    .s_axi_arlock                   (m_axi_vfifo_arlock),  // input [0:0]			s_axi_arlock
    .s_axi_arcache                  (m_axi_vfifo_arcache),  // input [3:0]			s_axi_arcache
    .s_axi_arprot                   (m_axi_vfifo_arprot),  // input [2:0]			s_axi_arprot
    .s_axi_arqos                    (m_axi_vfifo_arqos),  // input [3:0]			s_axi_arqos
    .s_axi_arvalid                  (m_axi_vfifo_arvalid),  // input			s_axi_arvalid
    .s_axi_arready                  (m_axi_vfifo_arready),  // output			s_axi_arready

    // Slave Interface Read Data Ports
    .s_axi_rid                      (s_axi_mig_rid),  // output [3:0]			s_axi_rid
    .s_axi_rdata                    (m_axi_vfifo_rdata),  // output [63:0]			s_axi_rdata
    .s_axi_rresp                    (m_axi_vfifo_rresp),  // output [1:0]			s_axi_rresp
    .s_axi_rlast                    (m_axi_vfifo_rlast),  // output			s_axi_rlast
    .s_axi_rvalid                   (m_axi_vfifo_rvalid),  // output			s_axi_rvalid
    .s_axi_rready                   (m_axi_vfifo_rready),  // input			s_axi_rready

    // Debug Ports
    .ddr3_ila_basic                 (ddr3_ila_basic_w),  // output [119:0]                               ddr3_ila_basic
    .ddr3_ila_wrpath                (ddr3_ila_wrpath_w),  // output [390:0]                               ddr3_ila_wrpath
    .ddr3_ila_rdpath                (ddr3_ila_rdpath_w),  // output [1023:0]                              ddr3_ila_rdpath
    .ddr3_vio_sync_out              (ddr3_vio_sync_out),  // input [13:0]                                 ddr3_vio_sync_out
    .dbg_pi_counter_read_val        (dbg_pi_counter_read_val),  // output [5:0]			dbg_pi_counter_read_val
    .dbg_sel_pi_incdec              (dbg_sel_pi_incdec),        // input			dbg_sel_pi_incdec
    .dbg_po_counter_read_val        (dbg_po_counter_read_val),  // output [8:0]			dbg_po_counter_read_val
    .dbg_sel_po_incdec              (dbg_sel_po_incdec),        // input			dbg_sel_po_incdec
    .dbg_byte_sel                   (dbg_byte_sel),             // input [3:0]			dbg_byte_sel
    .dbg_pi_f_inc                   (dbg_pi_f_inc),             // input			dbg_pi_f_inc
    .dbg_pi_f_dec                   (dbg_pi_f_dec),             // input			dbg_pi_f_dec
    .dbg_po_f_inc                   (dbg_po_f_inc),             // input			dbg_po_f_inc
    .dbg_po_f_stg23_sel             (dbg_po_f_stg23_sel),       // input			dbg_po_f_stg23_sel
    .dbg_po_f_dec                   (dbg_po_f_dec),             // input			dbg_po_f_dec
    // System Clock Ports
  // Need .SYSCLK_TYPE("NO_BUFFER") for input from top level mmcm and bufgce
    .sys_clk_i                      (sysclk_bufg),

  //  .sys_rst                        (sys_rst) // input sys_rst
    .sys_rst                        (cpu_reset)
);
assign m_axi_vfifo_bid = s_axi_mig_bid[0];
assign m_axi_vfifo_rid = s_axi_mig_rid[0];

assign dbg_dqs = 'b0;
assign dbg_bit = 'b0;
assign ddr3_vio_sync_out={dbg_dqs,dbg_bit};
assign dbg_sel_pi_incdec='b0;
assign dbg_sel_po_incdec='b0;
assign dbg_byte_sel= 'b0;             // input [3:0]            dbg_byte_sel
assign dbg_pi_f_inc= 'b0;               // input            dbg_pi_f_inc
assign dbg_pi_f_dec= 'b0;             // input            dbg_pi_f_dec
assign dbg_po_f_inc= 'b0;          // input            dbg_po_f_inc
assign dbg_po_f_stg23_sel= 'b0;       // input            dbg_po_f_stg23_sel
assign dbg_po_f_dec= 'b0;             // input            dbg_po_f_dec

always @(posedge ui_clk) begin
 aresetn <= ~ui_clk_sync_rst;
end

always @(posedge sysclk_bufg) begin
 sysclk_reset <= ~sysclk_resetn;
end

//axi_dma_0_exdes axi_dma_0_exdes_inst (
//  .clock (ui_clk),
//  .clock_lite (s_axi_clk),
//  .resetn (aresetn),
//  .start (dma_start),
//  .done  (dma_done),
//  .status (dma_status)
//);
//assign dma_start = dma_start_r;

//always @(posedge ui_clk) begin
//    if (ui_clk_sync_rst)
//        dma_start_r <= 1'b0;
//    else
//        dma_start_r <= 1'b1;
//end

//axi_dma_0 your_instance_name (
//  .s_axi_lite_aclk(s_axi_lite_aclk),                    // input wire s_axi_lite_aclk
//  .m_axi_sg_aclk(m_axi_sg_aclk),                        // input wire m_axi_sg_aclk
//  .m_axi_mm2s_aclk(m_axi_mm2s_aclk),                    // input wire m_axi_mm2s_aclk
//  .m_axi_s2mm_aclk(m_axi_s2mm_aclk),                    // input wire m_axi_s2mm_aclk
//  .axi_resetn(axi_resetn),                              // input wire axi_resetn
//  .s_axi_lite_awvalid(s_axi_lite_awvalid),              // input wire s_axi_lite_awvalid
//  .s_axi_lite_awready(s_axi_lite_awready),              // output wire s_axi_lite_awready
//  .s_axi_lite_awaddr(s_axi_lite_awaddr),                // input wire [9 : 0] s_axi_lite_awaddr
//  .s_axi_lite_wvalid(s_axi_lite_wvalid),                // input wire s_axi_lite_wvalid
//  .s_axi_lite_wready(s_axi_lite_wready),                // output wire s_axi_lite_wready
//  .s_axi_lite_wdata(s_axi_lite_wdata),                  // input wire [31 : 0] s_axi_lite_wdata
//  .s_axi_lite_bresp(s_axi_lite_bresp),                  // output wire [1 : 0] s_axi_lite_bresp
//  .s_axi_lite_bvalid(s_axi_lite_bvalid),                // output wire s_axi_lite_bvalid
//  .s_axi_lite_bready(s_axi_lite_bready),                // input wire s_axi_lite_bready
//  .s_axi_lite_arvalid(s_axi_lite_arvalid),              // input wire s_axi_lite_arvalid
//  .s_axi_lite_arready(s_axi_lite_arready),              // output wire s_axi_lite_arready
//  .s_axi_lite_araddr(s_axi_lite_araddr),                // input wire [9 : 0] s_axi_lite_araddr
//  .s_axi_lite_rvalid(s_axi_lite_rvalid),                // output wire s_axi_lite_rvalid
//  .s_axi_lite_rready(s_axi_lite_rready),                // input wire s_axi_lite_rready
//  .s_axi_lite_rdata(s_axi_lite_rdata),                  // output wire [31 : 0] s_axi_lite_rdata
//  .s_axi_lite_rresp(s_axi_lite_rresp),                  // output wire [1 : 0] s_axi_lite_rresp
//  .m_axi_sg_awaddr(m_axi_sg_awaddr),                    // output wire [31 : 0] m_axi_sg_awaddr
//  .m_axi_sg_awlen(m_axi_sg_awlen),                      // output wire [7 : 0] m_axi_sg_awlen
//  .m_axi_sg_awsize(m_axi_sg_awsize),                    // output wire [2 : 0] m_axi_sg_awsize
//  .m_axi_sg_awburst(m_axi_sg_awburst),                  // output wire [1 : 0] m_axi_sg_awburst
//  .m_axi_sg_awprot(m_axi_sg_awprot),                    // output wire [2 : 0] m_axi_sg_awprot
//  .m_axi_sg_awcache(m_axi_sg_awcache),                  // output wire [3 : 0] m_axi_sg_awcache
//  .m_axi_sg_awvalid(m_axi_sg_awvalid),                  // output wire m_axi_sg_awvalid
//  .m_axi_sg_awready(m_axi_sg_awready),                  // input wire m_axi_sg_awready
//  .m_axi_sg_wdata(m_axi_sg_wdata),                      // output wire [31 : 0] m_axi_sg_wdata
//  .m_axi_sg_wstrb(m_axi_sg_wstrb),                      // output wire [3 : 0] m_axi_sg_wstrb
//  .m_axi_sg_wlast(m_axi_sg_wlast),                      // output wire m_axi_sg_wlast
//  .m_axi_sg_wvalid(m_axi_sg_wvalid),                    // output wire m_axi_sg_wvalid
//  .m_axi_sg_wready(m_axi_sg_wready),                    // input wire m_axi_sg_wready
//  .m_axi_sg_bresp(m_axi_sg_bresp),                      // input wire [1 : 0] m_axi_sg_bresp
//  .m_axi_sg_bvalid(m_axi_sg_bvalid),                    // input wire m_axi_sg_bvalid
//  .m_axi_sg_bready(m_axi_sg_bready),                    // output wire m_axi_sg_bready
//  .m_axi_sg_araddr(m_axi_sg_araddr),                    // output wire [31 : 0] m_axi_sg_araddr
//  .m_axi_sg_arlen(m_axi_sg_arlen),                      // output wire [7 : 0] m_axi_sg_arlen
//  .m_axi_sg_arsize(m_axi_sg_arsize),                    // output wire [2 : 0] m_axi_sg_arsize
//  .m_axi_sg_arburst(m_axi_sg_arburst),                  // output wire [1 : 0] m_axi_sg_arburst
//  .m_axi_sg_arprot(m_axi_sg_arprot),                    // output wire [2 : 0] m_axi_sg_arprot
//  .m_axi_sg_arcache(m_axi_sg_arcache),                  // output wire [3 : 0] m_axi_sg_arcache
//  .m_axi_sg_arvalid(m_axi_sg_arvalid),                  // output wire m_axi_sg_arvalid
//  .m_axi_sg_arready(m_axi_sg_arready),                  // input wire m_axi_sg_arready
//  .m_axi_sg_rdata(m_axi_sg_rdata),                      // input wire [31 : 0] m_axi_sg_rdata
//  .m_axi_sg_rresp(m_axi_sg_rresp),                      // input wire [1 : 0] m_axi_sg_rresp
//  .m_axi_sg_rlast(m_axi_sg_rlast),                      // input wire m_axi_sg_rlast
//  .m_axi_sg_rvalid(m_axi_sg_rvalid),                    // input wire m_axi_sg_rvalid
//  .m_axi_sg_rready(m_axi_sg_rready),                    // output wire m_axi_sg_rready
//  .m_axi_mm2s_araddr(m_axi_mm2s_araddr),                // output wire [31 : 0] m_axi_mm2s_araddr
//  .m_axi_mm2s_arlen(m_axi_mm2s_arlen),                  // output wire [7 : 0] m_axi_mm2s_arlen
//  .m_axi_mm2s_arsize(m_axi_mm2s_arsize),                // output wire [2 : 0] m_axi_mm2s_arsize
//  .m_axi_mm2s_arburst(m_axi_mm2s_arburst),              // output wire [1 : 0] m_axi_mm2s_arburst
//  .m_axi_mm2s_arprot(m_axi_mm2s_arprot),                // output wire [2 : 0] m_axi_mm2s_arprot
//  .m_axi_mm2s_arcache(m_axi_mm2s_arcache),              // output wire [3 : 0] m_axi_mm2s_arcache
//  .m_axi_mm2s_arvalid(m_axi_mm2s_arvalid),              // output wire m_axi_mm2s_arvalid
//  .m_axi_mm2s_arready(m_axi_mm2s_arready),              // input wire m_axi_mm2s_arready
//  .m_axi_mm2s_rdata(m_axi_mm2s_rdata),                  // input wire [511 : 0] m_axi_mm2s_rdata
//  .m_axi_mm2s_rresp(m_axi_mm2s_rresp),                  // input wire [1 : 0] m_axi_mm2s_rresp
//  .m_axi_mm2s_rlast(m_axi_mm2s_rlast),                  // input wire m_axi_mm2s_rlast
//  .m_axi_mm2s_rvalid(m_axi_mm2s_rvalid),                // input wire m_axi_mm2s_rvalid
//  .m_axi_mm2s_rready(m_axi_mm2s_rready),                // output wire m_axi_mm2s_rready
//  .mm2s_prmry_reset_out_n(mm2s_prmry_reset_out_n),      // output wire mm2s_prmry_reset_out_n
//  .m_axis_mm2s_tdata(m_axis_mm2s_tdata),                // output wire [511 : 0] m_axis_mm2s_tdata
//  .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),                // output wire [63 : 0] m_axis_mm2s_tkeep
//  .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),              // output wire m_axis_mm2s_tvalid
//  .m_axis_mm2s_tready(m_axis_mm2s_tready),              // input wire m_axis_mm2s_tready
//  .m_axis_mm2s_tlast(m_axis_mm2s_tlast),                // output wire m_axis_mm2s_tlast
//  .mm2s_cntrl_reset_out_n(mm2s_cntrl_reset_out_n),      // output wire mm2s_cntrl_reset_out_n
//  .m_axis_mm2s_cntrl_tdata(m_axis_mm2s_cntrl_tdata),    // output wire [31 : 0] m_axis_mm2s_cntrl_tdata
//  .m_axis_mm2s_cntrl_tkeep(m_axis_mm2s_cntrl_tkeep),    // output wire [3 : 0] m_axis_mm2s_cntrl_tkeep
//  .m_axis_mm2s_cntrl_tvalid(m_axis_mm2s_cntrl_tvalid),  // output wire m_axis_mm2s_cntrl_tvalid
//  .m_axis_mm2s_cntrl_tready(m_axis_mm2s_cntrl_tready),  // input wire m_axis_mm2s_cntrl_tready
//  .m_axis_mm2s_cntrl_tlast(m_axis_mm2s_cntrl_tlast),    // output wire m_axis_mm2s_cntrl_tlast
//  .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr),                // output wire [31 : 0] m_axi_s2mm_awaddr
//  .m_axi_s2mm_awlen(m_axi_s2mm_awlen),                  // output wire [7 : 0] m_axi_s2mm_awlen
//  .m_axi_s2mm_awsize(m_axi_s2mm_awsize),                // output wire [2 : 0] m_axi_s2mm_awsize
//  .m_axi_s2mm_awburst(m_axi_s2mm_awburst),              // output wire [1 : 0] m_axi_s2mm_awburst
//  .m_axi_s2mm_awprot(m_axi_s2mm_awprot),                // output wire [2 : 0] m_axi_s2mm_awprot
//  .m_axi_s2mm_awcache(m_axi_s2mm_awcache),              // output wire [3 : 0] m_axi_s2mm_awcache
//  .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid),              // output wire m_axi_s2mm_awvalid
//  .m_axi_s2mm_awready(m_axi_s2mm_awready),              // input wire m_axi_s2mm_awready
//  .m_axi_s2mm_wdata(m_axi_s2mm_wdata),                  // output wire [511 : 0] m_axi_s2mm_wdata
//  .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb),                  // output wire [63 : 0] m_axi_s2mm_wstrb
//  .m_axi_s2mm_wlast(m_axi_s2mm_wlast),                  // output wire m_axi_s2mm_wlast
//  .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid),                // output wire m_axi_s2mm_wvalid
//  .m_axi_s2mm_wready(m_axi_s2mm_wready),                // input wire m_axi_s2mm_wready
//  .m_axi_s2mm_bresp(m_axi_s2mm_bresp),                  // input wire [1 : 0] m_axi_s2mm_bresp
//  .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid),                // input wire m_axi_s2mm_bvalid
//  .m_axi_s2mm_bready(m_axi_s2mm_bready),                // output wire m_axi_s2mm_bready
//  .s2mm_prmry_reset_out_n(s2mm_prmry_reset_out_n),      // output wire s2mm_prmry_reset_out_n
//  .s_axis_s2mm_tdata(s_axis_s2mm_tdata),                // input wire [511 : 0] s_axis_s2mm_tdata
//  .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),                // input wire [63 : 0] s_axis_s2mm_tkeep
//  .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),              // input wire s_axis_s2mm_tvalid
//  .s_axis_s2mm_tready(s_axis_s2mm_tready),              // output wire s_axis_s2mm_tready
//  .s_axis_s2mm_tlast(s_axis_s2mm_tlast),                // input wire s_axis_s2mm_tlast
//  .s2mm_sts_reset_out_n(s2mm_sts_reset_out_n),          // output wire s2mm_sts_reset_out_n
//  .s_axis_s2mm_sts_tdata(s_axis_s2mm_sts_tdata),        // input wire [31 : 0] s_axis_s2mm_sts_tdata
//  .s_axis_s2mm_sts_tkeep(s_axis_s2mm_sts_tkeep),        // input wire [3 : 0] s_axis_s2mm_sts_tkeep
//  .s_axis_s2mm_sts_tvalid(s_axis_s2mm_sts_tvalid),      // input wire s_axis_s2mm_sts_tvalid
//  .s_axis_s2mm_sts_tready(s_axis_s2mm_sts_tready),      // output wire s_axis_s2mm_sts_tready
//  .s_axis_s2mm_sts_tlast(s_axis_s2mm_sts_tlast),        // input wire s_axis_s2mm_sts_tlast
//  .mm2s_introut(mm2s_introut),                          // output wire mm2s_introut
//  .s2mm_introut(s2mm_introut),                          // output wire s2mm_introut
//  .axi_dma_tstvec(axi_dma_tstvec)                      // output wire [31 : 0] axi_dma_tstvec
//);

//ila_axis_adc ila_axis_adc_inst(
//    .clk (ui_clk),
//    //.clk(sysclk_bufg),
//     .probe0(axis_adc_tdata),   //wire [ADC_AXI_DATA_WIDTH-1:0]
//     .probe1(axis_adc_tvalid),
//     .probe2(axis_adc_tready),
//     .probe3(axis_adc_tlast),    //wire axis_adc_tlast;
//     .probe4(axis_adc_tkeep),   //wire [ADC_AXI_DATA_WIDTH/8-1:0] axis_adc_tkeep;
//     .probe5(axis_adc_tid),     //wire [ADC_AXI_TID_WIDTH-1:0]    axis_adc_tid;
//     .probe6(axis_adc_tdest),   //wire [ADC_AXI_TDEST_WIDTH-1:0]  axis_adc_tdest;
//     .probe7(axis_adc_tuser),   //wire [ADC_AXI_TUSER_WIDTH-1:0]  axis_adc_tuser;
//     .probe8(axis_adc_tstrb),    //wire [ADC_AXI_DATA_WIDTH/8-1:0] axis_adc_tstrb;
//     .probe9(S00_ARB_REQ_SUPPRESS),   // input wire S00_ARB_REQ_SUPPRESS
//     .probe10(S00_DECODE_ERR),              // output wire S00_DECODE_ERR
//     .probe11(S00_FIFO_DATA_COUNT),    // output wire [31 : 0] S00_FIFO_DATA_COUNT

//     .probe12(s_axis_vfifo_tdata),      // wire [MIG_AXI_DATA_WIDTH-1 : 0]
//    .probe13(s_axis_vfifo_tkeep),       // wire [MIG_AXI_DATA_WIDTH/8-1 : 0]
//    .probe14(s_axis_vfifo_tstrb),       // wire [MIG_AXI_DATA_WIDTH/8-1 : 0]
//    .probe15(s_axis_vfifo_tvalid),
//    .probe16(s_axis_vfifo_tready),
//    .probe17(s_axis_vfifo_tlast),
//    .probe18(s_axis_vfifo_tid),
//    .probe19(s_axis_vfifo_tdest)
//);

//ila_axis_adc_pkt ila_axis_adc_pkt_inst(
//    .clk (gtx_clk_bufg),
//     .probe0(adc_pkt_axis_tdata),
//     .probe1(adc_pkt_axis_tvalid),
//     .probe2(adc_pkt_axis_tready),
//     .probe3(adc_pkt_axis_tlast),//wire                adc_pkt_axis_tlast;
//     .probe4(adc_pkt_axis_tuser),//wire                adc_pkt_axis_tuser;
//     .probe5(adc_pkt_axis_tstrb),//wire [0:0]          adc_pkt_axis_tstrb;
//     .probe6(adc_pkt_axis_tkeep),//wire [0:0]          adc_pkt_axis_tkeep;
//     .probe7(adc_pkt_axis_tid),//wire [0:0]          adc_pkt_axis_tid;
//     .probe8(adc_pkt_axis_tdest)//wire [0:0]          adc_pkt_axis_tdest;
//);

//ila_axi_mm2s_ic ila_axi_mm2s_ic_inst(
//     .clk (ui_clk),
//    //.clk (sysclk_bufg),              // input wire M00_AXIS_ACLK
//     .probe0(M00_AXIS_TDATA),           // 64 bits
//     .probe1(M00_AXIS_TKEEP),
//     .probe2(M00_AXIS_TSTRB),
//     .probe3(M00_AXIS_TVALID),
//     .probe4(M00_AXIS_TREADY),
//     .probe5(M00_AXIS_TLAST),
//     .probe6(M00_AXIS_TID),
//     .probe7(M00_AXIS_TDEST),
//     .probe8(M00_FIFO_DATA_COUNT)
//);

//ila_axis_vfifo   ila_axis_vfifo_inst(
//    .clk(ui_clk),
//    .probe0(vfifo_mm2s_channel_full),
//    .probe1(s_axis_vfifo_tdata),        // wire [MIG_AXI_DATA_WIDTH-1 : 0]
//    .probe2(s_axis_vfifo_tkeep),
//    .probe3(s_axis_vfifo_tstrb),
//    .probe4(s_axis_vfifo_tvalid),
//    .probe5(s_axis_vfifo_tready),
//    .probe6(s_axis_vfifo_tlast),
//    .probe7(s_axis_vfifo_tid),
//    .probe8(s_axis_vfifo_tdest),
//    .probe9(m_axis_vfifo_tdata),        // wire [MIG_AXI_DATA_WIDTH-1 : 0]
//    .probe10(m_axis_vfifo_tkeep),
//    .probe11(m_axis_vfifo_tstrb),
//    .probe12(m_axis_vfifo_tvalid),
//    .probe13(m_axis_vfifo_tready),
//    .probe14(m_axis_vfifo_tlast),
//    .probe15(m_axis_vfifo_tid),
//    .probe16(m_axis_vfifo_tdest),
//    .probe17(vfifo_s2mm_channel_full),    // output wire [1 : 0] vfifo_s2mm_channel_full
//    .probe18(vfifo_mm2s_channel_empty),  // output wire [1 : 0] vfifo_mm2s_channel_empty
//    .probe19(vfifo_idle)                // output wire [1 : 0]
//);

endmodule
