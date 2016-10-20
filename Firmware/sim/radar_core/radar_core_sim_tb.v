`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 07/14/2016 04:32:51 PM
// Design Name:
// Module Name: radar_core_sim_tb
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


module radar_core_sim_tb();
  /*********************************************
  ** User variables
  *********************************************/


  localparam CLK_PERIOD          = 5000;         // 200 MHz
  localparam RESET_PERIOD = 20000; //in pSec

  localparam [7:0] SR_CH_COUNTER_ADDR = 64;
  localparam [7:0] SR_CH_TUNING_COEF_ADDR = 65;
  localparam [7:0] SR_CH_FREQ_OFFSET_ADDR = 66;
  localparam [7:0] SR_AWG_CTRL_WORD_ADDR = 67;

  localparam [7:0] SR_PRF_INT_ADDR = 68;
  localparam [7:0] SR_PRF_FRAC_ADDR = 69;
  localparam [7:0] SR_ADC_SAMPLE_ADDR = 70;

  

  localparam CTRL_WORD_SEL_CHIRP = 32'h00000010;
  localparam CTRL_WORD_SEL_AWG = 32'h00000310;
  localparam NUM_CHANNELS = 1;


  reg resetn_i;
  reg clk_i;
  wire                   clk;
  wire                   resetn;

  wire reset;
  wire rst;
  wire bus_clk, bus_rst, radio_clk, radio_rst;

  // wire [31:0]                 m_axis_data_tdata[0:NUM_CHANNELS-1];
  // wire [127:0]                m_axis_data_tuser[0:NUM_CHANNELS-1];
  // wire [NUM_CHANNELS-1:0]     m_axis_data_tlast;
  // wire [NUM_CHANNELS-1:0]     m_axis_data_tvalid;
  // wire [NUM_CHANNELS-1:0]     m_axis_data_tready;

  // wire [31:0]                 s_axis_data_tdata[0:NUM_CHANNELS-1];
  // wire [127:0]                s_axis_data_tuser[0:NUM_CHANNELS-1];
  // wire [NUM_CHANNELS-1:0]     s_axis_data_tlast;
  // wire [NUM_CHANNELS-1:0]     s_axis_data_tvalid;
  // wire [NUM_CHANNELS-1:0]     s_axis_data_tready;
    wire [31:0]                 m_axis_data_tdata;
  wire [127:0]                m_axis_data_tuser;
  wire      m_axis_data_tlast;
  wire      m_axis_data_tvalid;
  wire      m_axis_data_tready;

  wire [31:0]                 s_axis_data_tdata;
  wire [127:0]                s_axis_data_tuser;
  wire     s_axis_data_tlast;
  wire     s_axis_data_tvalid;
  wire     s_axis_data_tready;


  wire set_stb;
  wire [7:0] set_addr;
  wire [31:0] set_data;

  reg set_stb_r;
  reg [7:0] set_addr_r;
  reg [31:0] set_data_r;
  reg [2:0] stb_count;
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



  reg [31:0] awg_control_word_r = CTRL_WORD_SEL_CHIRP;
  wire [31:0] awg_control_word;

  /*********************************************
  ** DUT
  *********************************************/

  // Daughter board I/O
  wire [31:0] leds;
  wire [31:0] fp_gpio_r_in, fp_gpio_r_out, fp_gpio_r_ddr;
  wire [31:0] db_gpio_in, db_gpio_out, db_gpio_ddr;
  wire [31:0] misc_outs;
  reg  [31:0] misc_ins;
  wire [7:0]  sen;
  wire        sclk, mosi, miso;

  wire clear_tx = 0;
  wire clear_rx = 0;
  wire [15:0] src_sid = 16'h0;          // Source stream ID of this block
  wire [15:0] dst_sid = 16'h1;             // Destination stream ID destination of downstream block
  wire [15:0] rx_resp_dst_sid = 16'h2;     // Destination stream ID for TX errors / response packets (i.e. host PC)
  wire [15:0] tx_resp_dst_sid = 16'h3;   // Destination stream ID for TX errors / response packets (i.e. host PC)

  wire rb_stb;
  wire [7:0] rb_addr = 'b0;
  wire [63:0] rb_data;
  

  wire [63:0] vita_time;
  wire [63:0] vita_time_lastpps;
  assign vita_time = vita_counter;
  assign vita_time_lastpps = vita_counter;


  wire [NUM_CHANNELS*64-1:0]  resp_tdata;
  wire [NUM_CHANNELS-1:0]     resp_tlast, resp_tvalid, resp_tready;

  localparam BASE = 128;
  localparam RX_DELAY = 8;

  wire tx_stb = 1'b1;
  wire rx_stb = 1'b1;
  wire [31:0] tx;
  wire [31:0] rx;
  reg  [31:0] rx_shift_reg [RX_DELAY-1:0];
  integer i;

  initial
  begin
        clk_i = 1'b0;
  end

  initial begin
    resetn_i = 1'b0;
    #RESET_PERIOD
      resetn_i = 1'b1;
   end

  always
    begin
        clk_i = #(CLK_PERIOD/2.0) ~clk_i;
  end

  assign resetn = resetn_i;
  assign clk = clk_i;
  assign reset = ~resetn;
  assign rst = reset;
  assign bus_clk = clk;
  assign radio_clk = clk;
  assign bus_rst = rst;
  assign radio_rst = rst;

  initial begin
        repeat(4096)@(posedge clk_i); // wait for reset
        $finish;
  end



  always @(posedge clk) begin
      if (!resetn) begin
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

          for(i=0;i<RX_DELAY;i=i+1) begin
            rx_shift_reg[i] <= 'b0;
          end

      end
      else begin
          rx_shift_reg[0] <= tx;
          for(i=1;i<RX_DELAY;i=i+1) begin
            rx_shift_reg[i] <= rx_shift_reg[i-1];
          end
          wfin_axis_tvalid_reg <= 1'b1;
          wfin_axis_tkeep_reg <= 4'hf;

          rx_counter <= rx_counter + 1'b1;
          vita_counter <= vita_counter + 2'b10;

          if (counter == 0) begin
          	stb_count <= 3'b011;
          	if (reg_counter == 4'b0000) begin
                set_data_r <= 32'h000001ff;
                set_stb_r <= 1'b1;
                set_addr_r <= SR_PRF_FRAC_ADDR;
          	end else if (reg_counter == 4'b1000) begin
                set_data_r <= 32'h000000ff;
                set_stb_r <= 1'b1;
                set_addr_r <= SR_PRF_FRAC_ADDR;
          	end
          end else if ((counter == 8'b1) & (stb_count == 3'b011))begin
              stb_count <= stb_count -1'b1;
              if (reg_counter == 4'b0000) begin
          		set_data_r <= 32'h00000001;
          		set_stb_r <= 1'b1;
                set_addr_r <= SR_CH_COUNTER_ADDR;
          	end else if (reg_counter == 4'b1000) begin
          		set_data_r <= 32'h00000005;
          		 set_stb_r <= 1'b1;
                  set_addr_r <= SR_CH_COUNTER_ADDR;
              end
          end else if ((counter == 8'h02) & (stb_count == 3'b010))begin
              stb_count <= stb_count -1'b1;
              if (reg_counter == 4'b0000) begin
                  set_data_r <= 32'h0000000f;
                  set_stb_r <= 1'b1;
                  set_addr_r <= SR_ADC_SAMPLE_ADDR;
              end else if (reg_counter == 4'b1000) begin
                  set_data_r <= 32'h00000005;
                   set_stb_r <= 1'b1;
                  set_addr_r <= SR_ADC_SAMPLE_ADDR;
              end
          end else if ((counter == 8'h03) & (stb_count == 3'b001))begin
              stb_count <= stb_count -1'b1;
              if (reg_counter == 4'b0000) begin
                  set_data_r <= CTRL_WORD_SEL_AWG;
                  set_stb_r <= 1'b1;
                  set_addr_r <= SR_AWG_CTRL_WORD_ADDR;
              end else if (reg_counter == 4'b1000) begin
                  set_data_r <= CTRL_WORD_SEL_CHIRP;
                   set_stb_r <= 1'b1;
                  set_addr_r <= SR_AWG_CTRL_WORD_ADDR;
              end
          end else begin
              set_stb_r <= 1'b0;
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

          end else if (m_axis_data_tready) begin
              wfin_axis_tlast_reg <= 1'b0;
          end

          if (counter == 0) begin
            wfin_axis_tdata_reg <= wfrm_cmd;
            counter <= counter + 1'b1;
          end
          else if  (wfin_axis_tvalid_reg & m_axis_data_tready) begin
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

     radar_core #(
       .RADIO_NUM(0),
       .USE_SPI_CLK(0))
     radar_core (
       .clk(radio_clk), .reset(radio_rst),
       .clear_rx(clear_rx), .clear_tx(clear_tx),
       .src_sid(src_sid),
       .dst_sid(dst_sid),
       .rx_resp_dst_sid(rx_resp_dst_sid),
       .tx_resp_dst_sid(tx_resp_dst_sid),
       .rx(rx), .rx_stb(rx_stb),
       .tx(tx), .tx_stb(tx_stb),
       .vita_time(vita_time), .vita_time_lastpps(vita_time_lastpps),
       .pps(0),
       .misc_ins(0), .misc_outs(misc_outs),
       .fp_gpio_in(fp_gpio_r_in), .fp_gpio_out(fp_gpio_r_out), .fp_gpio_ddr(fp_gpio_r_ddr),
       .db_gpio_in(db_gpio_in), .db_gpio_out(db_gpio_out), .db_gpio_ddr(db_gpio_ddr),
       .leds(leds),
       .spi_clk(radio_clk), .spi_rst(radio_rst), .sen(sen), .sclk(sclk), .mosi(mosi), .miso(0),
       .set_stb(set_stb), .set_addr(set_addr), .set_data(set_data),
       .rb_stb(rb_stb), .rb_addr(rb_addr), .rb_data(rb_data),
       .tx_tdata(m_axis_data_tdata), .tx_tlast(m_axis_data_tlast), .tx_tvalid(m_axis_data_tvalid), .tx_tready(m_axis_data_tready), .tx_tuser(m_axis_data_tuser),
       .rx_tdata(s_axis_data_tdata), .rx_tlast(s_axis_data_tlast), .rx_tvalid(s_axis_data_tvalid), .rx_tready(s_axis_data_tready), .rx_tuser(s_axis_data_tuser),
       .resp_tdata(resp_tdata), .resp_tlast(resp_tlast), .resp_tvalid(resp_tvalid), .resp_tready(resp_tready));

     assign db_gpio_in = 'b0;
     assign fp_gpio_r_in = 'b0;
     assign rx_stb = 1'b1;
     assign tx_stb = 1'b1;
     
     assign set_stb = set_stb_r;
     assign set_addr = set_addr_r;
     assign set_data = set_data_r;

     assign rx = rx_shift_reg[RX_DELAY-1];

     assign s_axis_data_tready = 1'b1;
     assign m_axis_data_tdata = wfin_axis_tdata_reg;
     assign m_axis_data_tvalid = wfin_axis_tvalid_reg;
     assign m_axis_data_tlast = wfin_axis_tlast_reg;

     cvita_hdr_encoder cvita_hdr_encoder (
       .pkt_type(2'd0), .eob(1'b1), .has_time(1'b0),
       .seqnum(12'd0), .payload_length({wfrm_len[13:0],2'b00}), .dst_sid(dst_sid), .src_sid(src_sid),
       .vita_time(vita_time),
       .header(m_axis_data_tuser));



endmodule
