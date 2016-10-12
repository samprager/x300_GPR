`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 04:32:51 PM
// Design Name:
// Module Name: waveform_format_sim_tb
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


module waveform_format_sim_tb;

localparam FMC_TCLK_PERIOD          = 4069;         // 245.76 MHz
localparam RESET_PERIOD = 16276; //in pSec
reg fmc_tresetn_i;
reg fmc_tclk_i;
reg fmc_tclk_fast_i;
wire                   fmc_tclk;
wire                fmc_tclk_fast;
wire                   fmc_tresetn;

wire [127:0] waveform_parameters;
wire init_wf_write;
wire wf_write_ready;
wire wf_read_ready;

// data from ADC Data fifo
wire       [31:0]                    wfin_axis_tdata;
wire                                 wfin_axis_tvalid;
wire                                 wfin_axis_tlast;
wire       [3:0]                    wfin_axis_tkeep;
wire                                wfin_axis_tready;

wire       [31:0]                    wsin_axis_tdata;
wire                                 wsin_axis_tvalid;
wire                                 wsin_axis_tlast;
wire       [3:0]                    wsin_axis_tkeep;
wire                                wsin_axis_tready;

// data from ADC Data fifo
wire       [31:0]                    wfout_axis_tdata;
wire                                 wfout_axis_tvalid;
wire                                 wfout_axis_tlast;
wire       [3:0]                     wfout_axis_tkeep;
wire                                wfout_axis_tready;

wire                  wfrm_data_valid;
wire [15:0]           wfrm_data_i;
wire [15:0]           wfrm_data_q;


reg       [31:0]                    wfin_axis_tdata_reg;
reg                                 wfin_axis_tvalid_reg;
reg                                 wfin_axis_tlast_reg;
reg       [3:0]                    wfin_axis_tkeep_reg;
reg                                wfout_axis_tready_reg = 0;

reg [7:0]               counter = 'b0;
reg                     wf_written = 0;

reg [31:0] wfrm_ind = 'b0;
reg [31:0] wfrm_len = 'd1004;
reg [31:0] wfrm_id = 'b0;
reg [31:0] wfrm_placeholder= 'b0;
reg [31:0] wfrm_cmd = 32'h57574441;

reg [1:0] wfrm_counter;

reg [10:0] chirp_count;

reg chirp_init;
wire chirp_active;
wire chirp_done;
wire chirp_ready;
reg dds_source_select;

initial
begin
      fmc_tclk_i = 1'b0;
      fmc_tclk_fast_i = 1'b1;
end

initial begin
  fmc_tresetn_i = 1'b0;
  #RESET_PERIOD
    fmc_tresetn_i = 1'b1;
 end

always
  begin
      fmc_tclk_i = #(FMC_TCLK_PERIOD/2.0) ~fmc_tclk_i;
end

always
  begin
      fmc_tclk_fast_i = #(FMC_TCLK_PERIOD/4.0) ~fmc_tclk_fast_i;
end

assign fmc_tresetn = fmc_tresetn_i;
assign fmc_tclk = fmc_tclk_i;
assign fmc_tclk_fast = fmc_tclk_fast_i;

initial begin
      repeat(4096)@(posedge fmc_tclk_i); // wait for reset
      $finish;
end

always @(posedge fmc_tclk) begin
    if (!fmc_tresetn) begin
        wfin_axis_tdata_reg <= 'b0;
        wfin_axis_tvalid_reg <= 0;
        wfin_axis_tlast_reg <= 0;
        wfin_axis_tkeep_reg <= 'b0;
        wfout_axis_tready_reg <= 0;
        counter <= 0;

        wfrm_counter <= 0;

        dds_source_select <= 0;
        chirp_init <= 0;
    end
    else begin

        wfout_axis_tready_reg <= 1'b1;
        wfin_axis_tvalid_reg <= 1'b1;
        wfin_axis_tkeep_reg <= 4'hf;

        dds_source_select <= 1;
        if (counter == 0 & wfrm_counter == 2'b10)
            chirp_init <= 1;
        else
          chirp_init <= 0;


        if (&counter) begin
           wfin_axis_tlast_reg <= 1'b1;
           wfrm_counter <= wfrm_counter+1'b1;
           if(&wfrm_counter) begin
             wfrm_ind <= 'b0;
             wfrm_id <= wfrm_id + 1'b1;
           end else
             wfrm_ind <= wfrm_ind + 1'b1;
        end else if (wfin_axis_tready) begin
            wfin_axis_tlast_reg <= 1'b0;
        end

        if (counter == 0) begin
          wfin_axis_tdata_reg <= wfrm_cmd;
          counter <= counter + 1'b1;
        end
        else if  (wfin_axis_tvalid_reg & wfin_axis_tready) begin
          counter <= counter + 1'b1;
          if (counter == 1)
             wfin_axis_tdata_reg <=wfrm_id;
          else if (counter == 2)
             wfin_axis_tdata_reg <=wfrm_ind;
          else if (counter == 3)
             wfin_axis_tdata_reg <=wfrm_len;
          else if (counter == 4)
             wfin_axis_tdata_reg <=wfrm_placeholder;
          else
           wfin_axis_tdata_reg <= counter;
        end
    end
end

waveform_formatter u_waveform_formatter (
    .axi_tclk(fmc_tclk),
    .axi_tresetn(fmc_tresetn),
    .wf_write_ready(wf_write_ready),
    .init_wf_write(init_wf_write),
    .waveform_parameters(waveform_parameters),
    .wfrm_axis_tdata(wfin_axis_tdata),
    .wfrm_axis_tvalid(wfin_axis_tvalid),
    .wfrm_axis_tlast(wfin_axis_tlast),
    .wfrm_axis_tkeep(wfin_axis_tkeep),
    .wfrm_axis_tdest('b0),
    .wfrm_axis_tid('b0),
    .wfrm_axis_tuser('b0),
    .wfrm_axis_tready(wfin_axis_tready),

    .tdata(wsin_axis_tdata),
    .tvalid(wsin_axis_tvalid),
    .tlast(wsin_axis_tlast),
    .tkeep(wsin_axis_tkeep),
    .tdest(),
    .tid(),
    .tuser(),
    .tready(wsin_axis_tready)
);

waveform_stream #(
   .WRITE_BEFORE_READ(1'b1)
) u_waveform_stream(
    .clk_in1(fmc_tclk),
    .aresetn(fmc_tresetn),
    .waveform_parameters(waveform_parameters),
    .init_wf_write (init_wf_write),
    .wf_write_ready (wf_write_ready),
    .wf_read_ready (wf_read_ready),
    // data from ADC Data fifo
    .wfin_axis_tdata (wsin_axis_tdata),
    .wfin_axis_tvalid(wsin_axis_tvalid),
    .wfin_axis_tlast(wsin_axis_tlast),
    .wfin_axis_tkeep(wsin_axis_tkeep),
    .wfin_axis_tready(wsin_axis_tready),

    // data from ADC Data fifo
    .wfout_axis_tdata(wfout_axis_tdata),
    .wfout_axis_tvalid(wfout_axis_tvalid),
    .wfout_axis_tlast(wfout_axis_tlast),
    .wfout_axis_tkeep(wfout_axis_tkeep),
    .wfout_axis_tready(wfout_axis_tready)
);

waveform_dds u_waveform_dds(
    .axi_tclk(fmc_tclk),
    .axi_tresetn(fmc_tresetn),
    .wf_read_ready(wf_read_ready),
    
    .chirp_ready (chirp_ready),
    .chirp_done (chirp_done),
    .chirp_active (chirp_active),
    .chirp_init  (chirp_init),
    .chirp_enable  (1'b1),
    
    .dds_source_select(dds_source_select),

    .wfrm_axis_tdata(wfout_axis_tdata),
    .wfrm_axis_tvalid(wfout_axis_tvalid),
    .wfrm_axis_tlast(wfout_axis_tlast),
    .wfrm_axis_tready(wfout_axis_tready),

    .wfrm_data_valid(wfrm_data_valid),
    .wfrm_data_i(wfrm_data_i),
    .wfrm_data_q(wfrm_data_q)
);

assign wfin_axis_tdata = wfin_axis_tdata_reg;
assign wfin_axis_tvalid = wfin_axis_tvalid_reg;
assign wfin_axis_tlast = wfin_axis_tlast_reg;
assign wfin_axis_tkeep = wfin_axis_tkeep_reg;


endmodule
