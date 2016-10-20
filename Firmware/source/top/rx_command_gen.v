`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 06/8/2016 02:25:19 PM
// Design Name:
// Module Name: rx_command_gen
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
module rx_command_gen (
      input clk,
      input reset,

      output [31:0] command_i,
      output [63:0] time_i,
      output store_command,

      input [31:0] awg_data_len,
      input [31:0] num_adc_samples,
      input [63:0] vita_time,

      input awg_init,
      input adc_run,
      input adc_enable          // high while adc samples saved

    );

    wire [31:0] numlines;

    wire send_imm = 1'b1;
    wire chain = 1'b0;
    wire reload = 1'b0;
    wire stop = 1'b0;

    reg run_wait;

    reg [31:0] command_i_r;
    reg [63:0] time_i_r;
    reg store_command_r;

    assign numlines = awg_data_len + num_adc_samples;

    always @(posedge clk) begin
        if(reset) begin
           store_command_r <= 1'b0;
           command_i_r <= 'b0;
           time_i_r <= 'b0;
        end else if(run_wait & adc_run) begin
           command_i_r <= {send_imm,chain,reload,stop,numlines[27:0]};
           time_i_r <= vita_time;
           store_command_r <= 1'b1;
        end else begin
           store_command_r <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(reset) begin
           run_wait <= 1'b0;
        end else if(awg_init) begin
           run_wait <= 1'b1;
        end else if (adc_run) begin
           run_wait <= 1'b0;
        end
    end

    assign command_i = command_i_r;
    assign time_i = time_i_r;
    assign store_command = store_command_r;

endmodule
