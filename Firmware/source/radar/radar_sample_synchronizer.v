//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 10/14/2016 04:32:51 PM
// Design Name:
// Module Name: radar_sample_synchronizer
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

module radar_sample_synchronizer #
  (
     parameter ADC_AXI_DATA_WIDTH = 64,
     parameter ADC_AXI_TID_WIDTH = 1,
     parameter ADC_AXI_TDEST_WIDTH = 1,
     parameter ADC_AXI_TUSER_WIDTH = 1,
     parameter ADC_AXI_STREAM_ID = 1'b0,
     parameter ADC_AXI_STREAM_DEST = 1'b0,

     parameter SIMULATION = 0,
     parameter ALIGN = 1
   )
  (

   input    clk, // AXI input clock
   input    reset, // Active low AXI reset signal

   // --ADC Data Out Signals
  output [63:0] iq_tdata,
  output iq_tvalid,
  output iq_tlast,
  input iq_tready,
  output iq_first,
  output [63:0] iq_tuser,

  input [31:0] adc_data_iq,
  input [31:0] dac_data_iq,
  input adc_data_valid,
  input run_rx,
  input run_tx,


  output [ADC_AXI_DATA_WIDTH-1:0]     axis_adc_tdata,
  output axis_adc_tvalid,
  output axis_adc_tlast,
  output [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tkeep,
  output [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tstrb,
  output [ADC_AXI_TID_WIDTH-1:0] axis_adc_tid,
  output [ADC_AXI_TDEST_WIDTH-1:0] axis_adc_tdest,
  output [ADC_AXI_TUSER_WIDTH-1:0] axis_adc_tuser,
  input axis_adc_tready,

  input [31:0] awg_control_word,
  input adc_last
   );

  function integer clogb2 (input integer size);
      begin
        if (size == 1) begin
            clogb2 = 0;
        end else begin
        size = size - 1;
        for (clogb2=1; size>1; clogb2=clogb2+1)
          size = size >> 1;
      end
      end
  endfunction // clogb2
  parameter ALIGN_SIZE = clogb2(ALIGN);


  localparam     DATA_FIRST_COMMAND = 32'h46525354;     //Ascii FRST
  localparam     DATA_LAST_COMMAND = 32'h4c415354;     //Ascii LAST

  wire [31:0] adc_counter;
  wire [1:0] dds_route_ctrl_u;
  wire [1:0] dds_route_ctrl_l;
  wire [1:0] dds_source_ctrl;
  wire dds_source_select;

  reg [1:0] dds_route_ctrl_u_r;
  reg [1:0] dds_route_ctrl_l_r;
  reg [1:0] dds_source_ctrl_r;

  wire [63:0] adc_fifo_wr_tdata;
  wire       adc_fifo_wr_tvalid;
  wire       adc_fifo_wr_tlast;

  reg adc_last_hold;



     wire [12:0]              adc_fifo_wr_tdata_count;
     wire [9:0]               adc_fifo_rd_data_count;
     wire                       adc_fifo_wr_ack;
     wire                       adc_fifo_valid;
     wire                       adc_fifo_almost_full;
     wire                       adc_fifo_almost_empty;
     wire                      adc_fifo_wr_en;
     wire                      adc_fifo_rd_en;
     wire [ADC_AXI_DATA_WIDTH-1:0]  adc_fifo_data_out;
     wire [ADC_AXI_DATA_WIDTH-1:0]  adc_fifo_data_out_reversed;
     wire                     adc_fifo_full;
     wire                     adc_fifo_empty;

     reg [31:0] glbl_counter_reg;

     reg [15:0] data_alignment_counter;
     reg [15:0] data_word_counter;

     wire align_data;

     reg [31:0] adc_counter_reg;
     wire [31:0] glbl_counter;
     wire [31:0] data_command_word;

     wire [31:0] data_out_upper;
     wire [31:0] data_out_lower;

     reg [31:0] adc_data_iq_r;
     reg [31:0] dac_data_iq_r;
     reg run_rx_r;
     reg run_tx_r;
     reg adc_last_r;



assign dds_source_select = (&dds_source_ctrl);

assign data_out_lower  = (dds_route_ctrl_l == 2'b00) ? adc_data_iq_r : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b01) ? dac_data_iq_r : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b10) ? adc_counter : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b11) ? glbl_counter : 32'bz;

assign data_out_upper  = (dds_route_ctrl_u == 2'b00) ? adc_data_iq_r : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b01) ? dac_data_iq_r : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b10) ? adc_counter : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b11) ? glbl_counter : 32'bz;

assign dds_route_ctrl_l = dds_route_ctrl_l_r;
assign dds_route_ctrl_u = dds_route_ctrl_u_r;
assign dds_source_ctrl = dds_source_ctrl_r;


  always @(posedge clk) begin
     dds_route_ctrl_l_r <= awg_control_word[1:0];
     dds_route_ctrl_u_r <= awg_control_word[5:4];
  end

  always @(posedge clk) begin
         dds_source_ctrl_r <= awg_control_word[9:8];
  end

  always @(posedge clk) begin
    if (reset)
      data_word_counter <= 'b0;
   else if (iq_first)
      data_word_counter <= 'b0;
    else if(run_rx_r & adc_data_valid)
      data_word_counter <= data_word_counter + 1'b1;
  end

generate
if (ALIGN_SIZE>0) begin
   always @(posedge clk) begin
      if (reset)
        data_alignment_counter <= 'b0;
      else if(adc_last) begin
         data_alignment_counter[ALIGN_SIZE-1:0] <= (data_word_counter+1'b1)^(ALIGN-1);
         data_alignment_counter[15:ALIGN_SIZE] <= 'b0;
      end else if(|data_alignment_counter)
        data_alignment_counter <= data_alignment_counter - 1'b1;
    end
end else begin
    always @(posedge clk) begin
        data_alignment_counter <= 'b0;
    end
end
endgenerate

assign align_data = |data_alignment_counter;


 always @(posedge clk) begin
 if (reset)
    adc_last_hold <= 0;
    else if(adc_last)
    adc_last_hold <= 1'b1;
    else if (~align_data)
    adc_last_hold <= 0;
 end

  always @(posedge clk) begin
  if (reset) begin
    run_tx_r <= 1'b0;
    run_rx_r <= 1'b0;
    adc_last_r <= 1'b0;
    dac_data_iq_r <= 'b0;
    adc_data_iq_r <= 'b0;
  end else begin
    run_tx_r <= run_tx;
    run_rx_r <= run_rx;
    adc_last_r <= adc_last;
    dac_data_iq_r <= dac_data_iq;
    adc_data_iq_r <= adc_data_iq;
 end
 end




   always @(posedge clk) begin
    if (reset) begin
      adc_counter_reg <= 'b0;
    end
    else begin
      if (adc_fifo_wr_tvalid)
        adc_counter_reg <= adc_counter_reg+1;
    end
   end

   assign adc_counter = adc_counter_reg;

   always @(posedge clk) begin
    if (reset) begin
      glbl_counter_reg <= 'b0;
    end
    else begin
      glbl_counter_reg <= glbl_counter_reg+1;
    end
   end

   assign glbl_counter = glbl_counter_reg;

// asynchoronous fifo for converting 245.76 MHz 32 bit adc samples (16 i, 16 q)
// to rd clk domain 64 bit adc samples (i1 q1 i2 q2)
   fifo_generator_adc u_fifo_generator_adc
   (
   .wr_clk                    (clk),
   .rd_clk                    (clk),
   .wr_data_count             (adc_fifo_wr_tdata_count),
   .rd_data_count             (adc_fifo_rd_data_count),
   .wr_ack                    (adc_fifo_wr_ack),
   .valid                     (adc_fifo_valid),
   .almost_full               (adc_fifo_almost_full),
   .almost_empty              (adc_fifo_almost_empty),
   .rst                       (reset),
   //.wr_en                     (adc_fifo_wr_en),
   .wr_en                     (adc_fifo_wr_tvalid),
   //.rd_en                     (adc_fifo_rd_en),
   .rd_en                     (adc_fifo_rd_en),
   .din                       (adc_fifo_wr_tdata),
   .dout                      (adc_fifo_data_out),
   .full                      (adc_fifo_full),
   .empty                     (adc_fifo_empty)

   );

   genvar i;
   generate
   for (i=0;i<ADC_AXI_DATA_WIDTH;i=i+64) begin
      assign adc_fifo_data_out_reversed[i+63-:64] = adc_fifo_data_out[ADC_AXI_DATA_WIDTH-i-1-:64];
   end
   endgenerate

   adc_data_axis_wrapper #(
     .ADC_AXI_DATA_WIDTH(ADC_AXI_DATA_WIDTH),
     .ADC_AXI_TID_WIDTH(ADC_AXI_TID_WIDTH),
     .ADC_AXI_TDEST_WIDTH(ADC_AXI_TDEST_WIDTH),
     .ADC_AXI_TUSER_WIDTH(ADC_AXI_TUSER_WIDTH),
     .ADC_AXI_STREAM_ID(ADC_AXI_STREAM_ID),
     .ADC_AXI_STREAM_DEST(ADC_AXI_STREAM_DEST)
    )
    adc_data_axis_wrapper_inst (
      .axi_tclk                   (clk),
      .axi_tresetn                (~reset),
//      .adc_data                   (adc_fifo_data_out),
      .adc_data                   (adc_fifo_data_out_reversed),
      .adc_fifo_data_valid        (adc_fifo_valid),
      .adc_fifo_empty             (adc_fifo_empty),
      .adc_fifo_almost_empty      (adc_fifo_almost_empty),
      .adc_fifo_rd_en             (adc_fifo_rd_en),

      .tdata                      (axis_adc_tdata),
      .tvalid                     (axis_adc_tvalid),
      .tlast                      (axis_adc_tlast),
      .tkeep                      (axis_adc_tkeep),
      .tstrb                      (axis_adc_tstrb),
      .tid                        (axis_adc_tid),
      .tdest                      (axis_adc_tdest),
      .tuser                      (axis_adc_tuser),
      .tready                     (axis_adc_tready)
      );

 assign adc_fifo_wr_tdata  =  {data_out_upper,data_out_lower};
 assign adc_fifo_wr_tvalid = (iq_tvalid | adc_last_hold);
 assign adc_fifo_wr_tlast = (adc_last_hold & (~align_data));

assign iq_tdata = {dac_data_iq_r,adc_data_iq_r};
assign iq_tvalid = run_rx_r & adc_data_valid;
assign iq_tlast = adc_last_r;
assign iq_first = (run_rx & ~run_rx_r);
assign iq_tuser = {glbl_counter[31:0],adc_counter};


   endmodule
