`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Samuel Prager
//
// Create Date: 07/23/2016 03:43:49 AM
// Design Name:
// Module Name: sq_mag_estimate
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


module sq_mag_estimate #(
    parameter DATA_LEN = 32,
    parameter DIV_OR_OVERFLOW = 0,      // (1): Divide output by 2, (0): use overflow bit
    parameter REGISTER_OUTPUT = 1,
    parameter MULT_LATENCY = 6,
    parameter TUSER_LEN = 32,
    parameter INDEX_LEN = 32
    )(
    input clk,
    input [DATA_LEN-1:0] dataI,
    input dataI_tvalid,
    input dataI_tlast,
    input [DATA_LEN-1:0] dataQ,
    input dataQ_tvalid,
    input dataQ_tlast,
    input [TUSER_LEN-1:0] data_tuser,
    input [INDEX_LEN-1:0] data_index,
    output[2*DATA_LEN-1:0] dataMagSq,
    output dataMag_tvalid,
    output dataMag_tlast,
    output [TUSER_LEN-1:0] dataMag_tuser,
    output [INDEX_LEN-1:0] dataMag_index,
    output overflow
    );

    reg [2*DATA_LEN:0] dataMagSq_r;
    wire [2*DATA_LEN:0] dataMagSq_ext;
    wire [2*DATA_LEN-1:0] dataI_sq;
    wire [2*DATA_LEN-1:0] dataQ_sq;
    reg[MULT_LATENCY+REGISTER_OUTPUT-1:0] i_tvalid_shift;
    reg [MULT_LATENCY+REGISTER_OUTPUT-1:0] i_tlast_shift;
    reg[MULT_LATENCY+REGISTER_OUTPUT-1:0] q_tvalid_shift;
    reg [MULT_LATENCY+REGISTER_OUTPUT-1:0] q_tlast_shift;
    reg [TUSER_LEN-1:0] tuser_shift [MULT_LATENCY+REGISTER_OUTPUT-1:0];
    reg [INDEX_LEN-1:0] index_shift [MULT_LATENCY+REGISTER_OUTPUT-1:0];

    integer i;

  mult_gen_32b sq_i (
    .CLK(clk),  // input wire CLK
    .A(dataI),      // input wire [31 : 0] A
    .B(dataI),      // input wire [31 : 0] B
    .P(dataI_sq)      // output wire [63 : 0] P
  );
  mult_gen_32b sq_q (
    .CLK(clk),  // input wire CLK
    .A(dataQ),      // input wire [31 : 0] A
    .B(dataQ),      // input wire [31 : 0] B
    .P(dataQ_sq)      // output wire [63 : 0] P
  );

  always @(posedge clk) begin
    i_tvalid_shift[0] <= dataI_tvalid;
    i_tlast_shift[0] <= dataI_tlast;
    q_tvalid_shift[0] <= dataQ_tvalid;
    q_tlast_shift[0] <= dataQ_tlast;
    tuser_shift[0] <= data_tuser;
    index_shift[0] <= data_index;
    for(i=1;i<MULT_LATENCY+REGISTER_OUTPUT;i=i+1) begin
      i_tvalid_shift[i] <= i_tvalid_shift[i-1];
      i_tlast_shift[i] <= i_tlast_shift[i-1];
      q_tvalid_shift[i] <= q_tvalid_shift[i-1];
      q_tlast_shift[i] <= q_tlast_shift[i-1];
      tuser_shift[i] <= tuser_shift[i-1];
      index_shift[i] <= index_shift[i-1];
    end
  end

  assign dataMag_tvalid = i_tvalid_shift[MULT_LATENCY+REGISTER_OUTPUT-1] & q_tvalid_shift[MULT_LATENCY+REGISTER_OUTPUT-1];
  assign dataMag_tlast = i_tlast_shift[MULT_LATENCY+REGISTER_OUTPUT-1] & q_tlast_shift[MULT_LATENCY+REGISTER_OUTPUT-1];
  assign dataMag_tuser = tuser_shift[MULT_LATENCY+REGISTER_OUTPUT-1];
  assign dataMag_index = index_shift[MULT_LATENCY+REGISTER_OUTPUT-1];

generate if(REGISTER_OUTPUT == 1) begin
  always @(posedge clk) begin
      dataMagSq_r <= dataI_sq + dataQ_sq;
  end
  assign dataMagSq_ext = dataMagSq_r;
end
else begin
  assign dataMagSq_ext = dataI_sq + dataQ_sq;
end
endgenerate

assign dataMagSq = (DIV_OR_OVERFLOW == 1) ? dataMagSq_ext[2*DATA_LEN:1] : dataMagSq_ext[2*DATA_LEN-1:0];
assign overflow = dataMagSq_ext[2*DATA_LEN];


endmodule
