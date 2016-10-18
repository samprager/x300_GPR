//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 10/11/2016 04:32:51 PM
// Design Name:
// Module Name: wavegen_block
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

module wavegen_block #(
    parameter CHIRP_TUNING_COEF_INIT = 32'b1,
    parameter CHIRP_COUNT_MAX_INIT = 32'h00000dff, // 3584 samples
    parameter CHIRP_FREQ_OFFSET_INIT = 32'h0b00, // 2816 -> 10.56 MHz min freq
    parameter CHIRP_CTRL_WORD_INIT = 32'h20,

    parameter SR_CH_COUNTER_ADDR = 0,
    parameter SR_CH_TUNING_COEF_ADDR = 1,
    parameter SR_CH_FREQ_OFFSET_ADDR = 2,
    parameter SR_CH_CTRL_WORD_ADDR = 3
 )(
        input clk,
        input rst,
        output [15:0] awg_out_i, output [15:0] awg_out_q,
        output awg_data_valid,
        output [32:0] awg_data_len,

        input set_stb, input [7:0] set_addr, input [31:0] set_data,

        input [31:0]                     wr_axis_tdata,
        input                            wr_axis_tvalid,
        input                            wr_axis_tlast,
        output                            wr_axis_tready,
        input [31:0]                     wr_axis_tuser,
        input [3:0]                      wr_axis_tkeep,
        input [3:0]                      wr_axis_tdest,
        input [3:0]                      wr_axis_tid,

        input [31:0]                     chirp_control_word,

      // Control Module signals
        output awg_ready,
        output awg_done,
        output awg_active,
        input  awg_init,
        input  awg_enable,
        input  adc_enable

   );


wire [31:0] chirp_freq_offset;
wire [31:0] chirp_tuning_word_coeff;
wire [31:0] chirp_count_max;

//////////////////////////////////////////
// Waveform Data from Network  wires
//////////////////////////////////////////

// wire [31:0]                     wr_axis_tdata;
// wire                            wr_axis_tvalid;
// wire                            wr_axis_tlast;
// wire                            wr_axis_tready;
// wire [31:0]                     wr_axis_tuser;
// wire [3:0]                      wr_axis_tkeep;
// wire [3:0]                      wr_axis_tdest;
// wire [3:0]                      wr_axis_tid;

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

wire [31:0] wfout_size;

wire [15:0] wfrm_data_i;
wire [15:0] wfrm_data_q;
wire wfrm_data_valid;

wire [15:0] chirp_data_i;
wire [15:0] chirp_data_q;
wire chirp_data_valid;

wire [31:0] adc_counter;
wire adc_data_valid;

// wire data_valid;
//  reg [7:0] dds_route_ctrl_reg;
wire [1:0] dds_route_ctrl_u;
wire [1:0] dds_route_ctrl_l;
wire [1:0] dds_source_ctrl;
wire dds_source_select;

reg [1:0] dds_route_ctrl_u_r;
reg [1:0] dds_route_ctrl_l_r;
reg [1:0] dds_source_ctrl_r;

wire wfrm_ready;
wire wfrm_done;
wire wfrm_active;
wire wfrm_init;
wire wfrm_enable;

wire dds_ready;
wire dds_done;
wire dds_active;
wire dds_init;
wire dds_enable;

setting_reg #(.my_addr(SR_CH_COUNTER_ADDR), .at_reset(CHIRP_COUNT_MAX_INIT)) sr_ch_counter_max (
  .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
  .in(set_data),.out(chirp_count_max),.changed());


setting_reg #(.my_addr(SR_CH_TUNING_COEF_ADDR), .at_reset(CHIRP_TUNING_COEF_INIT)) sr_ch_tuning_coef (
  .clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
  .in(set_data),.out(chirp_tuning_word_coeff),.changed());

setting_reg #(.my_addr(SR_CH_FREQ_OFFSET_ADDR), .at_reset(CHIRP_FREQ_OFFSET_INIT)) sr_ch_freq_offset (
.clk(clk),.rst(rst),.strobe(set_stb),.addr(set_addr),
.in(set_data),.out(chirp_freq_offset),.changed());

CHIRP_DDS #(.DDS_LATENCY(DDS_LATENCY)) CHIRP_DDS_INST(
    .clock  (clk),
	.reset	(rst),
	.if_out_i  (chirp_data_i),			//i data to dac, 16-bit
	.if_out_q  (chirp_data_q),		    // q data to dac, 16-bit,
    .if_out_valid (chirp_data_valid),

  .chirp_ready (dds_ready),
  .chirp_done (dds_done),
  .chirp_active (dds_active),
  .chirp_init  (dds_init),
  .chirp_enable  (dds_enable),
 // .adc_enable    (adc_enable),

//        .dac_loopback               (chirp_control_word[0]),
  .freq_offset_in (chirp_freq_offset),
  .tuning_word_coeff_in (chirp_tuning_word_coeff),
  .chirp_count_max_in (chirp_count_max)
);

// Accepts commands to start and stop Radar pulse and requests samples
// from waveform in BRAM
waveform_dds waveform_dds_inst(
    .axi_tclk(clk),
    .axi_tresetn(!rst),
    .wf_read_ready(wf_read_ready),

    .chirp_ready (wfrm_ready),
    .chirp_done (wfrm_done),
    .chirp_active (wfrm_active),
    .chirp_init  (wfrm_init),
    .chirp_enable  (wfrm_enable),

    .dds_source_select(dds_source_select),

    .wfrm_axis_tdata(wfout_axis_tdata),
    .wfrm_axis_tvalid(wfout_axis_tvalid),
    .wfrm_axis_tlast(wfout_axis_tlast),
    .wfrm_axis_tready(wfout_axis_tready),

    .wfrm_data_valid(wfrm_data_valid),
    .wfrm_data_i(wfrm_data_i),
    .wfrm_data_q(wfrm_data_q)
);

// accepts waveform sample data from ethernet as input and outputs
// formatted stream of waveform samples

waveform_formatter waveform_formatter_inst (
    .axi_tclk(clk),
    .axi_tresetn(!rst),
    .wf_write_ready(wf_write_ready),
    .init_wf_write(init_wf_write),
    .waveform_parameters(waveform_parameters),
    .wfrm_axis_tdata(wr_axis_tdata),
    .wfrm_axis_tvalid(wr_axis_tvalid),
    .wfrm_axis_tlast(wr_axis_tlast),
    .wfrm_axis_tkeep(wr_axis_tkeep),
    .wfrm_axis_tdest(wr_axis_tdest),
    .wfrm_axis_tid(wr_axis_tid),
    .wfrm_axis_tuser(wr_axis_tuser),
    .wfrm_axis_tready(wr_axis_tready),

    .tdata(wfin_axis_tdata),
    .tvalid(wfin_axis_tvalid),
    .tlast(wfin_axis_tlast),
    .tkeep(wfin_axis_tkeep),
    .tdest(wfin_axis_tdest),
    .tid(wfin_axis_tid),
    .tuser(wfin_axis_tuser),
    .tready(wfin_axis_tready)
);

// wrapper for waveform bram -- contains logic for alternating R/W tasks

waveform_stream #(
   .WRITE_BEFORE_READ(1'b1)
) waveform_stream_inst(
    .clk_in1(clk),
    .aresetn(!rst),
    .waveform_parameters(waveform_parameters),
    .init_wf_write (init_wf_write),
    .wf_write_ready (wf_write_ready),
    .wf_read_ready (wf_read_ready),
    .wfout_size (wfout_size),
    // data to waveform bram
    .wfin_axis_tdata (wfin_axis_tdata),
    .wfin_axis_tvalid(wfin_axis_tvalid),
    .wfin_axis_tlast(wfin_axis_tlast),
    .wfin_axis_tkeep(wfin_axis_tkeep),
    .wfin_axis_tready(wfin_axis_tready),

    // data from waveform bram
    .wfout_axis_tdata(wfout_axis_tdata),
    .wfout_axis_tvalid(wfout_axis_tvalid),
    .wfout_axis_tlast(wfout_axis_tlast),
    .wfout_axis_tkeep(wfout_axis_tkeep),
    .wfout_axis_tready(wfout_axis_tready)
);

assign wfrm_init = (dds_source_select & awg_init);
assign dds_init = (!dds_source_select & awg_init);
assign wfrm_enable = (dds_source_select & awg_enable);
assign dds_enable = (!dds_source_select & awg_enable);

assign awg_done = ((dds_source_select & wfrm_done)|(!dds_source_select & dds_done));
assign awg_active = ((dds_source_select & wfrm_active)|(!dds_source_select & dds_active));
assign awg_ready =  ((dds_source_select & wfrm_ready)|(!dds_source_select & dds_ready));

assign dds_source_select = (&dds_source_ctrl);

assign awg_out_i = dds_source_select ? wfrm_data_i : chirp_data_i;
assign awg_out_q = dds_source_select ? wfrm_data_q : chirp_data_q;
assign awg_data_valid = dds_source_select ? wfrm_data_valid : chirp_data_valid;

assign awg_data_len = dds_source_select ? wfout_size : chirp_count_max;

assign dds_source_ctrl = dds_source_ctrl_r;

  always @(posedge clk) begin
     if (!chirp_enable)
         dds_source_ctrl_r <= chirp_control_word[9:8];
  end

endmodule
