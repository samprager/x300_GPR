//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 06/30/2016 03:54:31 PM
// Design Name:
// Module Name: ethernet_rgmii_axi_rx_decoder
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

module ethernet_rgmii_axi_rx_decoder #(
  parameter               DEST_ADDR      = 48'hda0102030405,
  parameter               SRC_ADDR       = 48'h5a0102030405,
  parameter               MAX_SIZE       = 16'd500,
  parameter               MIN_SIZE       = 16'd500,
  parameter               ENABLE_VLAN    = 1'b0,
  parameter               VLAN_ID        = 12'd2,
  parameter               VLAN_PRIORITY  = 3'd2,

    parameter               REG_WIDTH = 4,        // size of data registers in bytes
    parameter               NUM_REG = 6,
    parameter               PKT_SIZE_LEN = 2,     // length of packet size in bytes
    parameter               PKT_CTR_LEN = 2,
    parameter               CMD_LENGTH = 4,      // length of packet command word in bytes
    parameter               PKT_ID_LENGTH = 4,   // length of packet id word in bytes
    parameter               REG_MAP_OUT_LEN = REG_WIDTH*NUM_REG+CMD_LENGTH+PKT_ID_LENGTH

)(
   input                   axi_tclk,
   input                   axi_tresetn,

   input                   enable_rx_decode,
   input       [1:0]       speed,

       // data from ADC Data fifo
    input       [7:0]                    rx_axis_tdata,
    input                                rx_axis_tvalid,
    input                                rx_axis_tlast,
    output                               rx_axis_tready,

    output    [31:0] tdata,
    output          tvalid,
    output          tlast,
    input           tready

  //  output reg  [8*REG_WIDTH-1:0]        reg_map_axis_tdata,
  //  output reg                           reg_map_axis_tvalid,
  //  output reg                           reg_map_axis_tlast,
  //  input                                reg_map_axis_tready
   );



localparam     IDLE        = 3'b000,
               NEXT_PKT    = 3'b001,
               HEADER      = 3'b010,
               SIZE        = 3'b011,
               COUNTER     = 3'b100,
               DATA        = 3'b101,
               OVERHEAD    = 3'b110;

// work out the adjustment required to get the right packet size.
//localparam     PKT_ADJUST  = (ENABLE_VLAN) ? 22 : 18;
localparam     PKT_ADJUST  = (ENABLE_VLAN) ? 24 : 20;

// generate the vlan fields
localparam     VLAN_HEADER = {8'h81, 8'h00, VLAN_PRIORITY, 1'b0, VLAN_ID};

// generate the require header count compare
localparam     HEADER_LENGTH = (ENABLE_VLAN) ? 15 : 11;

// total offset for command packet header
localparam    CMD_HEADER_OFFSET = HEADER_LENGTH + PKT_SIZE_LEN + CMD_LENGTH+ PKT_ID_LENGTH;

// generate the required bandwidth controls based on speed
// we want to use less than 100% bandwidth to avoid loopback overflow
localparam     BW_1G       = 230;
localparam     BW_100M     = 23;
localparam     BW_10M      = 2;

reg [47:0]                 dest_mac_addr;
reg [47:0]                 src_mac_addr;


reg         [8*PKT_SIZE_LEN-1:0]         byte_count;
reg         [3:0]                        header_count;
reg         [3:0]                       src_mac_count;
reg         [3:0]                       dest_mac_count;
reg         [4:0]                        overhead_count;
reg         [3:0]                        size_count;
reg         [3:0]                        counter_count;
reg         [8*PKT_SIZE_LEN-1:0]          pkt_size;
reg         [8*PKT_CTR_LEN-1:0]           pkt_counter;
// reg         [8*PKT_ID_LENGTH-1:0]         pkt_id;

reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;

reg                         rx_axis_tvalid_reg;
reg                         rx_axis_tlast_reg;
reg     [7:0]               rx_axis_tdata_reg;

reg                        rx_axis_tready_int;

reg       [7:0]                    wr_fifo_rx_axis_tdata_reg;
reg                                wr_fifo_rx_axis_tvalid_reg;
reg                                wr_fifo_rx_axis_tlast_reg;

reg       [31:0]                    wr_fifo32_rx_axis_tdata_reg;
reg                                wr_fifo32_rx_axis_tvalid_reg;
reg                                wr_fifo32_rx_axis_tlast_reg;
wire                                wr_fifo32_rx_axis_tready;

// wire       [7:0]                    wr_fifo_rx_axis_tdata;
// wire                                wr_fifo_rx_axis_tvalid;
// wire                                wr_fifo_rx_axis_tlast;
wire                                wr_fifo_rx_axis_tready;

// wire       [8*REG_WIDTH-1:0]        rd_fifo_rx_axis_tdata;
// wire                                rd_fifo_rx_axis_tvalid;
// wire                                rd_fifo_rx_axis_tlast;
// wire                                rd_fifo_rx_axis_tready;

reg                       pkt_good;
reg                       rx_axis_tlast_aligned;
reg                       prev_tlast_aligned;

reg [1:0]                   width_conv_count;

wire                       axi_treset;

assign axi_treset = !axi_tresetn;

// Write interface
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
   rx_axis_tvalid_reg <= 1'b0;
   rx_axis_tlast_reg <= 1'b0;
   rx_axis_tdata_reg <= 7'b0;
   end else begin
   rx_axis_tvalid_reg <= rx_axis_tvalid;
   rx_axis_tlast_reg <= rx_axis_tlast;
   rx_axis_tdata_reg[7:0] <= rx_axis_tdata[7:0];
   end
end

// need a width conversion counter - max size limited to 11 bits
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      width_conv_count <= 0;
   end
   else if (gen_state == DATA & rx_axis_tready_int & rx_axis_tvalid) begin
      width_conv_count <= width_conv_count + 1'b1;
   end
   else if (gen_state == COUNTER) begin
      width_conv_count <= 1'b0;
   end
end

// need a packet counter - max size limited to 11 bits
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      byte_count <= 0;
   end
   else if (gen_state == DATA & |byte_count & rx_axis_tready_int & rx_axis_tvalid) begin
      byte_count <= byte_count -1;
   end
   else if (gen_state == COUNTER) begin
      byte_count <= pkt_size - PKT_CTR_LEN;
   end
end


// need a smaller count to manage the header insertion
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      header_count <= 0;
   end
   else if (gen_state == HEADER & !(&header_count) & rx_axis_tready_int & rx_axis_tvalid) begin
      header_count <= header_count + 1;
   end
   //else if (gen_state == SIZE & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_PKT | gen_state == SIZE) & rx_axis_tready_int & rx_axis_tvalid) begin
      header_count <= 0;
   end
end

// need a dst and src mac count count
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      dest_mac_count <= 4'b0110;
   end
   //else if (gen_state == HEADER & rx_axis_tready_int & rx_axis_tvalid & |dest_mac_count & |header_count) begin
   else if (gen_state == HEADER & rx_axis_tready_int & rx_axis_tvalid & |dest_mac_count) begin
      dest_mac_count <= dest_mac_count - 1;
   end
   //else if (gen_state == SIZE & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_PKT | gen_state == SIZE) & rx_axis_tready_int & rx_axis_tvalid) begin
      dest_mac_count <= 4'b0110;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      src_mac_count <= 0;
   end
   else if (gen_state == HEADER & rx_axis_tready_int & rx_axis_tvalid & dest_mac_count == 1'b1) begin
      src_mac_count <= 4'b0110;
   end
   else if (gen_state == HEADER & rx_axis_tready_int & rx_axis_tvalid & |src_mac_count) begin
      src_mac_count <= src_mac_count - 1;
   end
   //else if (gen_state == SIZE & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_PKT | gen_state == SIZE) & rx_axis_tready_int & rx_axis_tvalid) begin
      src_mac_count <= 0;
   end
end

// need a smaller count to manage the header insertion
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      size_count <= 0;
   end
   else if (gen_state == SIZE & !(&size_count) & rx_axis_tready_int & rx_axis_tvalid) begin
      size_count <= size_count + 1;
   end
   //else if (gen_state == COUNTER & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_PKT | gen_state == COUNTER) & rx_axis_tready_int & rx_axis_tvalid) begin
      size_count <= 0;
   end
end

// need a smaller count to manage the header insertion
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      counter_count <= 0;
   end
   else if (gen_state == COUNTER & !(&counter_count) & rx_axis_tready_int & rx_axis_tvalid) begin
      counter_count <= counter_count + 1;
   end
   //else if (gen_state == DATA & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_PKT | gen_state == DATA) & rx_axis_tready_int & rx_axis_tvalid) begin
      counter_count <= 0;
   end
end


// need a count to manage the frame overhead (assume 24 bytes)
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      overhead_count <= 0;
   end
   else if (gen_state == OVERHEAD & |overhead_count & wr_fifo_rx_axis_tready) begin
      overhead_count <= overhead_count - 1;
   end
   else if (gen_state == IDLE) begin
      overhead_count <= 24;
   end
end


// simple state machine to control the data
// on the transition from IDLE we reset the counters and increment the packet size
always @(gen_state or enable_rx_decode or header_count or counter_count or size_count or wr_fifo_rx_axis_tready or byte_count or wr_fifo_rx_axis_tvalid_reg or overhead_count or rx_axis_tvalid or rx_axis_tlast or rx_axis_tready_int or rx_axis_tlast_aligned)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if (enable_rx_decode & !wr_fifo_rx_axis_tvalid_reg & wr_fifo_rx_axis_tready) begin
            if (rx_axis_tlast_aligned)
                next_gen_state = HEADER;
            else
            next_gen_state = NEXT_PKT;
         end
      end
      NEXT_PKT : begin
        // if (rx_axis_tvalid & (rx_axis_tlast | prev_tlast_aligned) & rx_axis_tready_int)
        if (rx_axis_tvalid & rx_axis_tlast & rx_axis_tready_int)
            next_gen_state = HEADER;
      end
      HEADER : begin
         if (!pkt_good)
            next_gen_state = NEXT_PKT;
         else if (header_count == HEADER_LENGTH & rx_axis_tvalid)
            next_gen_state = SIZE;
      end
      SIZE : begin
         // when we enter SIZE header count is initially all 1's
         // it is cleared when we enter SIZE which gives us the required two cycles in this state
         if (size_count ==  (PKT_SIZE_LEN-1) & rx_axis_tvalid)
            next_gen_state = COUNTER;
      end
      COUNTER : begin
         // when we enter SIZE header count is initially all 1's
         // it is cleared when we enter SIZE which gives us the required two cycles in this state
         if (!pkt_good)
            next_gen_state = NEXT_PKT;
         else if (counter_count ==  (PKT_CTR_LEN-1)  & rx_axis_tvalid)
            next_gen_state = DATA;
      end
      DATA : begin
         // when an AVB AV channel we want to keep valid asserted to indicate a continuous feed of data
         //   the AVB module is then enitirely resposible for the bandwidth
         if (byte_count == 1 & wr_fifo_rx_axis_tready) begin
            next_gen_state = OVERHEAD;
         end
      end
      OVERHEAD : begin
         if (overhead_count == 1 & wr_fifo_rx_axis_tready) begin
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

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      pkt_good <= 0;
   end
   else if (gen_state == NEXT_PKT)
      pkt_good <= 1'b1;
   else if (gen_state == HEADER & !(|dest_mac_count)) begin
      if (dest_mac_addr != SRC_ADDR)
        pkt_good <= 1'b0;
    // end else if(gen_state == COUNTER) begin
    //    if (pkt_size != (REG_MAP_OUT_LEN + PKT_CTR_LEN))
    //      pkt_good <= 1'b0;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      dest_mac_addr <= 0;
   end
   else if (gen_state == HEADER & |dest_mac_count &rx_axis_tvalid & rx_axis_tready_int) begin
      dest_mac_addr[8*dest_mac_count-1-:8] <= rx_axis_tdata[7:0];
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      src_mac_addr <= 0;
   end
   else if (gen_state == HEADER & |src_mac_count &(|src_mac_count) &rx_axis_tvalid & rx_axis_tready_int) begin
      src_mac_addr[8*src_mac_count-1-:8] <= rx_axis_tdata[7:0];
   end
end

// Does not reverse incoming byte order
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      pkt_size <= 0;
   end
   else if (gen_state == SIZE & rx_axis_tvalid_reg & rx_axis_tready) begin
      pkt_size[8*(PKT_SIZE_LEN-1-size_count)+7-:8] <= rx_axis_tdata[7:0];
   end
end

// Reverses incoming byte order
//always @(posedge axi_tclk)
//begin
//   if (axi_treset) begin
//      pkt_size <= 0;
//   end
//   else if (gen_state == SIZE & rx_axis_tvalid_reg & rx_axis_tready) begin
//      pkt_size[8*size_count+7-:8] <= rx_axis_tdata[7:0];
//   end
//end

// Reverses incoming byte order
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      pkt_counter <= 0;
   end
   else if (gen_state == COUNTER & rx_axis_tvalid_reg & rx_axis_tready) begin
      pkt_counter[8*counter_count+7-:8] <= rx_axis_tdata[7:0];
   end
end

// Does not reverse incoming byte order
//always @(posedge axi_tclk)
//begin
//   if (axi_treset) begin
//      pkt_counter <= 0;
//   end
//   else if (gen_state == COUNTER & rx_axis_tvalid_reg & rx_axis_tready) begin
//      pkt_counter[8*(PKT_CTR_LEN-1-counter_count)+7-:8] <= rx_axis_tdata[7:0];
//   end
//end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      wr_fifo32_rx_axis_tdata_reg <= 0;
   end
   else if (gen_state == DATA & rx_axis_tvalid_reg & rx_axis_tready) begin
      wr_fifo32_rx_axis_tdata_reg[8*width_conv_count +7 -:8] <= rx_axis_tdata[7:0];
   end
end


// now generate the WR fifo TVALID output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      wr_fifo32_rx_axis_tvalid_reg <= 0;
   //else if (gen_state == DATA & !adc_axis_tvalid_reg)
   //else if (gen_state == DATA & rx_axis_tvalid)
   else if (gen_state == DATA & rx_axis_tvalid & wr_fifo32_rx_axis_tready & (&width_conv_count))
      wr_fifo32_rx_axis_tvalid_reg <= 1'b1;
   else if (wr_fifo32_rx_axis_tready)
      wr_fifo32_rx_axis_tvalid_reg <= 0;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
      wr_fifo32_rx_axis_tlast_reg <= 0;
   else if (byte_count == 1 & wr_fifo32_rx_axis_tready& (&width_conv_count))
      wr_fifo32_rx_axis_tlast_reg <= 1;
   else if (wr_fifo32_rx_axis_tready)
      wr_fifo32_rx_axis_tlast_reg <= 0;
end



always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      wr_fifo_rx_axis_tdata_reg <= 0;
   end
   else if (gen_state == DATA & rx_axis_tvalid_reg & rx_axis_tready) begin
      wr_fifo_rx_axis_tdata_reg <= rx_axis_tdata[7:0];
   end
end

// always @(posedge axi_tclk)
// begin
//    if (axi_treset) begin
//       wr_fifo_rx_axis_tlast_reg <= 0;
//    end
//    else if (gen_state == DATA & rx_axis_tvalid_reg & rx_axis_tready) begin
//       wr_fifo_rx_axis_tlast_reg <= rx_axis_tlast;
//    end
// end

always @(posedge axi_tclk)
begin
   if (axi_treset)
      rx_axis_tlast_aligned <= 0;
   else if (byte_count == 1 & wr_fifo_rx_axis_tready & rx_axis_tlast)
      rx_axis_tlast_aligned <= 1;
   else if (gen_state == HEADER)
      rx_axis_tlast_aligned <= 0;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
      prev_tlast_aligned <= 0;
   else if ((gen_state == NEXT_PKT | gen_state == IDLE) & rx_axis_tlast_aligned)
      prev_tlast_aligned <= 1;
   else
      prev_tlast_aligned <= 0;
end


// now generate the TLAST output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      wr_fifo_rx_axis_tlast_reg <= 0;
   else if (byte_count == 1 & wr_fifo_rx_axis_tready)
      wr_fifo_rx_axis_tlast_reg <= 1;
   else if (wr_fifo_rx_axis_tready)
      wr_fifo_rx_axis_tlast_reg <= 0;
end


// now generate the WR fifo TVALID output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      wr_fifo_rx_axis_tvalid_reg <= 0;
   //else if (gen_state == DATA & !adc_axis_tvalid_reg)
   //else if (gen_state == DATA & rx_axis_tvalid)
   else if (gen_state == DATA & rx_axis_tvalid & wr_fifo_rx_axis_tready)
      wr_fifo_rx_axis_tvalid_reg <= 1'b1;
   else if (wr_fifo_rx_axis_tready)
      wr_fifo_rx_axis_tvalid_reg <= 0;
end

// need to generate the ready output

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      rx_axis_tready_int <= 0;
   end
   else begin
    if (next_gen_state == DATA & wr_fifo_rx_axis_tready)
         rx_axis_tready_int <= 1;
   else if(gen_state == SIZE | gen_state==COUNTER | gen_state == HEADER | gen_state == NEXT_PKT)
        rx_axis_tready_int <= 1;
    else
        rx_axis_tready_int <= 0;
   end
end


//assign tvalid = wr_fifo_rx_axis_tvalid_reg;
//assign tlast = wr_fifo_rx_axis_tlast_reg;
//assign tdata = wr_fifo_rx_axis_tdata_reg;

assign tvalid = wr_fifo32_rx_axis_tvalid_reg;
assign tlast = wr_fifo32_rx_axis_tlast_reg;
assign tdata = wr_fifo32_rx_axis_tdata_reg;

assign rx_axis_tready = rx_axis_tready_int;

assign wr_fifo_rx_axis_tready = tready;

assign wr_fifo32_rx_axis_tready = tready;


endmodule
