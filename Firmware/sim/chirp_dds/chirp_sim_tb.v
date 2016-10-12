`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/14/2016 04:32:51 PM
// Design Name:
// Module Name: chirp_sim_tb
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


module chirp_sim_tb;

localparam FMC_TCLK_PERIOD          = 4069;         // 245.76 MHz
localparam RESET_PERIOD = 16276; //in pSec
reg fmc_tresetn_i;
reg fmc_tclk_i;
reg fmc_tclk_fast_i;
wire                   fmc_tclk;
wire                fmc_tclk_fast;
wire                   fmc_tresetn;

wire [127:0] chirp_parameters;

reg [31:0] ch_freq_offset = 32'd768; //32'h0600;
reg [31:0] ch_tuning_coef = 32'b1;
reg [31:0] ch_counter_max = 'b1;//32'd1023; //32'h00000fff;
reg [31:0] ch_ctrl_word = 32'b0;


reg      [127:0]                    chirp_parameters_reg = 'b0;


wire [15:0] dds_out_i;
wire [15:0] dds_out_q;
wire chirp_ready;
wire chirp_done;
wire chirp_active;
wire chirp_init;
reg chirp_init_reg;

reg [10:0] chirp_count;

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
      repeat(8192)@(posedge fmc_tclk_i); // wait for reset
      $finish;
end

always @(posedge fmc_tclk) begin
    if (!fmc_tresetn) begin
        chirp_count <= 0;
        chirp_init_reg <= 0;
    end
    else begin
        chirp_count <= chirp_count + 1'b1;
        if (chirp_count == 0)
            chirp_init_reg <= 1'b1;
        else
            chirp_init_reg <= 1'b0;
    end
end


CHIRP_DDS u_chirp_dds(
    .CLOCK(fmc_tclk),
    .RESET(!fmc_tresetn),
    .IF_OUT_I(dds_out_i),
    .IF_OUT_Q(dds_out_q),
    .IF_OUT_VALID(),

    .chirp_ready (chirp_ready),
    .chirp_done  (chirp_done),
    .chirp_active (chirp_active),
    .chirp_init  (chirp_init),
    .chirp_enable (1'b1),

    .freq_offset_in          (ch_freq_offset),
    .tuning_word_coeff_in    (ch_tuning_coef),
    .chirp_count_max_in            (ch_counter_max)

);
assign chirp_init=chirp_init_reg;
assign chirp_parameters = chirp_parameters_reg;

endmodule
