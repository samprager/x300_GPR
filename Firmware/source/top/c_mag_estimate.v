`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Samuel Prager
// 
// Create Date: 07/23/2016 03:43:49 AM
// Design Name: 
// Module Name: c_mag_estimate
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


module c_mag_estimate #(
    parameter DATA_LEN = 32,
    parameter ALPHA = 0.9,
    parameter BETA = 0.4
    )(
    input clk,
    input [DATA_LEN-1:0] dataI,
    input [DATA_LEN-1:0] dataQ,
    output[DATA_LEN-1:0] dataMag
    );
    
    reg [DATA_LEN-1:0] dataMag_r;
    reg [DATA_LEN-1:0] dataI_abs;
    reg [DATA_LEN-1:0] dataQ_abs;
//    wire [DATA_LEN-1:0] dataI_abs;
//    wire [DATA_LEN-1:0] dataQ_abs;
    
    always @(posedge clk) begin
        if (!dataI[DATA_LEN-1])
            dataI_abs <= dataI;
        else
            dataI_abs <= -dataI;
    end  
    always @(posedge clk) begin
        if (!dataQ[DATA_LEN-1])
            dataQ_abs <= dataQ;
        else
            dataQ_abs <= -dataQ;
    end
    
    always @(posedge clk) begin
        if (dataI_abs >= dataQ_abs)
            dataMag_r <= dataI_abs + {0,dataQ_abs[DATA_LEN-2:0]};
        else
            dataMag_r <= dataQ_abs + {0,dataI_abs[DATA_LEN-2:0]};
    end
    assign dataMag = dataMag_r;
//    assign dataI_abs = (dataI >= 0) ? dataI : -dataI;
//    assign dataQ_abs = (dataQ >= 0) ? dataQ : -dataQ;
//    assign dataMag = (dataI_abs >= dataQ_abs) ? dataI_abs + {0,dataQ_abs[DATA_LEN-2:0]} : dataQ_abs + {0,dataI_abs[DATA_LEN-2:0]};
                
    

endmodule
