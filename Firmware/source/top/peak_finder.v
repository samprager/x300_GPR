`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Samuel Prager
//
// Create Date: 07/23/2016 03:43:49 AM
// Design Name:
// Module Name: peak_finder
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


module peak_finder #(
    parameter DATA_LEN = 64,
    parameter FCLOCK = 245.76,
    parameter FFT_LEN = 8192,
    parameter CHIRP_BW = 61,     // Mhz
    parameter INIT_THRESHOLD = 64'h0000ffffffffffff,
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
    input [DATA_LEN-1:0] threshold,
    output [INDEX_LEN-1:0] peak_index,
    output [DATA_LEN-1:0] peak_tdata,
    output peak_tvalid,
    output peak_tlast,
    output [TUSER_LEN-1:0] peak_tuser,
    output [INDEX_LEN-1:0] num_peaks
    );

    reg [DATA_LEN-1:0] tdata_left;
    reg [DATA_LEN-1:0] tdata_mid;
    reg [INDEX_LEN-1:0]  index_mid;
    reg [TUSER_LEN-1:0] tuser_mid;
    reg [DATA_LEN-1:0] peak_tdata_r;
    reg                peak_tvalid_r;
    reg [DATA_LEN-1:0]  min_threshold;
    reg [INDEX_LEN-1:0] peak_index_r;
    reg tlast_mid;
    reg tvalid_mid;
    reg peak_tlast_r;
    reg [TUSER_LEN-1:0] peak_tuser_r;
    reg [INDEX_LEN-1:0] num_peaks_r;
    reg [DATA_LEN-1:0] peak_tdata_max;
    reg [INDEX_LEN-1:0] peak_index_max;


always @(posedge clk) begin
if (tvalid) begin
  tdata_mid<=tdata;
  tdata_left<=tdata_mid;
  index_mid <= index;
  tuser_mid <= tuser;
  peak_tuser_r <= tuser_mid;
  end
end

always @(posedge clk) begin
  tvalid_mid <= tvalid;
end

always @(posedge clk) begin
if (tlast & tvalid)
  tlast_mid <= 1'b1;
else
  tlast_mid <= 1'b0;
end

always @(posedge clk) begin
if(!aresetn)
  min_threshold <=INIT_THRESHOLD;
//else if(tvalid & !(|index))
//  min_threshold <= threshold;
else if(tvalid)
    min_threshold <= threshold;
end


always @(posedge clk) begin
if(!aresetn) begin
    peak_tdata_r <= 'b0;
    peak_tvalid_r <= 1'b0;
    peak_index_r <= 'b0;
    num_peaks_r <= 'b0;
    peak_tlast_r <= 1'b0;
end else if(tvalid & !(|index)) begin
  peak_tdata_r <= 'b0;
  peak_tvalid_r <= 1'b0;
  peak_index_r <= 'b0;
  num_peaks_r <= 'b0;
  peak_tlast_r <= 'b0;
end else if (tlast_mid & tvalid_mid) begin
  peak_tvalid_r <= 1'b1;
  peak_tdata_r <= peak_tdata_max;
  peak_index_r <= peak_index_max;
  num_peaks_r <= num_peaks_r;
  peak_tlast_r <= 1'b1;
end else if(tvalid & (tdata_mid >= tdata_left)&(tdata_mid >= tdata)&(tdata_mid> min_threshold)) begin
  peak_tdata_r <= tdata_mid;
  peak_tvalid_r <= 1'b1;
  peak_index_r <= index_mid;
  num_peaks_r <= num_peaks_r + 1'b1;
  peak_tlast_r <= 1'b0;
end else begin
  peak_tvalid_r <= 1'b0;
  peak_tlast_r <= 1'b0;
//  peak_tdata_r <= 'b0;
//  peak_index_r <= 'b0;
  peak_tdata_r <= peak_tdata_r;
  peak_index_r <= peak_index_r;
  num_peaks_r <= num_peaks_r;
end
end

always @(posedge clk) begin
if(!aresetn) begin
  peak_tdata_max <= 'b0;
  peak_index_max <= 'b0;
end else if (tlast_mid & tvalid_mid) begin
  peak_tdata_max <= 'b0;
  peak_index_max <= 'b0;
end else if (tvalid_mid & (tdata_mid > peak_tdata_max)) begin
  peak_tdata_max <= tdata_mid;
  peak_index_max <= index_mid;
end else begin
  peak_tdata_max <= peak_tdata_max;
  peak_index_max <= peak_index_max;
end
end


assign peak_tdata = peak_tdata_r;
assign peak_tvalid = peak_tvalid_r;
assign peak_tlast = peak_tlast_r;
assign peak_index = peak_index_r;
assign num_peaks = num_peaks_r;
assign peak_tuser = peak_tuser_r;


endmodule
