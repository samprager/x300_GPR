`timescale 1ps/1ps

module cmd_decoder_top #(
    parameter SIMULATION = 1,
    parameter CHIRP_PRF_INT_COUNT_INIT = 32'h00000000,
    parameter CHIRP_PRF_FRAC_COUNT_INIT = 32'h927c0000,
    parameter DEST_ADDR       =48'h985aebdb066f,
    parameter SRC_ADDR        = 48'h5a0102030405
)
(
input s_axi_aclk,
input s_axi_resetn,

input clk_fmc150,
input resetn_fmc150,

input gtx_clk_bufg,
input gtx_resetn,

output [7:0]  gpio_led,        // : out   std_logic_vector(7 downto 0);
input [7:0]  gpio_dip_sw,   //   : in    std_logic_vector(7 downto 0);
    // data from ADC Data fifo
output       [7:0]                     tx_axis_tdata,
output                                 tx_axis_tvalid,
output                                 tx_axis_tlast,
input                                  tx_axis_tready,

input       [7:0]                     rx_axis_tdata,
input                                 rx_axis_tvalid,
input                                 rx_axis_tlast,
output                                rx_axis_tready

);

  localparam RX_WR_CMD_DWIDTH = 224;
  localparam RX_RD_CMD_DWIDTH = 32;
  localparam RX_CMD_ID_WIDTH = 32;

  localparam ADC_AXI_DATA_WIDTH = 512;//64;
  localparam ADC_AXI_TID_WIDTH = 1;
  localparam ADC_AXI_TDEST_WIDTH = 1;
  localparam ADC_AXI_TUSER_WIDTH = 1;
  localparam ADC_AXI_STREAM_ID = 1'b0;
  localparam ADC_AXI_STREAM_DEST = 1'b1;

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

// Control Module Signals
wire [3:0] fmc150_status_vector;
wire chirp_ready;          // continuous high when dac ready
wire chirp_active;         // continuous high while chirping
wire chirp_done;           // single pulse when chirp finished
wire chirp_init;          // single pulse to initiate chirp
wire chirp_enable;        // continuous high while chirp enabled
wire adc_enable;          // high while adc samples saved


wire [7:0] fmc150_ctrl_bus;
wire [7:0] fmc150_ctrl_bus_bypass;
//fmc150_ctrl_bus = {3'b0,ddc_duc_bypass,digital_mode,adc_out_dac_in,external_clock,gen_adc_test_pattern};

wire [67:0] fmc150_spi_ctrl_bus_in;
wire [47:0] fmc150_spi_ctrl_bus_out = 48'b0;

wire [7:0] ethernet_ctrl_bus;
wire [7:0] ethernet_ctrl_bus_bypass;
// ethernet_ctrl_bus = {3'b0,enable_adc_pkt,gen_tx_data,chk_tx_data,mac_speed};

wire [127:0] chirp_parameters;
// chirp_parameters = {32'b0,chirp_freq_offset,chirp_tuning_word_coeff,chirp_count_max};

wire [31:0]   cmd_pkt_s_axis_tdata;
wire          cmd_pkt_s_axis_tvalid;
wire          cmd_pkt_s_axis_tlast;
wire          cmd_pkt_s_axis_tready;
wire [31:0]   cmd_pkt_s_axis_tuser;
wire [3:0]    cmd_pkt_s_axis_tdest;
wire    [3:0] cmd_pkt_s_axis_tid;
wire    [3:0] cmd_pkt_s_axis_tkeep;

wire [31:0]   cmd_pkt_axis_tdata;
wire          cmd_pkt_axis_tvalid;
wire          cmd_pkt_axis_tlast;
wire          cmd_pkt_axis_tready;

wire [31:0]   chirp_cmd_word;

wire [RX_WR_CMD_DWIDTH-1:0]   cmd_pkt_m_axis_tdata;
wire          cmd_pkt_m_axis_tvalid;
wire          cmd_pkt_m_axis_tlast;
wire          cmd_pkt_m_axis_tready;
wire [(RX_WR_CMD_DWIDTH)/8-1:0]   cmd_pkt_m_axis_tkeep;

wire  [RX_CMD_ID_WIDTH-1:0]        cmd_pkt_id;
wire  [RX_CMD_ID_WIDTH/8-1:0]        cmd_pkt_id_tkeep;

wire [RX_WR_CMD_DWIDTH-1:0]   cmd_axis_tdata;
wire          cmd_axis_tvalid;
wire          cmd_axis_tlast;
wire          cmd_axis_tready;
wire [RX_WR_CMD_DWIDTH/8-1:0]   cmd_axis_tkeep;

//`include "../../source/include/rx_cmd_1s4m_ic.v"
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tdata;
wire                            ch_wr_cmd_axis_tvalid;
wire                            ch_wr_cmd_axis_tlast;
wire                            ch_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]   ch_wr_cmd_axis_tkeep;
wire [3:0]                      ch_wr_cmd_axis_tdest;
wire [3:0]                      ch_wr_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     ch_wr_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     ch_wr_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   ch_wr_cmd_id_tkeep;

wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_wr_cmd_axis_tdata;
wire                            sp_wr_cmd_axis_tvalid;
wire                            sp_wr_cmd_axis_tlast;
wire                            sp_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_wr_cmd_axis_tkeep;
wire [3:0]                      sp_wr_cmd_axis_tdest;
wire [3:0]                      sp_wr_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     sp_wr_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     sp_wr_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   sp_wr_cmd_id_tkeep;

wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_rd_cmd_axis_tdata;
wire                            ch_rd_cmd_axis_tvalid;
wire                            ch_rd_cmd_axis_tlast;
wire                            ch_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    ch_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  ch_rd_cmd_axis_tkeep;
wire [3:0]                      ch_rd_cmd_axis_tdest;
wire [3:0]                      ch_rd_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     ch_rd_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     ch_rd_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   ch_rd_cmd_id_tkeep;

wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_rd_cmd_axis_tdata;
wire                            sp_rd_cmd_axis_tvalid;
wire                            sp_rd_cmd_axis_tlast;
wire                            sp_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_rd_cmd_axis_tkeep;
wire [3:0]                      sp_rd_cmd_axis_tdest;
wire [3:0]                      sp_rd_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     sp_rd_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     sp_rd_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   sp_rd_cmd_id_tkeep;

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

wire S00_CMD_DECODE_ERR;           // output wire S00_DECODE_ERR
wire [31:0] S00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] S00_FIFO_DATA_COUNT
wire [31:0] M00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M00_FIFO_DATA_COUNT
wire [31:0] M01_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M01_FIFO_DATA_COUNT
wire [31:0] M02_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M02_FIFO_DATA_COUNT
wire [31:0] M03_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M03_FIFO_DATA_COUNT

wire [31:0] cmd_fifo_axis_data_count;        // output wire [31 : 0] axis_data_count
wire [31:0] cmd_fifo_axis_wr_data_count;  // output wire [31 : 0] axis_wr_data_count
wire [31:0] cmd_fifo_axis_rd_data_count;  // output wire [31 : 0] axis_rd_data_count



wire data_tx_ready;        // high when ready to transmit
wire data_tx_active;       // high while data being transmitted
wire data_tx_done;         // single pule when done transmitting
wire data_tx_init;        // single pulse to start tx data
wire data_tx_enable;      // continuous high while transmit enabled

wire tlast_hold0;
wire tlast_hold1;
wire tlast_hold2;
wire tlast_hold8;

reg tlast_hold_en;
reg hold_en = 0;

wire clk_245_76MHz;
wire clk_245_rst;

// Start of User Design top instance
//***************************************************************************
// The User design is instantiated below. The memory interface ports are
// connected to the top-level and the application interface ports are
// connected to the traffic generator module. This provides a reference
// for connecting the memory controller to system.
//***************************************************************************

assign clk_245_76MHz = clk_fmc150;
assign clk_245_rst = !resetn_fmc150;

assign tx_axis_tdata = 'b0;
assign tx_axis_tvalid = 'b0;
assign tx_axis_tlast = 'b0;

control_module #(
    .SIMULATION(SIMULATION),
    .RX_WR_CMD_DWIDTH (RX_WR_CMD_DWIDTH),
    .CHIRP_PRF_INT_COUNT_INIT(CHIRP_PRF_INT_COUNT_INIT),
    .CHIRP_PRF_FRAC_COUNT_INIT(CHIRP_PRF_FRAC_COUNT_INIT)
)control_module_inst(
  .s_axi_aclk   (s_axi_aclk),
  .s_axi_resetn  (s_axi_resetn),
// for future use

  // input                               eth_ctrl_en,
  // input [8:0]                         axis_eth_ctrl_tdata,
  // input [8:0]                         axis_eth_ctrl_tkeep,
  // input                               axis_eth_ctrl_tvalid,
  // output                              axis_eth_ctrl_tready,

  .gpio_dip_sw                       (gpio_dip_sw),
  .gpio_led                         (gpio_led),

//  input clk_mig,              // 200 MHZ OR 100 MHz
//  input mig_init_calib_complete,
  .clk_fmc150 (clk_fmc150),           // 245.76 MHz
  .resetn_fmc150(resetn_fmc150),

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

chirp_dds_top #(
  .SIMULATION(SIMULATION),
  .ADC_AXI_DATA_WIDTH(ADC_AXI_DATA_WIDTH),
  .ADC_AXI_TID_WIDTH(ADC_AXI_TID_WIDTH),
  .ADC_AXI_TDEST_WIDTH(ADC_AXI_TDEST_WIDTH),
  .ADC_AXI_TUSER_WIDTH(ADC_AXI_TUSER_WIDTH),
  .ADC_AXI_STREAM_ID(ADC_AXI_STREAM_ID),
  .ADC_AXI_STREAM_DEST(ADC_AXI_STREAM_DEST)

  )
  chirp_dds_top_inst (
  .clk_245 (clk_fmc150),
  .clk_245_rst (!resetn_fmc150),

  .aclk (s_axi_aclk),
  .aresetn (s_axi_resetn),

  .cpu_reset(!resetn_fmc150),
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

   .wf_read_ready(wf_read_ready),
   .wfrm_axis_tdata(wfout_axis_tdata),
   .wfrm_axis_tvalid(wfout_axis_tvalid),
   .wfrm_axis_tlast(wfout_axis_tlast),
   .wfrm_axis_tready(wfout_axis_tready),

   .fmc150_status_vector                (fmc150_status_vector),
   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable),

   .chirp_control_word         (chirp_parameters[127:96]),
   .chirp_freq_offset          (chirp_parameters[95:64]),
   .chirp_tuning_word_coeff    (chirp_parameters[63:32]),
   .chirp_count_max            (chirp_parameters[31:0]),

  // .fmc150_ctrl_bus (fmc150_ctrl_bus),
    .fmc150_ctrl_bus (fmc150_ctrl_bus),
    .fmc150_spi_ctrl_bus_in (fmc150_spi_ctrl_bus_in),
    .fmc150_spi_ctrl_bus_out (fmc150_spi_ctrl_bus_out)

  );

  assign axis_adc_tready = 1'b1;

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


// rx_cmd_axis_data_fifo rx_cmd_axis_data_fifo_inst (
//   .s_axis_aresetn(gtx_resetn),          // input wire s_axis_aresetn
//   .m_axis_aresetn(s_axi_resetn),          // input wire m_axis_aresetn
//   .s_axis_aclk(gtx_clk_bufg),                // input wire s_axis_aclk
//   .s_axis_tvalid(cmd_pkt_m_axis_tvalid),            // input wire s_axis_tvalid
//   .s_axis_tready(cmd_pkt_m_axis_tready),            // output wire s_axis_tready
//   .s_axis_tdata(cmd_pkt_m_axis_tdata),              // input wire [191 : 0] s_axis_tdata
//   .s_axis_tkeep(cmd_pkt_m_axis_tkeep),              // input wire [23 : 0] s_axis_tkeep
//   .s_axis_tlast(cmd_pkt_m_axis_tlast),              // input wire s_axis_tlast
//
//   .m_axis_aclk(s_axi_aclk),                // input wire m_axis_aclk
//   .m_axis_tvalid(cmd_axis_tvalid),            // output wire m_axis_tvalid
//   .m_axis_tready(cmd_axis_tready),            // input wire m_axis_tready
//   .m_axis_tdata(cmd_axis_tdata),              // output wire [191 : 0] m_axis_tdata
//   .m_axis_tkeep(cmd_axis_tkeep),              // output wire [23 : 0] m_axis_tkeep
//   .m_axis_tlast(cmd_axis_tlast),              // input wire m_axis_tlast
//   .axis_data_count(cmd_fifo_axis_data_count),        // output wire [31 : 0] axis_data_count
//   .axis_wr_data_count(cmd_fifo_axis_wr_data_count),  // output wire [31 : 0] axis_wr_data_count
//   .axis_rd_data_count(cmd_fifo_axis_rd_data_count)  // output wire [31 : 0] axis_rd_data_count
// );

// rx_cmd_axis_dwidth_converter rx_cmd_axis_dwidth_converter_inst (
//   .aclk(gtx_clk_bufg),                    // input wire aclk
//   .aresetn(gtx_resetn),              // input wire aresetn
//   .s_axis_tvalid(cmd_pkt_s_axis_tvalid),  // input wire s_axis_tvalid
//   .s_axis_tready(cmd_pkt_s_axis_tready),  // output wire s_axis_tready
//   .s_axis_tdata(cmd_pkt_s_axis_tdata),    // input wire [31 : 0] s_axis_tdata
//   .s_axis_tlast(cmd_pkt_s_axis_tlast),    // input wire s_axis_tlast
//   .m_axis_tvalid(cmd_pkt_m_axis_tvalid),  // output wire m_axis_tvalid
//   .m_axis_tready(cmd_pkt_m_axis_tready),  // input wire m_axis_tready
//   .m_axis_tdata({cmd_pkt_m_axis_tdata,cmd_pkt_id}),    // output wire [191 : 0] m_axis_tdata
//   .m_axis_tkeep({cmd_pkt_m_axis_tkeep,cmd_pkt_id_tkeep}),    // output wire [23 : 0] m_axis_tkeep
//   .m_axis_tlast(cmd_pkt_m_axis_tlast)    // output wire m_axis_tlast
// );

// assign cmd_axis_tdata = ch_wr_cmd_axis_tdata[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:RX_CMD_ID_WIDTH];
// assign cmd_axis_tvalid = ch_wr_cmd_axis_tvalid;
// assign cmd_axis_tlast = ch_wr_cmd_axis_tlast;
// assign cmd_axis_tkeep = ch_wr_cmd_axis_tkeep[(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:RX_CMD_ID_WIDTH/8];
//
// assign ch_wr_cmd_axis_tready = cmd_axis_tready;
// assign sp_wr_cmd_axis_tready = 1;
// assign ch_rd_cmd_axis_tready = 1;
// assign sp_rd_cmd_axis_tready = 1;
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
     .axi_tclk (gtx_clk_bufg),
     .axi_tresetn (gtx_resetn),

     .enable_rx_decode        (1'b1),
     .speed                  (2'b10),

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
       .axi_tclk (gtx_clk_bufg),
       .axi_tresetn (gtx_resetn),

       .enable_rx_decode        (1'b1),
   // data from the RX data path
           .cmd_axis_tdata       (cmd_pkt_axis_tdata),
           .cmd_axis_tvalid       (cmd_pkt_axis_tvalid),
           .cmd_axis_tlast       (cmd_pkt_axis_tlast),
           .cmd_axis_tready      (cmd_pkt_axis_tready),

   // data TO the TX data path
           .tdata       (cmd_pkt_s_axis_tdata),
           .tvalid       (cmd_pkt_s_axis_tvalid),
           .tlast       (cmd_pkt_s_axis_tlast),
           .tuser       (cmd_pkt_s_axis_tuser),
           .tdest       (cmd_pkt_s_axis_tdest),
           .tid       (cmd_pkt_s_axis_tid),
           .tkeep       (cmd_pkt_s_axis_tkeep),
           .tready      (cmd_pkt_s_axis_tready)



);

signal_hold #(
    .HOLD_CLOCKS (0),
    .DATA_WIDTH (1)
) signal_hold_tlast0 (
    .clk(gtx_clk_bufg),
    .aresetn(gtx_resetn),
    .data_in(rx_axis_tlast),
    .data_out (tlast_hold0)
);

signal_hold #(
    .HOLD_CLOCKS (1),
    .DATA_WIDTH (1)
) signal_hold_tlast1 (
    .clk(gtx_clk_bufg),
    .aresetn(gtx_resetn),
    .data_in(rx_axis_tlast),
    .data_out (tlast_hold1)
);

signal_hold #(
    .HOLD_CLOCKS (2),
    .DATA_WIDTH (1)
) signal_hold_tlast2 (
    .clk(gtx_clk_bufg),
    .aresetn(gtx_resetn),
    .data_in(rx_axis_tlast),
    .data_out (tlast_hold2)
);

signal_hold #(
    .HOLD_CLOCKS (2),
    .DATA_WIDTH (1)
) signal_hold_tlast8 (
    .clk(gtx_clk_bufg),
    .aresetn(gtx_resetn),
    .data_in((rx_axis_tdata[0]^rx_axis_tdata[1])),
    .data_out (tlast_hold8)
);

always @(posedge gtx_clk_bufg) begin
if (!gtx_resetn)
    hold_en <= 0;
else
    hold_en <= !hold_en;
end

always @(posedge hold_en) begin
    tlast_hold_en = tlast_hold2;
end


endmodule
