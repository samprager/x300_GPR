`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 03:15:50 PM
// Design Name:
// Module Name: waveform_stream
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


module waveform_stream # (
    parameter WRITE_BEFORE_READ = 1'b1
)(
    input aresetn,
    input clk_in1,
    input [127:0] waveform_parameters,
    input init_wf_write,
    output wf_write_ready,
    output wf_read_ready,

    output [31:0] wfout_size,
    // data from ADC Data fifo
    input       [31:0]                    wfin_axis_tdata,
    input                                 wfin_axis_tvalid,
    input                                 wfin_axis_tlast,
    input       [3:0]                     wfin_axis_tkeep,
    output                                wfin_axis_tready,

    // data from ADC Data fifo
    output       [31:0]                    wfout_axis_tdata,
    output                                 wfout_axis_tvalid,
    output                                 wfout_axis_tlast,
    output       [3:0]                     wfout_axis_tkeep,
    input                                wfout_axis_tready

);
localparam     IDLE        = 3'b000,
               WR_CMD        = 3'b001,
               WR_DATA    = 3'b010,
               RD_CMD        = 3'b011,
               RD_DATA    = 3'b100;

localparam FIXED = 1'b0;
localparam INCR = 1'b1;

localparam NUM_WRITE = 'd1004;//'h80;            // 32 bit words to write
localparam NUM_BTT = 4*NUM_WRITE;       // bytes to transfer

wire [7:0]m_axis_mm2s_sts_tdata;
wire [0:0]m_axis_mm2s_sts_tkeep;
wire m_axis_mm2s_sts_tlast;
wire m_axis_mm2s_sts_tready;
wire m_axis_mm2s_sts_tvalid;
wire [31:0]m_axis_mm2s_tdata;
wire [3:0]m_axis_mm2s_tkeep;
wire m_axis_mm2s_tlast;
wire m_axis_mm2s_tready;
wire m_axis_mm2s_tvalid;
wire [7:0]m_axis_s2mm_sts_tdata;
wire [0:0]m_axis_s2mm_sts_tkeep;
wire m_axis_s2mm_sts_tlast;
wire m_axis_s2mm_sts_tready;
wire m_axis_s2mm_sts_tvalid;
wire [71:0]s_axis_mm2s_cmd_tdata;
wire s_axis_mm2s_cmd_tready;
wire s_axis_mm2s_cmd_tvalid;
wire [71:0]s_axis_s2mm_cmd_tdata;
wire s_axis_s2mm_cmd_tready;
wire s_axis_s2mm_cmd_tvalid;
wire [31:0]s_axis_s2mm_tdata;
wire [3:0]s_axis_s2mm_tkeep;
wire s_axis_s2mm_tlast;
wire s_axis_s2mm_tready;
wire s_axis_s2mm_tvalid;
wire mm2s_err;
wire s2mm_err;

reg m_axis_mm2s_sts_tready_reg;
reg m_axis_mm2s_tready_reg;
reg m_axis_s2mm_sts_tready_reg;

reg [71:0]s_axis_mm2s_cmd_tdata_reg;
reg s_axis_mm2s_cmd_tvalid_reg;
reg [71:0]s_axis_s2mm_cmd_tdata_reg; //{RSVD(4b),TAG(4b),SADDR(32b),DRR(1b),EOF(1b),DSA(6b),Type(1b),BTT(23b)}
reg s_axis_s2mm_cmd_tvalid_reg;

//reg [31:0]s_axis_s2mm_tdata_reg;
//reg [3:0]s_axis_s2mm_tkeep_reg;
//reg s_axis_s2mm_tlast_reg;
//reg s_axis_s2mm_tvalid_reg;

reg wf_write_ready_reg;
reg wf_read_ready_reg;
reg [31:0] wf_new_size;  // bytes to transfer
reg [31:0] wf_cur_size;  // bytes to transfer

reg         [2:0]          next_gen_state;
reg         [2:0]          gen_state;

reg [31:0] rd_addr = 32'hC0000000;
reg [31:0] wr_addr = 32'hC0000000;
reg [31:0] wr_counter;
reg [31:0] rd_counter;
reg [2:0] wr_cmd_counter;
reg [1:0] rd_cmd_counter;

reg wf_written = 1'b0;


// register that tracks whether or not we have written to the bram...
always @(posedge clk_in1) begin
    if(!aresetn)
        wf_written <= 0;
    else if ((gen_state == WR_CMD) | (!WRITE_BEFORE_READ))
        wf_written <= 1;
    else
        wf_written <= wf_written;
end


always @(posedge clk_in1) begin
    if(!aresetn)
        wf_write_ready_reg <= 0;
    else if (gen_state == IDLE)
        wf_write_ready_reg <= 1;
   else
        wf_write_ready_reg <= 0;
end

always @(posedge clk_in1) begin
    if(!aresetn)
        wf_read_ready_reg <= 0;
    else if (gen_state == IDLE)
        wf_read_ready_reg <= 1;
   else
        wf_read_ready_reg <= 0;
end

always @(posedge clk_in1) begin
    if(!aresetn)
        wf_new_size <= 0;
    else if (gen_state == IDLE & wf_write_ready_reg & init_wf_write)
        wf_new_size <= waveform_parameters[31:0];
end

always @(posedge clk_in1) begin
    if(!aresetn)
        wf_cur_size <= 0;
    else if (gen_state == WR_CMD & (s_axis_s2mm_cmd_tvalid_reg & s_axis_s2mm_cmd_tready))
        wf_cur_size <= wf_new_size;
end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        m_axis_mm2s_sts_tready_reg <= 0;
        m_axis_s2mm_sts_tready_reg <= 0;
    end
    else begin
        m_axis_mm2s_sts_tready_reg <= 1;
        m_axis_s2mm_sts_tready_reg <= 1;
    end
end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        wr_cmd_counter <= 0;
    end
    else if (gen_state == WR_CMD & ((s_axis_s2mm_cmd_tvalid_reg & s_axis_s2mm_cmd_tready) | (|wr_cmd_counter))) begin
        wr_cmd_counter <= wr_cmd_counter+1;
    end
    else begin
        wr_cmd_counter <= 0;
    end
end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        s_axis_s2mm_cmd_tvalid_reg <= 0;
    end
    else if (gen_state == WR_CMD & !(s_axis_s2mm_cmd_tvalid_reg & s_axis_s2mm_cmd_tready) & (wr_cmd_counter == 0)) begin
        s_axis_s2mm_cmd_tvalid_reg <= 1;
    end
    else begin
        s_axis_s2mm_cmd_tvalid_reg <= 0;
    end
end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        s_axis_s2mm_cmd_tdata_reg <= 0;
    end
    else if (gen_state == WR_CMD & (wr_cmd_counter == 0)) begin
        s_axis_s2mm_cmd_tdata_reg[67:64] <= 4'hE;   //test tag
        s_axis_s2mm_cmd_tdata_reg[63:32] <= wr_addr;
         s_axis_s2mm_cmd_tdata_reg[30] <= 1'b1;    // eof
        s_axis_s2mm_cmd_tdata_reg[23] <= INCR;
        s_axis_s2mm_cmd_tdata_reg[22:0] <= {wf_new_size[20:0],2'b0};  // shift left two places for size in bytes
    end
end
always @(posedge clk_in1)begin
    if(!aresetn) begin
        rd_cmd_counter <= 0;
    end
    else if (gen_state == RD_CMD & ((s_axis_mm2s_cmd_tvalid_reg & s_axis_mm2s_cmd_tready) | (|rd_cmd_counter))) begin
        rd_cmd_counter <= rd_cmd_counter+1;
    end
    else begin
        rd_cmd_counter <= 0;
    end
end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        s_axis_mm2s_cmd_tvalid_reg <= 0;
    end
    else if ((gen_state == RD_CMD)&!(s_axis_mm2s_cmd_tvalid_reg & s_axis_mm2s_cmd_tready)&(rd_cmd_counter == 0))begin
        s_axis_mm2s_cmd_tvalid_reg <= 1;
    end
    else begin
        s_axis_mm2s_cmd_tvalid_reg <= 0;
    end
end
always @(posedge clk_in1)begin
    if(!aresetn) begin
        s_axis_mm2s_cmd_tdata_reg <= 0;
    end
    else if (gen_state == RD_CMD) begin
        s_axis_mm2s_cmd_tdata_reg[67:64] <= 4'hE;   //test tag
        s_axis_mm2s_cmd_tdata_reg[63:32] <= rd_addr;
        s_axis_mm2s_cmd_tdata_reg[30] <= 1'b1;      // eof
        s_axis_mm2s_cmd_tdata_reg[23] <= INCR;
        s_axis_mm2s_cmd_tdata_reg[22:0] <= {wf_cur_size[20:0],2'b0};
    end
end

//always @(posedge clk_in1)begin
//    if(!aresetn) begin
//        s_axis_s2mm_tvalid_reg <= 0;
//    end
//    else if (gen_state == WR_DATA) begin
//        s_axis_s2mm_tvalid_reg <= 1;
//    end
//    else if(s_axis_s2mm_tready) begin
//       s_axis_s2mm_tvalid_reg <= 0;
//    end
//end

//always @(posedge clk_in1)begin
//    if(!aresetn) begin
//        s_axis_s2mm_tkeep_reg <= 0;
//    end
//    else if (gen_state == WR_DATA) begin
//        s_axis_s2mm_tkeep_reg <= 4'hf;
//    end
//    else begin
//       s_axis_s2mm_tkeep_reg <= 0;
//    end
//end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        wr_counter <= 0;
    end
    else if(gen_state == WR_DATA & s_axis_s2mm_tready & s_axis_s2mm_tvalid) begin
        wr_counter <= wr_counter + 1'b1;
    end
    else if(gen_state != WR_DATA) begin
        wr_counter <= 1'b0;
    end
end


//always @(posedge clk_in1)begin
//    if(!aresetn) begin
//        s_axis_s2mm_tlast_reg <= 0;
//    end
//    else if(gen_state == WR_DATA & (wr_counter == (wf_cur_size-1)) & s_axis_s2mm_tready) begin
//        s_axis_s2mm_tlast_reg <= 1;
//    end
//    else if(s_axis_s2mm_tready) begin
//        s_axis_s2mm_tlast_reg <= 0;
//    end
//end

always @(posedge clk_in1)begin
    if(!aresetn) begin
        rd_counter <= 0;
    end
    else if(gen_state == RD_DATA & m_axis_mm2s_tready_reg & m_axis_mm2s_tvalid) begin
        rd_counter <= rd_counter + 1'b1;
    end
    else if(gen_state != RD_DATA) begin
        rd_counter <= 0;
    end
end
always @(posedge clk_in1)begin
    if(!aresetn) begin
        m_axis_mm2s_tready_reg <= 0;
    end
    else if ((gen_state == RD_DATA)| (gen_state == RD_CMD & s_axis_mm2s_cmd_tvalid_reg & s_axis_mm2s_cmd_tready)) begin
        m_axis_mm2s_tready_reg <= 1;
    end
    else begin
        m_axis_mm2s_tready_reg <= 0;
    end
end
always @(gen_state or wr_counter or rd_counter  or s_axis_mm2s_cmd_tvalid_reg or s_axis_mm2s_cmd_tready or s_axis_s2mm_cmd_tvalid_reg or s_axis_s2mm_cmd_tready or m_axis_mm2s_tlast or wfout_axis_tready or wf_write_ready_reg or init_wf_write or wf_read_ready or wr_cmd_counter or rd_cmd_counter)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
        if (init_wf_write & wf_write_ready_reg) begin
            next_gen_state = WR_CMD;
        end
        else if (wfout_axis_tready & wf_read_ready) begin
            next_gen_state = RD_CMD;
         end
      end
      WR_CMD : begin
        if (&wr_cmd_counter)
            next_gen_state = WR_DATA;
      end
      WR_DATA : begin
         if (wr_counter == wf_cur_size)
            next_gen_state = IDLE;
      end
      RD_CMD : begin
         if (s_axis_mm2s_cmd_tvalid_reg & s_axis_mm2s_cmd_tready)
            next_gen_state = RD_DATA;
      end
      RD_DATA : begin
        if (wfout_axis_tready & m_axis_mm2s_tlast)
         next_gen_state = IDLE;
      end

      default : begin
         next_gen_state = IDLE;
      end
   endcase
end

always @(posedge clk_in1)
begin
   if (!aresetn) begin
      gen_state <= IDLE;
   end
   else begin
      gen_state <= next_gen_state;
   end
end

assign wf_read_ready = wf_read_ready_reg & wf_written;
assign wf_write_ready = wf_write_ready_reg;
assign wfout_size = wf_cur_size;

assign s_axis_s2mm_tvalid = (gen_state == WR_DATA)? wfin_axis_tvalid : 0;
assign s_axis_s2mm_tdata = wfin_axis_tdata;
assign s_axis_s2mm_tkeep = wfin_axis_tkeep;
assign s_axis_s2mm_tlast = wfin_axis_tlast;
assign wfin_axis_tready = (gen_state == WR_DATA)? s_axis_s2mm_tready : 0;

assign wfout_axis_tvalid = (gen_state == RD_DATA)? m_axis_mm2s_tvalid : 0;
assign wfout_axis_tdata = m_axis_mm2s_tdata;
assign wfout_axis_tkeep = m_axis_mm2s_tkeep;
assign wfout_axis_tlast = m_axis_mm2s_tlast;
assign m_axis_mm2s_tready = (gen_state == RD_DATA)? wfout_axis_tready : 0;


//assign m_axis_mm2s_tready = m_axis_mm2s_tready_reg;
assign m_axis_mm2s_sts_tready =  m_axis_mm2s_sts_tready_reg;
assign m_axis_s2mm_sts_tready = m_axis_s2mm_sts_tready_reg;

assign s_axis_mm2s_cmd_tdata = s_axis_mm2s_cmd_tdata_reg;
assign s_axis_mm2s_cmd_tvalid = s_axis_mm2s_cmd_tvalid_reg;
assign s_axis_s2mm_cmd_tdata = s_axis_s2mm_cmd_tdata_reg; //{RSVD(4b),TAG(4b),SADDR(32b),DRR(1b),EOF(1b),DSA(6b),Type(1b),BTT(23b)}
assign s_axis_s2mm_cmd_tvalid = s_axis_s2mm_cmd_tvalid_reg;

// assign s_axis_s2mm_tdata = s_axis_s2mm_tdata_reg;
// assign s_axis_s2mm_tkeep = s_axis_s2mm_tkeep_reg;
// assign s_axis_s2mm_tlast = s_axis_s2mm_tlast_reg;
// assign s_axis_s2mm_tvalid = s_axis_s2mm_tvalid_reg;

 //   design_1 design_1_i (
 bram_stream_wrapper bram_stream_wrapper_inst(
         .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),
         .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),
         .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),
         .m_axis_mm2s_sts_tready(m_axis_mm2s_sts_tready),
         .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),
         .m_axis_mm2s_tdata(m_axis_mm2s_tdata),
         .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),
         .m_axis_mm2s_tlast(m_axis_mm2s_tlast),
         .m_axis_mm2s_tready(m_axis_mm2s_tready),
         .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),
         .m_axis_s2mm_sts_tdata(m_axis_s2mm_sts_tdata),
         .m_axis_s2mm_sts_tkeep(m_axis_s2mm_sts_tkeep),
         .m_axis_s2mm_sts_tlast(m_axis_s2mm_sts_tlast),
         .m_axis_s2mm_sts_tready(m_axis_s2mm_sts_tready),
         .m_axis_s2mm_sts_tvalid(m_axis_s2mm_sts_tvalid),
         .s_axis_mm2s_cmd_tdata(s_axis_mm2s_cmd_tdata),
         .s_axis_mm2s_cmd_tready(s_axis_mm2s_cmd_tready),
         .s_axis_mm2s_cmd_tvalid(s_axis_mm2s_cmd_tvalid),
         .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata),
         .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready),
         .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid),
         .s_axis_s2mm_tdata(s_axis_s2mm_tdata),
         .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),
         .s_axis_s2mm_tlast(s_axis_s2mm_tlast),
         .s_axis_s2mm_tready(s_axis_s2mm_tready),
         .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),
         .aresetn(aresetn),
         .clk_in1(clk_in1),
         .mm2s_err(mm2s_err),
         .s2mm_err(s2mm_err)
     );


endmodule
