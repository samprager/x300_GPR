
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 06/22/2016 02:25:19 PM
// Design Name:
// Module Name: config_reg_map
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

//--------------DDS Chirp Generation Parameters-------------------
//-- period = 4.17 us, BW = 46.08 MHz
//-- 491.52 Mhz clock, 4096 samples, 16 bit phase accumulator (n = 16)
//-- ch_tuning_coef = 3      for BW = 46.08 MHz (2048 samples)
//-- ch_tuning_coef = 4      for BW = 61.44 MHz (2048 samples)
//-- ch_tuning_coef = 1.5    for BW = 46.08 MHz (4096 samples)
//-- ch_tuning_coef = 2      for BW = 61.44 MHz (4096 samples)
//-- Calculated Using:
//--    ch_tuning_coef = BW*(2^n)/(num_samples*fClock)
//-- Taken From:
//--    ch_tuning_coef = period*slope*(2^n)/(num_samples*fClock)
//-- Where:
//--    slope = BW/period
//--    num_samples = period*fclock
//--
//-- Note: Derived From:
//--    tuning_word = rect[t/period] t*slope*(2^n)/fclock
//-- And:
//--     t = sample_count*period/num_samples
//-- Therefore:
//--    tuning_word = sample_count*tuning_coeff
//-- Push the initial freq beyon baseband:
//  min_freq = freq_offset*fclock/2^n
//-------------------------------------------------------------------
`timescale 1 ps/1 ps


// -----------------------
// -- Module Definition --
// -----------------------

module config_reg_map # (
parameter REG_ADDR_WIDTH                            = 8,
parameter CORE_DATA_WIDTH                           = 32,
parameter CORE_BE_WIDTH                             = CORE_DATA_WIDTH/8,

parameter RX_WR_CMD_DWIDTH                         = 224,
parameter RX_RD_CMD_DWIDTH                         = 32,

parameter  CHIRP_CLK_FREQ                           = 245760000,    // Hz

parameter ADC_SAMPLE_COUNT_INIT = 32'h000001fe, // 510 samples
parameter CHIRP_PRF_INT_COUNT_INIT = 32'h00000000,
parameter CHIRP_PRF_FRAC_COUNT_INIT = 32'h1d4c0000,  // 2 sec
parameter CHIRP_TUNING_COEF_INIT = 32'b1,
parameter CHIRP_COUNT_MAX_INIT = 32'h00000dff, // 3584 samples
parameter CHIRP_FREQ_OFFSET_INIT = 32'h0b00, // 2816 -> 10.56 MHz min freq
parameter CHIRP_CTRL_WORD_INIT = 32'h20,

parameter ADC_CLK_FREQ                              = 245.7
)
(

  input                               rst_n,
  input                               clk,


  input                                   wr_cmd,
  input [7:0]                             wr_addr,
  input [31:0]                            wr_data,
  input [31:0]                            wr_keep,
  output                                   wr_valid,
  output                                  wr_ready,
  output reg [1:0]                        wr_err,

  input                                 network_cmd_en,

  // // Decoded Commands from RGMII RX fifo
  // input [RX_WR_CMD_DWIDTH-1:0]         cmd_axis_tdata,
  // input                                 cmd_axis_tvalid,
  // input                                 cmd_axis_tlast,
  // input [RX_WR_CMD_DWIDTH/8-1:0]       cmd_axis_tkeep,
  // output                                cmd_axis_tready,
  // Decoded Commands from RGMII RX fifo
  input [RX_WR_CMD_DWIDTH-1:0]         ch_wr_cmd_axis_tdata,
  input                                 ch_wr_cmd_axis_tvalid,
  input                                 ch_wr_cmd_axis_tlast,
  input [RX_WR_CMD_DWIDTH/8-1:0]       ch_wr_cmd_axis_tkeep,
  output                                ch_wr_cmd_axis_tready,

  // Decoded Commands from RGMII RX fifo
  input [RX_WR_CMD_DWIDTH-1:0]         sp_wr_cmd_axis_tdata,
  input                                 sp_wr_cmd_axis_tvalid,
  input                                 sp_wr_cmd_axis_tlast,
  input [RX_WR_CMD_DWIDTH/8-1:0]       sp_wr_cmd_axis_tkeep,
  output                                sp_wr_cmd_axis_tready,

 // input [7:0]                             gpio_dip_sw,
  // Chirp Control registers
  output reg [31:0]                 ch_prf_int = CHIRP_PRF_INT_COUNT_INIT, // prf in sec
  output reg [31:0]                 ch_prf_frac = CHIRP_PRF_FRAC_COUNT_INIT, //10*CHIRP_CLK_FREQ;  = 245760000  (10 sec)

  // Chirp Waveform Configuration registers
  output reg [31:0]                 ch_tuning_coef = CHIRP_TUNING_COEF_INIT,
  output reg [31:0]                 ch_counter_max = CHIRP_COUNT_MAX_INIT,
  output reg [31:0]                 ch_freq_offset = CHIRP_FREQ_OFFSET_INIT,
  output reg [31:0]                 ch_ctrl_word = CHIRP_CTRL_WORD_INIT,

  // ADC Sample time after chirp data_tx_done -
  output reg [31:0]                 adc_sample_time = ADC_SAMPLE_COUNT_INIT,
  // FMC150 Mode Control
  output [7:0] fmc150_ctrl_bus,
  // output reg ddc_duc_bypass                         = 1'b1, // dip_sw(3)
  // output reg digital_mode                           = 1'b0,
  // output reg adc_out_dac_in                         = 1'b0,
  // output reg external_clock                         = 1'b0,
  // output reg gen_adc_test_pattern                   = 1'b0,

  output [67:0] fmc150_spi_ctrl_bus_in,       // to fmc150
  input [47:0] fmc150_spi_ctrl_bus_out,       // from fmc150

  // -- Set_CH_A_iDelay <= fmc150_spi_ctrl_bus_in(4 downto 0);
  // -- Set_CH_B_iDelay <= fmc150_spi_ctrl_bus_in(9 downto 5);
  // -- Set_CLK_iDelay <= fmc150_spi_ctrl_bus_in(14 downto 10);
  // -- Register_Address <= fmc150_spi_ctrl_bus_in(30 downto 15);
  // -- SPI_Register_Data_to_FMC150 <= fmc150_spi_ctrl_bus_in(62 downto 31);
  // -- RW(0 downto 0)        <= fmc150_spi_ctrl_bus_in(63 downto 63);
  // -- CDCE72010(0 downto 0) <= fmc150_spi_ctrl_bus_in(64 downto 64);
  // -- ADS62P49(0 downto 0)  <= fmc150_spi_ctrl_bus_in(65 downto 65);
  // -- DAC3283(0 downto 0)   <= fmc150_spi_ctrl_bus_in(66 downto 66);
  // -- AMC7823(0 downto 0)   <= fmc150_spi_ctrl_bus_in(67 downto 67);


  // Ethernet Control Signals
  output [7:0] ethernet_ctrl_bus
  // output reg enable_adc_pkt                         = 1'b1, //dip_sw(1)
  // output reg gen_tx_data                            = 1'b0,
  // output reg chk_tx_data                            = 1'b0,
  // output reg [1:0] mac_speed                        = 2'b10 // {dip_sw(0),~dip_sw(0)}

);

reg wr_ready_reg                                    = 1'b0;
reg wr_valid_reg                                    = 1'b0;
reg wr_cmd_reg                                      = 1'b0;
reg [7:0] wr_addr_reg;
reg [31:0] wr_data_reg;
reg [31:0] wr_keep_reg;

reg ddc_duc_bypass_r = 1'b1;                        // dip_sw(3)
wire ddc_duc_bypass;
wire digital_mode;
wire adc_out_dac_in;
wire external_clock;
wire gen_adc_test_pattern;

reg [4:0] Set_CH_A_iDelay = 5'h1e;
reg [4:0] Set_CH_B_iDelay = 5'h00;
reg [4:0] Set_CLK_iDelay = 5'h00;
reg [15:0] Register_Address = 16'h0004;
reg [31:0] SPI_Register_Data_to_FMC150 = 32'h00000077;
reg RW = 0;
reg CDCE72010 = 0;
reg ADS62P49 = 0;
reg DAC3283 = 0;
reg AMC7823 = 0;

reg ch_wr_cmd_axis_tready_int;
reg sp_wr_cmd_axis_tready_int;

wire gen_tx_data;                           // depricated
wire chk_tx_data;                          // depticated
wire enable_adc_pkt;
wire [1:0] mac_speed;
reg enable_adc_pkt_r = 1'b1;                        //dip_sw(1)
reg [1:0] mac_speed_r = 2'b10;                        // {dip_sw[0],~dip_sw[0]};

wire [3:0] addr_up;
wire [3:0] addr_low;



assign wr_ready                                     = wr_ready_reg;
assign wr_valid                                     = wr_valid_reg;

assign fmc150_ctrl_bus = {3'b0,ddc_duc_bypass,digital_mode,adc_out_dac_in,external_clock,gen_adc_test_pattern};
assign ddc_duc_bypass = ddc_duc_bypass_r;
assign digital_mode                           = 1'b0;
assign adc_out_dac_in                         = 1'b0;
assign external_clock                         = 1'b0;
assign gen_adc_test_pattern                   = 1'b0;

assign fmc150_spi_ctrl_bus_in = {AMC7823,DAC3283,ADS62P49,CDCE72010,RW,SPI_Register_Data_to_FMC150,Register_Address,Set_CLK_iDelay,Set_CH_B_iDelay,Set_CH_A_iDelay};


assign ethernet_ctrl_bus = {2'b0,1'b1,enable_adc_pkt,gen_tx_data,chk_tx_data,mac_speed};
assign enable_adc_pkt = enable_adc_pkt_r;
assign mac_speed = mac_speed_r;
assign gen_tx_data = 1'b0;
assign chk_tx_data = 1'b0;


always @(posedge clk)
begin
  if (!rst_n)
    ch_wr_cmd_axis_tready_int <= 1'b0;
  else if (network_cmd_en)
    ch_wr_cmd_axis_tready_int <= 1'b1;
  else
    ch_wr_cmd_axis_tready_int <= 1'b0;
end

assign ch_wr_cmd_axis_tready = ch_wr_cmd_axis_tready_int;

always @(posedge clk)
begin
  if (!rst_n)
    sp_wr_cmd_axis_tready_int <= 1'b0;
  else if (network_cmd_en)
    sp_wr_cmd_axis_tready_int <= 1'b1;
  else
    sp_wr_cmd_axis_tready_int <= 1'b0;
end

assign sp_wr_cmd_axis_tready = sp_wr_cmd_axis_tready_int;

always @(posedge clk)
begin
    ddc_duc_bypass_r <= 1'b1;//gpio_dip_sw[3];
end

always @(posedge clk)
begin
    enable_adc_pkt_r <= 1'b1;//gpio_dip_sw[1];
    mac_speed_r <= 2'b10; //{gpio_dip_sw[0],~gpio_dip_sw[0]};
end

always @(posedge clk)
begin
  if (!rst_n) begin
    wr_ready_reg                                   <= 1'b0;
    wr_cmd_reg                                     <= 1'b0;
  end else if (wr_cmd & wr_ready_reg) begin
    wr_cmd_reg                                     <= wr_cmd;
    wr_addr_reg                                    <= wr_addr;
    wr_data_reg                                    <= wr_data;
    wr_keep_reg                                    <= wr_keep;
    //wr_valid_reg <= 1'b1;
  end else begin
    wr_cmd_reg                                     <= 1'b0;
    wr_ready_reg                                   <= 1'b1;
  end
end

assign addr_up                                      = wr_addr[7:4];
assign addr_low                                     = wr_addr[3:0];

always @(posedge clk)
begin
if (!rst_n) begin
  Set_CH_A_iDelay             <= 5'h1e; //fmc150_spi_ctrl_bus_in(4 downto 0);
  Set_CH_B_iDelay             <= 5'h00; //fmc150_spi_ctrl_bus_in(9 downto 5);
  Set_CLK_iDelay              <= 5'h00; //fmc150_spi_ctrl_bus_in(14 downto 10);
  Register_Address            <= 16'h0004; //fmc150_spi_ctrl_bus_in(30 downto 15);
  SPI_Register_Data_to_FMC150 <= 32'h00000077; //fmc150_spi_ctrl_bus_in(62 downto 31);
  RW        <= 1'b0; //fmc150_spi_ctrl_bus_in(63 downto 63);
  CDCE72010 <= 1'b0; //fmc150_spi_ctrl_bus_in(64 downto 64);
  ADS62P49  <= 1'b0; //fmc150_spi_ctrl_bus_in(65 downto 65);
  DAC3283   <= 1'b0; //fmc150_spi_ctrl_bus_in(66 downto 66);
  AMC7823   <= 1'b0; //fmc150_spi_ctrl_bus_in(67 downto 67);
end else if(network_cmd_en) begin
    if (sp_wr_cmd_axis_tvalid & sp_wr_cmd_axis_tready_int) begin
      Set_CH_A_iDelay             <= sp_wr_cmd_axis_tdata[4:0]; //fmc150_spi_ctrl_bus_in(4 downto 0);
      Set_CH_B_iDelay             <= sp_wr_cmd_axis_tdata[12:8]; //fmc150_spi_ctrl_bus_in(9 downto 5);
      Set_CLK_iDelay              <= sp_wr_cmd_axis_tdata[20:16]; //fmc150_spi_ctrl_bus_in(14 downto 10);
      Register_Address            <= sp_wr_cmd_axis_tdata[47:32]; //fmc150_spi_ctrl_bus_in(30 downto 15);
      SPI_Register_Data_to_FMC150 <= sp_wr_cmd_axis_tdata[95:64]; //fmc150_spi_ctrl_bus_in(62 downto 31);
      RW        <= sp_wr_cmd_axis_tdata[96]; //fmc150_spi_ctrl_bus_in(63 downto 63);
      CDCE72010 <= sp_wr_cmd_axis_tdata[128]; //fmc150_spi_ctrl_bus_in(64 downto 64);
      ADS62P49  <= sp_wr_cmd_axis_tdata[136]; //fmc150_spi_ctrl_bus_in(65 downto 65);
      DAC3283   <= sp_wr_cmd_axis_tdata[144]; //fmc150_spi_ctrl_bus_in(66 downto 66);
      AMC7823   <= sp_wr_cmd_axis_tdata[152]; //fmc150_spi_ctrl_bus_in(67 downto 67);
    end else begin
      Set_CH_A_iDelay             <= Set_CH_A_iDelay; //fmc150_spi_ctrl_bus_in(4 downto 0);
      Set_CH_B_iDelay             <= Set_CH_B_iDelay; //fmc150_spi_ctrl_bus_in(9 downto 5);
      Set_CLK_iDelay              <= Set_CLK_iDelay; //fmc150_spi_ctrl_bus_in(14 downto 10);
      Register_Address            <= Register_Address; //fmc150_spi_ctrl_bus_in(30 downto 15);
      SPI_Register_Data_to_FMC150 <= SPI_Register_Data_to_FMC150; //fmc150_spi_ctrl_bus_in(62 downto 31);
      RW        <= RW; //fmc150_spi_ctrl_bus_in(63 downto 63);
      CDCE72010 <= CDCE72010; //fmc150_spi_ctrl_bus_in(64 downto 64);
      ADS62P49  <= ADS62P49; //fmc150_spi_ctrl_bus_in(65 downto 65);
      DAC3283   <= DAC3283; //fmc150_spi_ctrl_bus_in(66 downto 66);
      AMC7823   <= AMC7823; //fmc150_spi_ctrl_bus_in(67 downto 67);
    end
end
end


always @(posedge clk)
begin
  if (!rst_n) begin
        wr_valid_reg                                   <= 1'b0;
        wr_err                                   <= 2'b0;
      // Chirp Control registers
      ch_prf_int           <= CHIRP_PRF_INT_COUNT_INIT; // prf in sec
      ch_prf_frac          <= CHIRP_PRF_FRAC_COUNT_INIT;
      ch_tuning_coef       <= CHIRP_TUNING_COEF_INIT;//32'b1;
      ch_counter_max      <= CHIRP_COUNT_MAX_INIT;//32'h00000fff;
      ch_freq_offset       <= CHIRP_FREQ_OFFSET_INIT; //32'h0600;
      ch_ctrl_word         <= CHIRP_CTRL_WORD_INIT; //32'h20;
      adc_sample_time      <= ADC_SAMPLE_COUNT_INIT;

  end else if(network_cmd_en) begin
    if (ch_wr_cmd_axis_tvalid & ch_wr_cmd_axis_tready_int) begin
      ch_prf_int <= ch_wr_cmd_axis_tdata[31:0];
      ch_prf_frac <= ch_wr_cmd_axis_tdata[63:32];
      adc_sample_time <= ch_wr_cmd_axis_tdata[95:64];
      ch_freq_offset <= ch_wr_cmd_axis_tdata[127:96];
      ch_tuning_coef<= ch_wr_cmd_axis_tdata[159:128];
      ch_counter_max <= ch_wr_cmd_axis_tdata[191:160]-1'b1;
      ch_ctrl_word <= ch_wr_cmd_axis_tdata[223:192];
    end else begin
      ch_prf_int <= ch_prf_int;
      ch_prf_frac <= ch_prf_frac;
      adc_sample_time <= adc_sample_time;
      ch_freq_offset <= ch_freq_offset;
      ch_tuning_coef<= ch_tuning_coef;
      ch_counter_max <= ch_counter_max;
      ch_ctrl_word <= ch_ctrl_word;
    end
  end else if(wr_cmd & wr_ready_reg) begin

    if (addr_up == 4'b0000) begin
      if (addr_low == 4'b0000) begin
        if (&wr_keep[31:0]) begin
          ch_prf_int                               <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else if (addr_low == 4'b0001) begin
        if (&wr_keep[31:0]) begin
          ch_prf_frac                              <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else if (addr_low == 4'b0010) begin
        if (&wr_keep[31:0]) begin
          ch_tuning_coef                           <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else if (addr_low == 4'b0011) begin
        if (&wr_keep[31:0]) begin
          ch_counter_max                          <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else if (addr_low == 4'b0100) begin
        if (&wr_keep[31:0]) begin
          ch_freq_offset                           <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else if (addr_low == 4'b0101) begin
        if (&wr_keep[31:0]) begin
          adc_sample_time                          <= wr_data;
          wr_valid_reg                             <= 1'b1;
          wr_err                                   <= 2'b0;
        end else begin
          wr_valid_reg                             <= 1'b0;
          wr_err                                   <= 2'b01;
        end
      end else begin
        wr_valid_reg                               <= 1'b0;
        wr_err                                     <= 2'b11;
      end
    end else begin
      wr_valid_reg                                 <= 1'b0;
      wr_err                                       <= 2'b11;
    end
  end else begin
    wr_valid_reg                                   <= 1'b0;
  end
end





endmodule
