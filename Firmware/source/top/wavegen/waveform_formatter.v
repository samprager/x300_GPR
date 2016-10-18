//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 08/14/2016 03:54:31 PM
// Design Name:
// Module Name: waveform_formatter
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

module waveform_formatter(
   input                   axi_tclk,
   input                   axi_tresetn,

   input                   wf_write_ready,
   output                  [127:0] waveform_parameters,
   output                  init_wf_write,
       // data from ADC Data fifo
    input       [31:0]                    wfrm_axis_tdata,
    input                                 wfrm_axis_tvalid,
    input                                 wfrm_axis_tlast,
    input       [3:0]                     wfrm_axis_tkeep,
    input       [3:0]                     wfrm_axis_tdest,
    input       [3:0]                     wfrm_axis_tid,
    input      [31:0]                     wfrm_axis_tuser,
    output                                wfrm_axis_tready,

    output    [31:0] tdata,
    output           tvalid,
    output           tlast,
    output    [3:0]  tkeep,
    output    [3:0]  tdest,
    output    [3:0]  tid,
    output    [31:0] tuser,
    input            tready

  //  output reg  [8*REG_WIDTH-1:0]        reg_map_axis_tdata,
  //  output reg                           reg_map_axis_tvalid,
  //  output reg                           reg_map_axis_tlast,
  //  input                                reg_map_axis_tready
   );



localparam     IDLE        = 3'b000,
               NEXT_CMD    = 3'b001,
               HEADER       = 3'b010,
               DATA        = 3'b011,
               OVERHEAD    = 3'b100;

localparam     CHIRP_WRITE_COMMAND = 32'h57574343;     //Ascii WWCC
localparam     FMC150_WRITE_COMMAND = 32'h57574646;     //Ascii WWFF
localparam     DATA_WRITE_COMMAND = 32'h57574441;       //Ascii WWDA

localparam    CHIRP_READ_COMMAND = 32'h52524343;         //Ascii RRCC
localparam    FMC150_READ_COMMAND = 32'h52524646;         //Ascii RRFF

localparam    HEADER_LENGTH = 2;

reg [31:0]                 next_wfrm_id;
reg [31:0]                 next_wfrm_ind;
reg [31:0]                 next_wfrm_len;
reg [31:0]                 next_wfrm_placeholder;

reg [31:0]                 curr_wfrm_id;
reg [31:0]                 curr_wfrm_ind;
reg [31:0]                 curr_wfrm_len;
reg [31:0]                 curr_wfrm_placeholder;

reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;
reg         [4:0]          overhead_count;
reg         [31:0]         data_count;
reg         [7:0]         header_count;

reg                         wfrm_axis_tvalid_reg;
reg                         wfrm_axis_tlast_reg;
reg     [31:0]              wfrm_axis_tdata_reg;

//reg                         wfrm_axis_tready_int;
wire                         wfrm_axis_tready_int;

reg                         init_wf_write_reg;
reg         [127:0]         waveform_parameters_reg;

reg       [31:0]                   tdata_reg;
reg                                tvalid_reg;
reg                                tlast_reg;
reg       [3:0]                    tdest_reg;
reg       [3:0]                    tid_reg;
reg       [3:0]                    tkeep_reg;
reg       [31:0]                   tuser_reg;

reg                       has_waveform;
reg                       new_waveform;
reg                       new_command;
reg                       cont_command;
reg                       waveform_good;


wire                       axi_treset;

assign axi_treset = !axi_tresetn;

// Write interface
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
   wfrm_axis_tvalid_reg <= 1'b0;
   wfrm_axis_tlast_reg <= 1'b0;
   wfrm_axis_tdata_reg <= 32'b0;
   end else begin
   wfrm_axis_tvalid_reg <= wfrm_axis_tvalid;
   wfrm_axis_tlast_reg <= wfrm_axis_tlast;
   wfrm_axis_tdata_reg[31:0] <= wfrm_axis_tdata[31:0];
   end
end



// need a count to manage the frame overhead (assume 24 bytes)
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      overhead_count <= 0;
   end
   else if (gen_state == OVERHEAD & |overhead_count) begin
      overhead_count <= overhead_count - 1;
   end
   else if (gen_state == IDLE) begin
      overhead_count <= 24;
   end
end

// need a count to manage the frame overhead (assume 24 bytes)
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      data_count <= 0;
   end
   else if (gen_state == DATA & |data_count & wfrm_axis_tready_int & wfrm_axis_tvalid) begin
      data_count <= data_count - 1;
   end
   else if (gen_state == HEADER & new_waveform & header_count == HEADER_LENGTH) begin
      data_count <= next_wfrm_len;
   end
end

// need a smaller count to manage the header insertion
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      header_count <= 0;
   end
   else if (gen_state == HEADER & !(&header_count) & wfrm_axis_tready_int & wfrm_axis_tvalid) begin
      header_count <= header_count + 1;
   end
   //else if (gen_state == SIZE & rx_axis_tready_int & rx_axis_tvalid) begin
   else if ((gen_state == NEXT_CMD | gen_state == DATA) & wfrm_axis_tready_int & wfrm_axis_tvalid) begin
      header_count <= 0;
   end
end


// simple state machine to control the data
// on the transition from IDLE we reset the counters and increment the packet size
always @(gen_state or new_command or wf_write_ready or cont_command or waveform_good or data_count or header_count or tready or tvalid_reg or overhead_count or wfrm_axis_tvalid or wfrm_axis_tlast or wfrm_axis_tready_int)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if ((!tvalid_reg & tready) | wf_write_ready) begin
            next_gen_state = NEXT_CMD;
         end
      end
      NEXT_CMD : begin
        // if (rx_axis_tvalid & (rx_axis_tlast | prev_tlast_aligned) & rx_axis_tready_int)
        if (new_command &  & wfrm_axis_tvalid & wfrm_axis_tready_int)
            next_gen_state = HEADER;
      end
      HEADER : begin
        // if (rx_axis_tvalid & (rx_axis_tlast | prev_tlast_aligned) & rx_axis_tready_int)
        if (!waveform_good)
            next_gen_state = NEXT_CMD;
        else if (header_count == HEADER_LENGTH & wfrm_axis_tvalid)
            next_gen_state = DATA;
      end
      DATA : begin
         // when an AVB AV channel we want to keep valid asserted to indicate a continuous feed of data
         //   the AVB module is then enitirely resposible for the bandwidth
         if (wfrm_axis_tlast == 1 & tready & wfrm_axis_tvalid & data_count == 1) begin
            next_gen_state = OVERHEAD;
         end
         else if (wfrm_axis_tlast == 1 & tready & wfrm_axis_tvalid) begin
            next_gen_state = NEXT_CMD;
         end
      end
      OVERHEAD : begin
         if (overhead_count == 1) begin
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
  if (axi_treset)
    new_command <= 1'b0;
  else if (gen_state == NEXT_CMD & wfrm_axis_tvalid & wfrm_axis_tready_int) begin
    if ((wfrm_axis_tdata == DATA_WRITE_COMMAND))
      new_command <= 1'b1;
    else
      new_command <= 1'b0;
  end else if (gen_state != NEXT_CMD)
      new_command <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    cont_command <= 1'b0;
  else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int) begin
    if ((wfrm_axis_tdata == DATA_WRITE_COMMAND))
      cont_command <= 1'b1;
    else
      cont_command <= 1'b0;
  end else
      cont_command <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_wfrm_id <= 0;
  else if (gen_state == NEXT_CMD & new_command & wfrm_axis_tvalid & wfrm_axis_tready_int)
    next_wfrm_id <= wfrm_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_wfrm_ind <= 0;
  else if (gen_state == HEADER & wfrm_axis_tvalid & wfrm_axis_tready_int & header_count == 0)
    next_wfrm_ind <= wfrm_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_wfrm_len <= 0;
  else if (gen_state == HEADER & wfrm_axis_tvalid & wfrm_axis_tready_int & header_count == 1)
    next_wfrm_len <= wfrm_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_wfrm_placeholder <= 0;
  else if (gen_state == HEADER & wfrm_axis_tvalid & wfrm_axis_tready_int & header_count == 2)
    next_wfrm_placeholder <= wfrm_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    waveform_good <= 0;
  else if (gen_state == NEXT_CMD)
     waveform_good <= 1'b1;
  else if (gen_state == HEADER & wfrm_axis_tvalid & wfrm_axis_tready_int & header_count == 1) begin
    if((next_wfrm_id != curr_wfrm_id)|(!has_waveform)) begin
      if (|next_wfrm_ind)
        waveform_good <= 1'b0;
     end else begin
      if (next_wfrm_ind != curr_wfrm_ind+1)
        waveform_good <= 1'b0;
      else if(wfrm_axis_tdata != curr_wfrm_len)
        waveform_good <= 1'b0;
    end
  end
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    new_waveform <= 0;
  else if (gen_state == HEADER & header_count == 1 & ((next_wfrm_id != curr_wfrm_id) | (!has_waveform)) & !(|next_wfrm_ind) & wfrm_axis_tvalid & wfrm_axis_tready_int)
    new_waveform <= 1'b1;
  else
    new_waveform <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    init_wf_write_reg <= 0;
  else if (new_waveform)
    init_wf_write_reg <= 1'b1;
  else if(wf_write_ready)
    init_wf_write_reg <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    waveform_parameters_reg <= 'b0;
  else if (new_waveform)
    waveform_parameters_reg[31:0] <= next_wfrm_len;
end


always @(posedge axi_tclk)
begin
  if (axi_treset)
    has_waveform <= 0;
  else if (new_waveform)
    has_waveform <= 1'b1;
  else
    has_waveform <= has_waveform;
end



always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_wfrm_id <= 0;
  else if (new_waveform)
    curr_wfrm_id <= next_wfrm_id;
  else
    curr_wfrm_id <= curr_wfrm_id;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_wfrm_ind <= 0;
  else if (gen_state == HEADER & waveform_good & header_count == HEADER_LENGTH)
    curr_wfrm_ind <= next_wfrm_ind;
  else
    curr_wfrm_ind <= curr_wfrm_ind;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_wfrm_len <= 0;
  else if (new_waveform)
    curr_wfrm_len <= next_wfrm_len;
  else
    curr_wfrm_len <= curr_wfrm_len;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_wfrm_placeholder <= 0;
  else
    curr_wfrm_placeholder <= next_wfrm_placeholder;
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tdata_reg <= 0;
   end
   else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int) begin
      tdata_reg <= wfrm_axis_tdata;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tuser_reg <= 0;
   end
   else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int) begin
      tuser_reg <= curr_wfrm_len;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tkeep_reg <= 0;
   end
   else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int) begin
      tkeep_reg <= 4'hf;
   end
end

// now generate the WR fifo TID output
always @(posedge axi_tclk)
begin
   tid_reg <= 0;
end

always @(posedge axi_tclk)
begin
   if (axi_treset)
      tdest_reg <= 0;
   else if (gen_state == DATA & wfrm_axis_tvalid & wfrm_axis_tready_int)
      tdest_reg <= 4'b0010;
end


// now generate the TLAST output
always @(posedge axi_tclk)
begin
   if (axi_treset)
    tlast_reg <= 0;
   //else if (gen_state == DATA &  wfrm_axis_tvalid & wfrm_axis_tready_int & wfrm_axis_tlast)
   else if (gen_state == DATA &  (data_count == 1))
      tlast_reg <= 1;
   else if (tready)
      tlast_reg <= 0;
end


// now generate the WR fifo TVALID output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      tvalid_reg <= 0;
   else if (gen_state == DATA & wfrm_axis_tvalid & tready ) //& !(tvalid_reg & tready & !wfrm_axis_tready_int))
      tvalid_reg <= 1'b1;
   else if (tready)
      tvalid_reg <= 0;
end

// need to generate the ready output

//always @(posedge axi_tclk)
//begin
//   if (axi_treset) begin
//      wfrm_axis_tready_int <= 0;
//   end
//   else begin
//    if (next_gen_state == DATA & tready)
//         wfrm_axis_tready_int <= 1;
//   //else if(gen_state == NEXT_CMD & (!new_command | tready))
//   else if(gen_state == NEXT_CMD | gen_state == HEADER)
//        wfrm_axis_tready_int <= 1;
//    else
//        wfrm_axis_tready_int <= 0;
//   end
//end

assign wfrm_axis_tready_int = ((gen_state == DATA & tready) | (gen_state == NEXT_CMD | gen_state == HEADER));

//assign tvalid = wr_fifo_rx_axis_tvalid_reg;
//assign tlast = wr_fifo_rx_axis_tlast_reg;
//assign tdata = wr_fifo_rx_axis_tdata_reg;

assign tvalid = tvalid_reg;
assign tlast = tlast_reg;
assign tdata = tdata_reg;
assign tuser = tuser_reg;
assign tdest = tdest_reg;
assign tkeep = tkeep_reg;
assign tid = tid_reg;

assign wfrm_axis_tready = wfrm_axis_tready_int;
assign init_wf_write = init_wf_write_reg;

assign waveform_parameters = waveform_parameters_reg;


endmodule
