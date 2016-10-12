`timescale 1ps/100fs

module sim_tb_regmap;

   localparam CLK_PERIOD          = 8000;         // 125 MHz
  localparam RESET_PERIOD = 320000; //in pSec

  reg                               rst_n_i;
  reg                               clk_i;

  wire                               rst_n;
  wire                               clk;

  reg                                   wr_cmd_i;
  reg [7:0]                             wr_addr_i;
  reg [31:0]                            wr_data_i;
  reg [31:0]                            wr_keep_i;
  wire                                  wr_valid;
  wire                                  wr_ready;
  wire [1:0]                            wr_err;
  
  reg                                    wr_cmd_ii;
  
  wire                                   wr_cmd;
  wire [7:0]                             wr_addr;
  wire [31:0]                            wr_data;
  wire [31:0]                            wr_keep;

  // Chirp Control registers
wire [31:0]                 ch_prf_int; // prf in sec
wire [31:0]                 ch_prf_frac;
wire [31:0]                 ch_tuning_coef;
wire [31:0]                 ch_counter_size;
wire [31:0]                 ch_freq_offset;
wire [31:0]                 adc_sample_time;
wire ddc_duc_bypass;  // dip_sw(3)
wire digital_mode;
wire adc_out_dac_in;
wire external_clock;
wire gen_adc_test_pattern;
wire enable_adc_pkt;
wire gen_tx_data ;
wire chk_tx_data;
wire [1:0] mac_speed;

reg enable_write;


 //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
  initial begin
    rst_n_i = 1'b0;
    #RESET_PERIOD
      rst_n_i = 1'b1;
   end

  //**************************************************************************//
  // Clock Generation
  //**************************************************************************//

  initial
    begin
        clk_i = 1'b0;
    end
  always
    begin
        clk_i = #(CLK_PERIOD/2.0) ~clk_i;
    end


   assign rst_n = rst_n_i;
   assign clk = clk_i;


 initial begin
      enable_write = 1'b1; // initial value
      @(posedge rst_n_i); // wait for reset
      enable_write = 1'b0;
      repeat(32) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(256) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(32) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(1) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(3) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(1) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(2) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(1) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(1) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(256) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(2048) @(posedge clk_i);
      enable_write = 1'b0;
      repeat(2048) @(posedge clk_i);
      enable_write = 1'b1;
      repeat(2048) @(posedge clk_i);
      $finish;
    end

 always @(posedge  clk_i) begin
    if (~rst_n_i) begin
        wr_cmd_i <= 1'b0;
    end else begin
        if (wr_ready & enable_write & !wr_cmd_i) begin
            wr_cmd_i <= 1'b1;
       end else begin
            wr_cmd_i <= 1'b0;
        end
    end
end

always @(posedge  clk_i) begin
    if (~rst_n_i)
       wr_cmd_ii <= 1'b0;
    else
        wr_cmd_ii <= wr_cmd_i;
end
always @(posedge  clk_i) begin
   if (~rst_n_i) begin
       wr_addr_i <= 8'b0;
       wr_data_i <= 32'd20;
       wr_keep_i <= 32'hfffffff0;
   end else begin
       if (wr_valid & wr_cmd_ii) begin
           wr_addr_i <= wr_addr_i + 1;
           wr_data_i <= wr_data_i + 1;
           wr_keep_i <= wr_keep_i;
       end else if (wr_cmd_ii & (&wr_err))
           wr_addr_i <= wr_addr_i+1;
       else if (wr_cmd_ii & (wr_err == 2'b01))
           wr_keep_i <= wr_keep_i + 1;
       else if (wr_cmd_ii & (wr_err == 2'b10))
           wr_keep_i <= {wr_keep_i[31:1],1'b1};
   end
end


 config_reg_map  u_regmap_top (
        .clk (clk),
        .rst_n (rst_n),

      .wr_cmd                                  ( wr_cmd),
      .wr_addr                                 ( wr_addr),
      .wr_data                                 ( wr_data),
      .wr_keep                                 ( wr_keep),
      .wr_valid                                ( wr_valid),
      .wr_ready                                ( wr_ready),
      .wr_err                                  ( wr_err),

        // Chirp Control registers
          .ch_prf_int  (ch_prf_int),
          .ch_prf_frac (ch_prf_frac),

          .adc_sample_time       (adc_sample_time),
          .ch_tuning_coef  (ch_tuning_coef),
          .ch_counter_max  (ch_counter_size),
          .ch_freq_offset  (ch_freq_offset),

        // FMC150 Mode Control
      .ddc_duc_bypass                         (ddc_duc_bypass),
      .digital_mode                           (digital_mode),
      .adc_out_dac_in                         (adc_out_dac_in),
      .external_clock                         (external_clock),
      .gen_adc_test_pattern                   (gen_adc_test_pattern),

    //  . Control Signals
      .enable_adc_pkt                         (enable_adc_pkt),
      .gen_tx_data                            (gen_tx_data),
      .chk_tx_data                            (chk_tx_data),
      .mac_speed                              (mac_speed)
);

assign wr_cmd = wr_cmd_i;
assign wr_addr = wr_addr_i;
assign wr_data = wr_data_i;
assign wr_keep = wr_keep_i;



endmodule
