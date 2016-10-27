//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 10/18/2016 02:25:19 PM
// Design Name:
// Module Name: axi_delay_fifo
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
// Converts AXI-Stream sample data to a strobed data interface for the radio frontend
// Outputs an error packet if an underrun or late timed command occurs.

module axi_delay_fifo #(
  parameter DELAY = 4,   // What to do when errors occur -- wait for next packet or next burst
  parameter WIDTH = 32
)(
 input clk, input reset, input clear,
 input [WIDTH-1:0] i_tdata,
 input i_tvalid,
 output i_tready,
 output [WIDTH-1:0] o_tdata,
 output o_tvalid,
 input o_tready);


wire [WIDTH-1:0] i_tdata_d [0:DELAY];
wire [DELAY:0] i_tvalid_d;
wire [DELAY:0] i_tready_d;


genvar i;
generate
for (i=1;i<=DELAY;i=i+1) begin : loop
axi_fifo_flop2 #(.WIDTH(WIDTH))
axi_fifo_flop2 (
  .clk(clk), .reset(reset), .clear(clear),
  .i_tdata(i_tdata_d[i-1]), .i_tvalid(i_tvalid_d[i-1]), .i_tready(i_tready_d[i-1]),
  .o_tdata(i_tdata_d[i]), .o_tvalid(i_tvalid_d[i]), .o_tready(i_tready_d[i]),
  .space(), .occupied());
end
endgenerate
assign i_tdata_d[0] = i_tdata;
assign i_tvalid_d[0] = i_tvalid;
assign i_tready = i_tready_d[0];

assign i_tready_d[DELAY] = o_tready;
assign o_tdata = i_tdata_d[DELAY];
assign o_tvalid = i_tvalid_d[DELAY];

endmodule // axi_delay_fifo
