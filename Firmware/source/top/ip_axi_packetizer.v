//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 05/26/2016 03:54:31 PM
// Design Name:
// Module Name: ip_axi_packetizer
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
// Adds IP Headers around a packet of data
//////////////////////////////////////////////////////////////////////////////////

`timescale 1 ps/1 ps

module ip_axi_packetizer #(
    parameter               DEST_IP      = 32'hC0A80A0A,  // 192.168.10.10
    parameter               SRC_IP       = 32'hC0A80A01, // 192.168.10.1
    parameter               MAX_SIZE       = 16'd532,
    parameter               MIN_SIZE       = 16'd532,
    parameter               DEST_PORT      = 16'd4000,
    parameter               SRC_PORT      = 16'd4000

)(
   input                   axi_tclk,
   input                   axi_tresetn,

   input                   enable_adc_pkt,
   input       [1:0]       speed,

       // data from ADC Data fifo
    input       [7:0]                    adc_axis_tdata,
    input                                adc_axis_tvalid,
    input                                adc_axis_tlast,
    input                                adc_axis_tuser,
    output                               adc_axis_tready,

   output reg  [7:0]       tdata,
   output                  tvalid,
   output reg              tlast,
   input                   tready
   );



localparam     IDLE        = 3'b000,
               IP_HEADER      = 3'b001,
               UDP_HEADER        = 3'b010,
               ALIGN         =3'b011,
               DATA        = 3'b100;

// work out the adjustment required to get the right packet size.
//localparam     PKT_ADJUST  = (ENABLE_VLAN) ? 22 : 18;
localparam     PKT_ADJUST  =  20;


localparam     VERSION = 4'h4;              // IP version 4
localparam     HEADER_LENGTH = 4'h5;        // 5*32 bits = 20 bytes
localparam     SERVICE_TYPE = 8'b0;
localparam     TOTAL_LENGTH = MIN_SIZE;
localparam     FLAGS = 3'b010;   
localparam     FRAGMENT_OFFSET = 13'b0; 
localparam      TTL = 8'hFF;  
localparam      PROTOCOL = 8'h11;               //UDP  
localparam      UDP_LENGTH =     TOTAL_LENGTH   - 4*HEADER_LENGTH;
// generate the required bandwidth controls based on speed
// we want to use less than 100% bandwidth to avoid loopback overflow
localparam     BW_1G       = 230;
localparam     BW_100M     = 23;
localparam     BW_10M      = 2;

reg         [15:0]        ip_id;
reg         [15:0]        ip_checksum;
reg         [15:0]        udp_checksum;
reg         [31:0]        global_pkt_counter;
reg         [15:0]        data_id;

reg         [11:0]         byte_count;
reg         [3:0]          header_count;
reg         [4:0]          overhead_count;
reg         [11:0]         pkt_size;
reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;
wire        [7:0]          lut_data;
reg                        tvalid_int;

reg                        adc_axis_tvalid_reg;
reg                        adc_axis_tlast_reg;
reg     [7:0]               adc_axis_tdata_reg;
reg                        adc_axis_tuser_reg;

reg                       adc_axis_tready_int;
wire                      adc_axis_tready_sig;

reg                       tready_reg;
// rate control signals
reg         [7:0]          basic_rc_counter;
reg                        add_credit;
reg         [12:0]         credit_count;
reg         [3:0]         align_count;
reg         [15:0]          packet_count;

wire                       axi_treset;

assign axi_treset = !axi_tresetn;

// Write interface
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
   adc_axis_tvalid_reg <= 1'b0;
   adc_axis_tlast_reg <= 1'b0;
   adc_axis_tdata_reg <= 7'b0;
   adc_axis_tuser_reg <= 1'b0;
   
   tready_reg <= 1'b0;
   end else begin
   adc_axis_tvalid_reg <= adc_axis_tvalid;
   adc_axis_tlast_reg <= adc_axis_tlast;
   adc_axis_tdata_reg[7:0] <= adc_axis_tdata[7:0];
   adc_axis_tuser_reg <= adc_axis_tuser;
  
   tready_reg <= tready;
   end
end

assign adc_axis_tready  = adc_axis_tready_int;
//assign adc_axis_tready  = adc_axis_tready_sig;

// need a packet counter - max size limited to 11 bits
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      byte_count <= 0;
   end
   else if (gen_state == DATA & |byte_count & tready & adc_axis_tvalid) begin
      byte_count <= byte_count -1;
   end
   else if (gen_state == HEADER) begin
      byte_count <= pkt_size;
   end
end

// need a smaller count to manage the header insertion
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      header_count <= 0;
   end
   else if (gen_state == HEADER & !(&header_count) & (tready | !tvalid_int)) begin
      header_count <= header_count + 1;
   end
   else if (gen_state == SIZE & tready) begin
      header_count <= 0;
   end
end

// need a smaller count to manage the alignment counter (2 bytes)
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      align_count <= 0;
   end
   else if (gen_state == SIZE & (tready | !tvalid_int) & (|align_count) & header_count==0) begin
      align_count <= align_count - 1;
   end
   else if (gen_state == IDLE) begin
      align_count <= 2;
   end
end

// 2 byte packet counter to increment with every packet
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      packet_count <= 0;
   end
   else if (gen_state == OVERHEAD & next_gen_state == IDLE) begin
      packet_count <= packet_count + 1;
   end
end


// need a count to manage the frame overhead (assume 24 bytes)
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      overhead_count <= 0;
   end
   else if (gen_state == OVERHEAD & |overhead_count & tready) begin
      overhead_count <= overhead_count - 1;
   end
   else if (gen_state == IDLE) begin
      overhead_count <= 24;
   end
end

// need a smaller count to manage the header insertion
// adjust parameter values by 18 to allow for header and crc
// so the pkt_size can be issued directly in the size field
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      pkt_size <= MIN_SIZE - PKT_ADJUST;
   end
   else if (gen_state == DATA & next_gen_state != DATA) begin
      if (pkt_size == MAX_SIZE - PKT_ADJUST)
         pkt_size <= MIN_SIZE - PKT_ADJUST;
      else
         pkt_size <= pkt_size + 1;
   end
end

// store the parametised values in a lut (64 deep)
// this should mean the values could be adjusted in fpga_editor etc..
genvar i;
generate
  for (i=0; i<=7; i=i+1) begin : lut_loop
    LUT6 #(
       .INIT      ({48'd0,
                    VLAN_HEADER[i],
                    VLAN_HEADER[i+8],
                    VLAN_HEADER[i+16],
                    VLAN_HEADER[i+24],
                    SRC_ADDR[i],
                    SRC_ADDR[i+8],
                    SRC_ADDR[i+16],
                    SRC_ADDR[i+24],
                    SRC_ADDR[i+32],
                    SRC_ADDR[i+40],
                    DEST_ADDR[i],
                    DEST_ADDR[i+8],
                    DEST_ADDR[i+16],
                    DEST_ADDR[i+24],
                    DEST_ADDR[i+32],
                    DEST_ADDR[i+40]
                   })   // Specify LUT Contents
    ) LUT6_inst (
       .O         (lut_data[i]),
       .I0        (header_count[0]),
       .I1        (header_count[1]),
       .I2        (header_count[2]),
       .I3        (header_count[3]),
       .I4        (1'b0),
       .I5        (1'b0)
    );
   end
endgenerate

// rate control logic

// first we need an always active counter to provide the credit control
always @(posedge axi_tclk)
begin
   if (axi_treset | !enable_adc_pkt)
      basic_rc_counter     <= 255;
   else
      basic_rc_counter     <= basic_rc_counter + 1;
end

// now we need to set the compare level depending upon the selected speed
// the credits are applied using a simple less-than check
always @(posedge axi_tclk)
begin
   if (speed[1])
      if (basic_rc_counter < BW_1G)
         add_credit        <= 1;
      else
         add_credit        <= 0;
   else if (speed[0])
      if (basic_rc_counter < BW_100M)
         add_credit        <= 1;
      else
         add_credit        <= 0;
   else
      if (basic_rc_counter < BW_10M)
         add_credit        <= 1;
      else
         add_credit        <= 0;
end

// basic credit counter - -ve value means do not send a frame
always @(posedge axi_tclk)
begin
   if (axi_treset)
      credit_count         <= 0;
   else begin
      // if we are in frame
      if (gen_state != IDLE) begin
         if (!add_credit & credit_count[12:10] != 3'b110)  // stop decrementing at -2048
            credit_count <= credit_count - 1;
      end
      else begin
         if (add_credit & credit_count[12:11] != 2'b01)    // stop incrementing at 2048
            credit_count <= credit_count + 1;
      end
   end
end

// simple state machine to control the data
// on the transition from IDLE we reset the counters and increment the packet size
always @(gen_state or enable_adc_pkt or header_count or tready or byte_count or tvalid_int or
         credit_count or overhead_count or adc_axis_tvalid or align_count)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if (enable_adc_pkt & !tvalid_int & !credit_count[12])
            next_gen_state = HEADER;
      end
      HEADER : begin
         if (header_count == HEADER_LENGTH & tready)
            next_gen_state = SIZE;
      end
      SIZE : begin
         // when we enter SIZE header count is initially all 1's
         // it is cleared when we enter SIZE which gives us the required two cycles in this state
         if (header_count == 0 & tready & adc_axis_tvalid & align_count == 0)
            next_gen_state = DATA;
      end
      DATA : begin
         // when an AVB AV channel we want to keep valid asserted to indicate a continuous feed of data
         //   the AVB module is then enitirely resposible for the bandwidth
         if (byte_count == 1 & tready) begin
            next_gen_state = OVERHEAD;
         end
      end
      OVERHEAD : begin
         if (overhead_count == 1 & tready) begin
            next_gen_state = IDLE;
         end
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

// need to generate the ready output 

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      adc_axis_tready_int <= 0;
   end
   else begin
   //   if (gen_state == SIZE & header_count == 0)
//     if (gen_state == SIZE & align_count == 0)
//         adc_axis_tready_int <= tready;
//      else if (gen_state == DATA & next_gen_state == DATA)
    if (next_gen_state == DATA & tready)
         adc_axis_tready_int <= 1;
      else
         adc_axis_tready_int <= 0;
   end
end

assign adc_axis_tready_sig = tready & ((gen_state == SIZE & align_count == 0) | (gen_state == DATA & next_gen_state == DATA));

// now generate the TVALID output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      tvalid_int <= 0;
   //else if (gen_state == DATA & !adc_axis_tvalid_reg)
   else if (gen_state == DATA & !adc_axis_tvalid)
      tvalid_int <= 0;
   else if (gen_state == SIZE & align_count == 0 & !adc_axis_tvalid)
      tvalid_int <= 0;     
   else if (gen_state != IDLE & gen_state != OVERHEAD)
      tvalid_int <= 1;
   else if (tready)
      tvalid_int <= 0;
end

// now generate the TDATA output
always @(posedge axi_tclk)
begin
   if (gen_state == HEADER & (tready | !tvalid_int))
      tdata <= lut_data;
   else if (gen_state == SIZE & tready) begin
      if (header_count[3])
         tdata <= {5'h0, pkt_size[10:8]};
      else if (align_count[1] & header_count == 0)
         tdata <= pkt_size[7:0];
      else if (align_count[0])
         tdata <= packet_count[15:8];
      else if (align_count == 0)
         tdata <= packet_count[7:0];
   end
  // else if (tready & adc_axis_tvalid)
  //    tdata <= adc_axis_tdata[7:0];
    else if (tready & adc_axis_tvalid_reg)
      tdata <= adc_axis_tdata[7:0];
end


// now generate the TLAST output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      tlast <= 0;
   else if (byte_count == 1 & tready)
      tlast <= 1;
   else if (tready)
      tlast <= 0;
end

assign tvalid = tvalid_int;


endmodule
