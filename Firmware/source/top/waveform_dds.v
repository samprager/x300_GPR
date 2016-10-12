//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 08/14/2016 03:54:31 PM
// Design Name:
// Module Name: waveform_dds
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

`timescale 1 ps/1 ps

module waveform_dds(
   input                   axi_tclk,
   input                   axi_tresetn,

   input                   wf_read_ready,

   output        reg         chirp_ready,
   output        reg         chirp_done,
   output        reg         chirp_active,
   input                  chirp_init,
   input                  chirp_enable,

   input                  dds_source_select,
       // data from ADC Data fifo
    input       [31:0]                    wfrm_axis_tdata,
    input                                 wfrm_axis_tvalid,
    input                                 wfrm_axis_tlast,
    output                                wfrm_axis_tready,

    output                                wfrm_data_valid,
    output      [15:0]                    wfrm_data_i,
    output      [15:0]                    wfrm_data_q
   );



localparam     IDLE        = 3'b000,
               DATA        = 3'b001;

reg      [31:0]            wfrm_data_iq_r = 'b0;
reg                        wfrm_data_valid_r;


reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;
reg         [31:0]         data_count;

//reg                         wfrm_axis_tready_int;
wire                       wfrm_axis_tready_int;
wire                       axi_treset;

assign axi_treset = !axi_tresetn;

// Write interface
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
   wfrm_data_iq_r <= 'b0;
   wfrm_data_valid_r <= 0;
   end
   else if (gen_state == DATA) begin
      if (wfrm_axis_tvalid & wfrm_axis_tready_int) begin
        wfrm_data_iq_r <= wfrm_axis_tdata;
        wfrm_data_valid_r <= 1;
      end else begin
        wfrm_data_iq_r <= wfrm_data_iq_r;
        wfrm_data_valid_r <= 0;
      end
  end
  else begin
    wfrm_data_iq_r <= 'b0;
    wfrm_data_valid_r <= 0;
  end
end

// always @(posedge axi_tclk)
// begin
//    if (axi_treset)
//     wfrm_axis_tready_int <= 0;
//    else if (gen_state == DATA)
//     wfrm_axis_tready_int <= 1;
//    else
//     wfrm_axis_tready_int <= 0;
// end

assign wfrm_axis_tready_int = (gen_state == DATA);

always @(posedge axi_tclk)
begin
   if (axi_treset)
    data_count <= 0;
   else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int)
    data_count <= data_count + 1;
  else if(gen_state == IDLE)
   data_count <= 0;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
    chirp_ready <= 0;
   else if (wf_read_ready)
    chirp_ready <= 1;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
     chirp_done <= 0;
   else if (gen_state == DATA & wfrm_axis_tlast & wfrm_axis_tvalid)
     chirp_done <= 1;
   else
     chirp_done <= 0;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
     chirp_active <= 0;
   else if (gen_state == DATA & wfrm_axis_tvalid)
     chirp_active <= 1;
   else if(gen_state == IDLE)
     chirp_active <= 0;
end

// simple state machine to control the data
// on the transition from IDLE we reset the counters and increment the packet size
always @(gen_state or wf_read_ready or chirp_init or dds_source_select or wfrm_axis_tvalid or wfrm_axis_tlast or wfrm_axis_tready_int)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
//         if (dds_source_select & wf_read_ready & chirp_init)
         if (dds_source_select & chirp_init)
            next_gen_state = DATA;
      end
      DATA : begin
         if (wfrm_axis_tlast & wfrm_axis_tvalid)
            next_gen_state = IDLE;
      end
      default : begin
         next_gen_state = IDLE;
      end
   endcase
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      gen_state <= IDLE;
   end
   else begin
      gen_state <= next_gen_state;
   end
end

assign wfrm_data_valid = wfrm_data_valid_r;
assign wfrm_data_i = wfrm_data_iq_r[15:0];
assign wfrm_data_q = wfrm_data_iq_r[31:16];
assign wfrm_axis_tready = wfrm_axis_tready_int;


endmodule
