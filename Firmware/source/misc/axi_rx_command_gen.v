//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 06/30/2016 03:54:31 PM
// Design Name:
// Module Name: axi_rx_command_gen
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

module axi_rx_command_gen #(
    parameter               REG_WIDTH = 4,        // size of data registers in bytes
    parameter               NUM_REG = 7

)(
   input                   axi_tclk,
   input                   axi_tresetn,

   input                   enable_rx_decode,

       // data from ADC Data fifo
    input       [31:0]                    cmd_axis_tdata,
    input                                 cmd_axis_tvalid,
    input                                 cmd_axis_tlast,
    output                                cmd_axis_tready,

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
               DATA        = 3'b010,
               OVERHEAD    = 3'b011;

localparam     CHIRP_WRITE_COMMAND = 32'h57574343;     //Ascii WWCC
localparam     FMC150_WRITE_COMMAND = 32'h57574646;     //Ascii WWFF
localparam     DATA_WRITE_COMMAND = 32'h57574441;       //Ascii WWDA

localparam    CHIRP_READ_COMMAND = 32'h52524343;         //Ascii RRCC
localparam    FMC150_READ_COMMAND = 32'h52524646;         //Ascii RRFF


reg [31:0]                 next_cmd_word;
reg [31:0]                 next_cmd_id;

reg [31:0]                 curr_cmd_word;
reg [31:0]                 curr_cmd_id;



reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;
reg         [4:0]                        overhead_count;


reg                         cmd_axis_tvalid_reg;
reg                         cmd_axis_tlast_reg;
reg     [31:0]               cmd_axis_tdata_reg;

reg                        cmd_axis_tready_int;

reg       [31:0]                   tdata_reg;
reg                                tvalid_reg;
reg                                tlast_reg;
reg       [3:0]                    tdest_reg;
reg       [3:0]                    tid_reg;
reg       [3:0]                    tkeep_reg;
reg       [31:0]                   tuser_reg;

reg                       has_command;
reg                       new_command;
reg                       write_command;
reg                       read_command;



wire                       axi_treset;

assign axi_treset = !axi_tresetn;

// Write interface
always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      cmd_axis_tvalid_reg      <= 1'b0;
      cmd_axis_tlast_reg       <= 1'b0;
      cmd_axis_tdata_reg       <= 32'b0;
   end else begin
      cmd_axis_tvalid_reg      <= cmd_axis_tvalid;
      cmd_axis_tlast_reg       <= cmd_axis_tlast;
      cmd_axis_tdata_reg[31:0] <= cmd_axis_tdata[31:0];
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


// simple state machine to control the data
// on the transition from IDLE we reset the counters and increment the packet size
always @(gen_state or enable_rx_decode or new_command or tready or tvalid_reg or overhead_count or cmd_axis_tvalid or cmd_axis_tlast or cmd_axis_tready_int)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if (enable_rx_decode & !tvalid_reg & tready) begin
            next_gen_state = NEXT_CMD;
         end
      end
      NEXT_CMD : begin
        // if (rx_axis_tvalid & (rx_axis_tlast | prev_tlast_aligned) & rx_axis_tready_int)
        if (new_command)
            next_gen_state = DATA;
      end
      DATA : begin
         // when an AVB AV channel we want to keep valid asserted to indicate a continuous feed of data
         //   the AVB module is then enitirely resposible for the bandwidth
         if (cmd_axis_tlast == 1 & tready & cmd_axis_tvalid) begin
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


always @(posedge axi_tclk)
begin
  if (axi_treset) begin
    write_command <= 1'b0;
  end
  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int) begin
    if ((cmd_axis_tdata == CHIRP_WRITE_COMMAND) | (cmd_axis_tdata == FMC150_WRITE_COMMAND)|(cmd_axis_tdata == DATA_WRITE_COMMAND))
      write_command <= 1'b1;
    else
      write_command <= 1'b0;
  end else if (gen_state != NEXT_CMD)
      write_command <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset) begin
    read_command <= 1'b0;
  end
  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int) begin
    if ((cmd_axis_tdata == CHIRP_READ_COMMAND) | (cmd_axis_tdata == FMC150_READ_COMMAND))
      read_command <= 1'b1;
    else
      read_command <= 1'b0;
  end else if (gen_state != NEXT_CMD)
      read_command <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_cmd_word <= 0;
  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & !write_command & !read_command)
    next_cmd_word <= cmd_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    next_cmd_id <= 0;
  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & (write_command | read_command))
    next_cmd_id <= cmd_axis_tdata;
end

always @(posedge axi_tclk)
begin
  if (axi_treset) begin
    new_command <= 0;
  end
  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & (write_command | read_command)) begin
      if (cmd_axis_tdata != curr_cmd_id)
        new_command <= 1'b1;
      else
        new_command <= 1'b0;
  end else if (gen_state != NEXT_CMD)
      new_command <= 1'b0;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_cmd_word <= 0;
  else if ((write_command | read_command))
      curr_cmd_word <= next_cmd_word;
  else
      curr_cmd_word <= curr_cmd_word;
end

always @(posedge axi_tclk)
begin
  if (axi_treset)
    curr_cmd_id <= 0;
  else if (new_command)
      curr_cmd_id <= next_cmd_id;
  else
      curr_cmd_id <= curr_cmd_id;
end


always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tdata_reg <= 0;
   end
   else if (gen_state == DATA & cmd_axis_tvalid & cmd_axis_tready_int) begin
      tdata_reg <= cmd_axis_tdata;
   end
  //  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & new_command) begin
  //    tdata_reg <= cmd_axis_tdata;
  else if (gen_state == NEXT_CMD & new_command) begin
    tdata_reg <= curr_cmd_word;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tuser_reg <= 0;
   end
   else if (gen_state == DATA & cmd_axis_tvalid & cmd_axis_tready_int) begin
      tuser_reg <= curr_cmd_id;
   end
  //  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & new_command) begin
  //    tdata_reg <= cmd_axis_tdata;
  else if (gen_state == NEXT_CMD & new_command) begin
    tuser_reg <= next_cmd_id;
   end
end

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      tkeep_reg <= 0;
   end
   else if (gen_state == DATA & cmd_axis_tvalid & cmd_axis_tready_int) begin
      tkeep_reg <= 4'hf;
   end
  //  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & new_command) begin
  //    tdata_reg <= cmd_axis_tdata;
  else if (gen_state == NEXT_CMD & new_command) begin
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
   if (axi_treset) begin
      tdest_reg <= 0;
   end
   else if (gen_state == DATA & cmd_axis_tvalid & cmd_axis_tready_int) begin
      if(curr_cmd_word == CHIRP_WRITE_COMMAND)
        tdest_reg <= 4'b0000;
      else if(curr_cmd_word == FMC150_WRITE_COMMAND)
        tdest_reg <= 4'b0001;
     else if(curr_cmd_word == DATA_WRITE_COMMAND)
          tdest_reg <= 4'b0010;
      else if(curr_cmd_word == FMC150_READ_COMMAND)
          tdest_reg <= 4'b0011;
      else if(curr_cmd_word == CHIRP_READ_COMMAND)
          tdest_reg <= 4'b0011;

   end
  //  else if (gen_state == NEXT_CMD & cmd_axis_tvalid & cmd_axis_tready_int & new_command) begin
  //    tdata_reg <= cmd_axis_tdata;
  else if (gen_state == NEXT_CMD & new_command) begin
    if(curr_cmd_word == CHIRP_WRITE_COMMAND)
      tdest_reg <= 4'b0000;
    else if(curr_cmd_word == FMC150_WRITE_COMMAND)
      tdest_reg <= 4'b0001;
    else if(curr_cmd_word == DATA_WRITE_COMMAND)
         tdest_reg <= 4'b0010;
     else if(curr_cmd_word == FMC150_READ_COMMAND)
         tdest_reg <= 4'b0011;
     else if(curr_cmd_word == CHIRP_READ_COMMAND)
         tdest_reg <= 4'b0011;
   end
end


// now generate the TLAST output
always @(posedge axi_tclk)
begin
   if (axi_treset)
    tlast_reg <= 0;
   else if (gen_state == DATA &  cmd_axis_tvalid & cmd_axis_tready_int & cmd_axis_tlast)
      tlast_reg <= 1;
   else if (tready)
      tlast_reg <= 0;
end


// now generate the WR fifo TVALID output
always @(posedge axi_tclk)
begin
   if (axi_treset)
      tvalid_reg <= 0;
   //else if (gen_state == DATA & !adc_axis_tvalid_reg)
   //else if (gen_state == DATA & rx_axis_tvalid)
   else if (gen_state == DATA & cmd_axis_tvalid)
      tvalid_reg <= 1'b1;
//   else if(gen_state == NEXT_CMD & new_command & cmd_axis_tvalid)
  else if(gen_state == NEXT_CMD & new_command)
      tvalid_reg <= 1'b1;
   else if (tready)
      tvalid_reg <= 0;
end

// need to generate the ready output

always @(posedge axi_tclk)
begin
   if (axi_treset) begin
      cmd_axis_tready_int <= 0;
   end
   else begin
    if (next_gen_state == DATA & tready)
         cmd_axis_tready_int <= 1;
   //else if(gen_state == NEXT_CMD & (!new_command | tready))
   else if(gen_state == NEXT_CMD & (!new_command))
        cmd_axis_tready_int <= 1;
    else
        cmd_axis_tready_int <= 0;
   end
end


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

assign cmd_axis_tready = cmd_axis_tready_int;


endmodule
