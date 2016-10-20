`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 04:32:51 PM
// Design Name:
// Module Name: wavegen_sim_tb
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


module wavegen_sim_tb;

localparam FMC_TCLK_PERIOD          = 5000;         // 200 MHz
localparam RESET_PERIOD = 20000; //in pSec

localparam CTRL_WORD_SEL_CHIRP = 32'h00000010;
localparam CTRL_WORD_SEL_AWG = 32'h00000310;

reg fmc_tresetn_i;
reg fmc_tclk_i;
reg fmc_tclk_fast_i;
wire                   fmc_tclk;
wire                fmc_tclk_fast;
wire                   fmc_tresetn;

wire clk;
wire reset;

wire tx_stb = 1'b1;
wire rx_stb = 1'b1;
wire [31:0] tx;
wire [31:0] rx;

// data from ADC Data fifo
wire       [31:0]                    wfin_axis_tdata;
wire                                 wfin_axis_tvalid;
wire                                 wfin_axis_tlast;
wire       [3:0]                    wfin_axis_tkeep;
wire                                wfin_axis_tready;


wire                  awg_data_valid;
wire                  awg_data_last;
wire [15:0]           awg_out_i;
wire [15:0]           awg_out_q;
wire [31:0]           awg_data_len;

wire [31:0] 		 num_adc_samples;

wire set_stb;
wire [7:0] set_addr;
wire [31:0] set_data;

reg set_stb_r;
reg [7:0] set_addr_r;
reg [31:0] set_data_r;
reg stb_count;
reg [31:0] rx_counter;
reg [63:0] vita_counter;



reg       [31:0]                    wfin_axis_tdata_reg;
reg                                 wfin_axis_tvalid_reg;
reg                                 wfin_axis_tlast_reg;
reg       [3:0]                    wfin_axis_tkeep_reg;

reg [7:0]               counter = 'b0;
reg                     wf_written = 0;

reg [31:0] wfrm_ind = 'b0;
reg [31:0] wfrm_len = 'd1004;
reg [31:0] wfrm_id = 'b0;
reg [31:0] wfrm_placeholder= 'b0;
reg [31:0] wfrm_cmd = 32'h57574441;

reg [1:0] wfrm_counter;
reg [3:0] reg_counter;

reg [10:0] chirp_count;



  wire awg_ready;
  wire awg_done;
  wire awg_active;
  wire awg_init;
  wire awg_enable;
  wire adc_enable;
  wire adc_run;



reg [31:0] awg_control_word_r = CTRL_WORD_SEL_CHIRP;
wire [31:0] awg_control_word;

initial
begin
      fmc_tclk_i = 1'b0;
      fmc_tclk_fast_i = 1'b1;
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

always
  begin
      fmc_tclk_fast_i = #(FMC_TCLK_PERIOD/4.0) ~fmc_tclk_fast_i;
end

assign fmc_tresetn = fmc_tresetn_i;
assign fmc_tclk = fmc_tclk_i;
assign fmc_tclk_fast = fmc_tclk_fast_i;

assign clk = fmc_tclk;
assign reset = ~fmc_tresetn;

initial begin
      repeat(4096)@(posedge fmc_tclk_i); // wait for reset
      $finish;
end

always @(posedge fmc_tclk) begin
    if (!fmc_tresetn) begin
        wfin_axis_tdata_reg <= 'b0;
        wfin_axis_tvalid_reg <= 0;
        wfin_axis_tlast_reg <= 0;
        wfin_axis_tkeep_reg <= 'b0;
        counter <= 0;

        wfrm_counter <= 0;
        reg_counter <= 0;

        awg_control_word_r <= CTRL_WORD_SEL_CHIRP;
        set_stb_r <= 0;
        set_addr_r <= 'b0;
        set_data_r <= 32'h00000004;
        stb_count <= 0;
        rx_counter <= 0;
        vita_counter <= 64'h10;
    end
    else begin

        wfin_axis_tvalid_reg <= 1'b1;
        wfin_axis_tkeep_reg <= 4'hf;

        rx_counter <= rx_counter + 1'b1;
        vita_counter <= vita_counter + 2'b10;

        if (counter == 0) begin
        	stb_count <= 1'b1;
        	if (reg_counter == 4'b0000) begin
        	    set_stb_r <= 1'b1;
                set_addr_r <= 'b0;
        		set_data_r <= 32'h00000001;
        	end else if (reg_counter == 4'b1000) begin
        	    set_stb_r <= 1'b1;
                set_addr_r <= 'b0;
        		set_data_r <= 32'h00000005;
        	end
        end else if ((counter == 8'b1) & (stb_count == 1'b1))begin
            stb_count <= 0;
            if (reg_counter == 4'b0000) begin
        		set_data_r <= 32'h0000000f;
        		set_stb_r <= 1'b1;
                set_addr_r <= 'd6;
        	end else if (reg_counter == 4'b1000) begin
        		set_data_r <= 32'h00000005;
        		 set_stb_r <= 1'b1;
                set_addr_r <= 'd6;
            end
        end else begin
            set_stb_r <= 1'b0;
        end

        if (awg_done) begin
            if (awg_control_word_r == CTRL_WORD_SEL_AWG)
                awg_control_word_r <= CTRL_WORD_SEL_CHIRP;
            else
                awg_control_word_r <= CTRL_WORD_SEL_AWG;
        end

        if (&counter) begin
           wfin_axis_tlast_reg <= 1'b1;
           wfrm_counter <= wfrm_counter+1'b1;
           reg_counter <= reg_counter+1'b1;
           if(&wfrm_counter) begin
             wfrm_ind <= 'b0;
             wfrm_id <= wfrm_id + 1'b1;
           end else
             wfrm_ind <= wfrm_ind + 1'b1;

        end else if (wfin_axis_tready) begin
            wfin_axis_tlast_reg <= 1'b0;
        end

        if (counter == 0) begin
          wfin_axis_tdata_reg <= wfrm_cmd;
          counter <= counter + 1'b1;
        end
        else if  (wfin_axis_tvalid_reg & wfin_axis_tready) begin
          counter <= counter + 1'b1;
          if (counter == 1)
             wfin_axis_tdata_reg <=wfrm_id;
          else if (counter == 2)
             wfin_axis_tdata_reg <=wfrm_ind;
          else if (counter == 3)
             wfin_axis_tdata_reg <=wfrm_len;
          else if (counter == 4)
             wfin_axis_tdata_reg <=wfrm_placeholder;
          else
           wfin_axis_tdata_reg <= counter;
        end
    end
end

wavegen_block #(
	.SR_CH_COUNTER_ADDR(0),
    .SR_CH_TUNING_COEF_ADDR(1),
    .SR_CH_FREQ_OFFSET_ADDR(2)
	)
u_wavegen_block (
    .clk(fmc_tclk),
    .rst(~fmc_tresetn),

    .awg_out_i(awg_out_i),
    .awg_out_q(awg_out_q),
    .awg_data_valid(awg_data_valid),
    .awg_data_last(awg_data_last),
    .awg_data_len(awg_data_len),

    .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),

    .wr_axis_tdata(wfin_axis_tdata),
    .wr_axis_tvalid(wfin_axis_tvalid),
    .wr_axis_tlast(wfin_axis_tlast),
    .wr_axis_tuser('b0),
    .wr_axis_tkeep(wfin_axis_tkeep),
    .wr_axis_tdest('b0),
    .wr_axis_tid('b0),
    .wr_axis_tready(wfin_axis_tready),

    .awg_control_word(awg_control_word),


    .awg_ready (awg_ready),
    .awg_done (awg_done),
    .awg_active (awg_active),
    .awg_init  (awg_init),
    .awg_enable  (awg_enable),
    .adc_enable   (adc_enable)
);

  localparam CHIRP_CLK_FREQ = 200000000;    // Hz
  localparam ADC_SAMPLE_COUNT_INIT = 32'h00000003;
  localparam CHIRP_PRF_INT_COUNT_INIT = 32'h00000000;
  localparam CHIRP_PRF_FRAC_COUNT_INIT = 32'h000001ff;

  radar_pulse_controller #(
      .CLK_FREQ (CHIRP_CLK_FREQ),
      .ADC_SAMPLE_COUNT_INIT(ADC_SAMPLE_COUNT_INIT),
      .CHIRP_PRF_INT_COUNT_INIT(CHIRP_PRF_INT_COUNT_INIT),
      .CHIRP_PRF_FRAC_COUNT_INIT(CHIRP_PRF_FRAC_COUNT_INIT),

      .SR_PRF_INT_ADDR(4),
      .SR_PRF_FRAC_ADDR(5),
      .SR_ADC_SAMPLE_ADDR(6)
  )
u_radar_pulse_controller (
	.clk(fmc_tclk),
	.reset(~fmc_tresetn),
	.set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
	.num_adc_samples (num_adc_samples),
    .awg_data_valid(awg_data_valid),

    .awg_ready (awg_ready),
    .awg_done (awg_done),
    .awg_active (awg_active),
    .awg_init  (awg_init),
    .awg_enable  (awg_enable),
    .adc_enable   (adc_enable),
    .adc_run (adc_run)
);

wire run_awg;
wire [31:0] sample_awg;
wire loopback = 1'b0;

assign run_awg = ~(tx_stb & ~awg_data_valid);
assign sample_awg = {awg_out_i,awg_out_q};

 /********************************************************
 ** TX Chain
 ********************************************************/
 wire [31:0] tx_idle = 0;

 wire [31:0] sample_tx;
 wire [63:0] txresp_tdata;
 wire [127:0] txresp_tuser;
 wire txresp_tlast, txresp_tvalid, txresp_tready;

assign rx = rx_counter;
assign tx = run_awg ? sample_awg : tx_idle;

assign txresp_tdata = 'b0;
assign txresp_tuser = 'b0;
assign txresp_tlast = 0;
assign txresp_tvalid = 0;

 /********************************************************
 ** RX Chain
 ********************************************************/
 wire [31:0] sample_rx     = loopback ? tx     : rx;     // Digital Loopback TX -> RX
 wire        sample_rx_stb = loopback ? tx_stb : rx_stb;

 wire [63:0] rxresp_tdata;
 wire [127:0] rxresp_tuser;
 wire rxresp_tlast, rxresp_tvalid, rxresp_tready;

 wire [31:0] rx_tdata;
 wire rx_tlast;
 wire rx_tvalid;
 wire [127:0] rx_tuser;
 wire rx_tready;

 wire run_rx;
 wire clear_tx = 0;
 wire clear_rx = 0;
 wire [15:0] src_sid = 16'h0;          // Source stream ID of this block
 wire [15:0] dst_sid = 16'h1;             // Destination stream ID destination of downstream block
 wire [15:0] rx_resp_dst_sid = 16'h2;     // Destination stream ID for TX errors / response packets (i.e. host PC)
 wire [15:0] tx_resp_dst_sid = 16'h3;   // Destination stream ID for TX errors / response packets (i.e. host PC)

 wire [31:0] rx_command_i;
 wire [63:0] rx_time_i;
 wire rx_store_command;

 wire [63:0] vita_time;
 assign vita_time = vita_counter;

localparam ADC_AXI_DATA_WIDTH = 512;//64;
localparam ADC_AXI_TID_WIDTH = 1;
localparam ADC_AXI_TDEST_WIDTH = 1;
localparam ADC_AXI_TUSER_WIDTH = 1;
localparam ADC_AXI_STREAM_ID = 1'b0;
localparam ADC_AXI_STREAM_DEST = 1'b1;

localparam [7:0] SR_TX_CTRL_ERROR_POLICY = 144;
localparam [7:0] SR_RX_CTRL_COMMAND      = 152;
localparam [7:0] SR_RX_CTRL_TIME_HI      = 153;
localparam [7:0] SR_RX_CTRL_TIME_LO      = 154;
localparam [7:0] SR_RX_CTRL_HALT         = 155;
localparam [7:0] SR_RX_CTRL_MAXLEN       = 156;
localparam [7:0] SR_RX_CTRL_CLEAR_CMDS   = 157;
localparam [7:0] SR_RX_CTRL_OUTPUT_FORMAT = 158;

wire [ADC_AXI_DATA_WIDTH-1:0]     axis_adc_tdata;
wire axis_adc_tvalid;
wire axis_adc_tlast;
wire [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tkeep;
wire [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tstrb;
wire [ADC_AXI_TID_WIDTH-1:0] axis_adc_tid;
wire [ADC_AXI_TDEST_WIDTH-1:0] axis_adc_tdest;
wire [ADC_AXI_TUSER_WIDTH-1:0] axis_adc_tuser;
wire axis_adc_tready;

wire [63:0] iq_tdata;
wire iq_tvalid;
wire iq_tlast;
wire iq_tready;
wire iq_first;

assign iq_tready = 1'b1;
assign axis_adc_tready = 1'b1;

radar_sample_synchronizer #(
    .ADC_AXI_DATA_WIDTH(ADC_AXI_DATA_WIDTH),
    .ADC_AXI_TID_WIDTH(ADC_AXI_TID_WIDTH),
    .ADC_AXI_TDEST_WIDTH(ADC_AXI_TDEST_WIDTH),
    .ADC_AXI_TUSER_WIDTH(ADC_AXI_TUSER_WIDTH),
    .ADC_AXI_STREAM_ID(ADC_AXI_STREAM_ID),
    .ADC_AXI_STREAM_DEST(ADC_AXI_STREAM_DEST)
)
radar_sample_synchronizer (
    .clk (clk), // AXI input clock
    .reset (reset), // Active low AXI reset signal

    // --TX and RX Data Out Signals
   .iq_tdata(iq_tdata),
   .iq_tvalid(iq_tvalid),
   .iq_tlast(iq_tlast),
   .iq_tready(iq_tready),
   .iq_first(iq_first),
   .counter_id(),

   .dac_data_iq(tx),
   .adc_data_iq(sample_rx),
   .adc_data_valid(sample_rx_stb),


   .axis_adc_tdata                      (axis_adc_tdata),
   .axis_adc_tvalid                     (axis_adc_tvalid),
   .axis_adc_tlast                      (axis_adc_tlast),
   .axis_adc_tkeep                      (axis_adc_tkeep),
   .axis_adc_tid                        (axis_adc_tid),
   .axis_adc_tdest                      (axis_adc_tdest),
   .axis_adc_tuser                      (axis_adc_tuser),
   .axis_adc_tready                     (axis_adc_tready),
   .axis_adc_tstrb                      (axis_adc_tstrb),

   .awg_control_word(awg_control_word),
   .awg_init(awg_init),
   .awg_enable(awg_enable),
   .adc_enable(adc_enable),
   .adc_run(adc_run)
 );
 rx_command_gen rx_command_gen(
       .clk(clk), .reset(reset),
       .command_i(rx_command_i), .time_i(rx_time_i), .store_command(rx_store_command),
       .awg_data_len(awg_data_len),
       .num_adc_samples (num_adc_samples),
       .vita_time(vita_time),
       .awg_init (awg_init),
       .adc_run(adc_run),
       .adc_enable (adc_enable));


 radar_rx_controller#(
   .SR_RX_CTRL_COMMAND(SR_RX_CTRL_COMMAND),
   .SR_RX_CTRL_TIME_HI(SR_RX_CTRL_TIME_HI),
   .SR_RX_CTRL_TIME_LO(SR_RX_CTRL_TIME_LO),
   .SR_RX_CTRL_HALT(SR_RX_CTRL_HALT),
   .SR_RX_CTRL_MAXLEN(SR_RX_CTRL_MAXLEN),
   .SR_RX_CTRL_CLEAR_CMDS(SR_RX_CTRL_CLEAR_CMDS),
   .SR_RX_CTRL_OUTPUT_FORMAT(SR_RX_CTRL_OUTPUT_FORMAT)
 )
 radar_rx_controller (
   .clk(clk), .reset(reset), .clear(clear_rx),
   .vita_time(vita_time), .sid({src_sid, dst_sid}), .resp_sid({src_sid, rx_resp_dst_sid}),
   .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
   .command_i(rx_command_i), .time_i(rx_time_i), .store_command(rx_store_command),
   .rx_tdata(rx_tdata), .rx_tlast(rx_tlast), .rx_tvalid(rx_tvalid), .rx_tready(rx_tready), .rx_tuser(rx_tuser),
   .resp_tdata(rxresp_tdata), .resp_tlast(rxresp_tlast), .resp_tvalid(rxresp_tvalid), .resp_tready(rxresp_tready), .resp_tuser(rxresp_tuser),
   .strobe(sample_rx_stb), .sample(sample_rx), .run(run_rx));

assign rx_tready = 1'b1;
assign rxresp_tready = 1'b1;

assign wfin_axis_tdata = wfin_axis_tdata_reg;
assign wfin_axis_tvalid = wfin_axis_tvalid_reg;
assign wfin_axis_tlast = wfin_axis_tlast_reg;
assign wfin_axis_tkeep = wfin_axis_tkeep_reg;

assign awg_control_word = awg_control_word_r;

assign set_stb = set_stb_r;
assign set_data = set_data_r;
assign set_addr = set_addr_r;


endmodule
