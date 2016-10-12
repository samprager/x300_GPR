`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2016 04:32:51 PM
// Design Name: 
// Module Name: datamover_bram_sim_tb
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


module datamover_bram_sim_tb;

localparam FMC_TCLK_PERIOD          = 4069;         // 245.76 MHz
localparam RESET_PERIOD = 16276; //in pSec 
reg fmc_tresetn_i;
reg fmc_tclk_i;   
wire                   fmc_tclk;
wire                   fmc_tresetn;
        
initial
begin
      fmc_tclk_i = 1'b0;
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

assign fmc_tresetn = fmc_tresetn_i;
assign fmc_tclk = fmc_tclk_i;

 initial begin
      repeat(4096)@(posedge fmc_tclk_i); // wait for reset
      $finish;
end
    
datamover_bram_top u_datamover_bram_top(
    .clk_in1(fmc_tclk),
    .aresetn(fmc_tresetn)
);

   
endmodule
