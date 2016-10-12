`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Samuel Prager
//
// Create Date: 07/23/2016 03:43:49 AM
// Design Name:
// Module Name: freq_domain_lpf
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


module freq_domain_lpf #(
    parameter DATA_LEN = 64,
    parameter FCLOCK = 245.76,
    parameter FFT_LEN = 8192,
    parameter CHIRP_BW = 61,     // Mhz
    parameter TUSER_LEN = 32,
    parameter INDEX_LEN = 32
    )(
    input clk,
    input aresetn,
    input [DATA_LEN-1:0] tdata,
    input tvalid,
    input tlast,
    input [TUSER_LEN-1:0] tuser,
    input [INDEX_LEN-1:0] index,
    input [INDEX_LEN-1:0] cutoff,
    output [DATA_LEN-1:0] lpf_tdata,
    output lpf_tvalid,
    output lpf_tlast,
    output [TUSER_LEN-1:0] lpf_tuser,
    output [INDEX_LEN-1:0] lpf_index
    );

    localparam INIT_CUTOFF = FFT_LEN/2;

    reg [INDEX_LEN-1:0]  cutoff_index;


always @(posedge clk) begin
if(!aresetn)
  cutoff_index <= INIT_CUTOFF;
else if (tvalid & !(|index))
  cutoff_index <= cutoff;
end

assign lpf_tdata = (index <= cutoff_index)? tdata : 'b0;
assign lpf_tvalid = tvalid;
assign lpf_tlast = tlast;
//assign lpf_tvalid = (index <= cutoff_index)? tvalid : 1'b0;
//assign lpf_tlast = (tvalid&(((index<cutoff_index)&tlast)|((index==cutoff_index))))? 1'b1 : 1'b0;
assign lpf_tuser = tuser;
assign lpf_index = index;

endmodule
