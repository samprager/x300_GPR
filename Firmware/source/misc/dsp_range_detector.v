`timescale 1ps/1ps

module dsp_range_detector #
  (
     parameter PK_AXI_DATA_WIDTH = 512,
     parameter PK_AXI_TID_WIDTH = 1,
     parameter PK_AXI_TDEST_WIDTH = 1,
     parameter PK_AXI_TUSER_WIDTH = 1,
     parameter PK_AXI_STREAM_ID = 1'b0,
     parameter PK_AXI_STREAM_DEST = 1'b0,

     parameter FFT_LEN = 8192,
     parameter SIMULATION = 0
   )
  (

   input    aclk, // AXI input clock
   input    aresetn, // Active low AXI reset signal

   // --ADC Data Out Signals
  input [31:0] adc_iq_tdata,
  input [31:0] dac_iq_tdata,
  input iq_tvalid,
  input iq_tlast,
  output iq_tready,
  input iq_first,
  input [63:0] counter_id,

  output [PK_AXI_DATA_WIDTH-1:0]     pk_axis_tdata,
  output pk_axis_tvalid,
  output pk_axis_tlast,
  output reg [PK_AXI_DATA_WIDTH/8-1:0] pk_axis_tkeep = {PK_AXI_DATA_WIDTH/8{1'b1}},
  output reg [PK_AXI_TDEST_WIDTH-1:0] pk_axis_tdest = PK_AXI_STREAM_DEST[PK_AXI_TDEST_WIDTH-1:0],
  output reg [PK_AXI_TID_WIDTH-1:0] pk_axis_tid = PK_AXI_STREAM_ID[PK_AXI_TID_WIDTH-1:0],
  output reg [PK_AXI_DATA_WIDTH/8-1:0]pk_axis_tstrb = {PK_AXI_DATA_WIDTH/8{1'b1}},
  output reg [PK_AXI_TUSER_WIDTH-1:0] pk_axis_tuser = {PK_AXI_TUSER_WIDTH{1'b0}},
  input  pk_axis_tready,

  input [31:0] lpf_cutoff,
  input [7:0] threshold_ctrl_i,    // {4b word index, 4b word value} in 64bit threshold
  input [7:0] threshold_ctrl_q,    // {4b word index, 4b word value} in 64bit threshold

// Control Module signals
  input chirp_ready,
  input chirp_done,
  input chirp_active,
  input chirp_init,
  input chirp_enable,
  input adc_enable,
  input [31:0] chirp_control_word,
  input [31:0] chirp_freq_offset,
  input [31:0] chirp_tuning_word_coeff,
  input [31:0] chirp_count_max

   );

   localparam FCUTOFF_IND = FFT_LEN/2;
   localparam MIXER_LATENCY = 3;
   localparam INIT_THRESHOLD = {4'b0001,60'b0};

   integer i;

  wire [15:0] adc_data_i;
  wire [15:0] adc_data_q;
  wire [15:0] dac_data_i;
  wire [15:0] dac_data_q;

  reg [MIXER_LATENCY-1:0] iq_tvalid_shift;
  reg [MIXER_LATENCY-1:0] iq_tlast_shift;


     wire [63:0] s_fft_i_axis_tdata;
     wire s_fft_i_axis_tvalid;
     wire s_fft_i_axis_tlast;
     wire s_fft_i_axis_tready;

     wire [63:0] s_fft_q_axis_tdata;
     wire s_fft_q_axis_tvalid;
     wire s_fft_q_axis_tlast;
     wire s_fft_q_axis_tready;

     wire [63:0] m_fft_i_axis_tdata;
     wire m_fft_i_axis_tvalid;
     wire m_fft_i_axis_tlast;
     wire m_fft_i_axis_tready;
     wire [31:0] m_fft_i_index;

     wire [63:0] m_fft_q_axis_tdata;
     wire m_fft_q_axis_tvalid;
     wire m_fft_q_axis_tlast;
     wire m_fft_q_axis_tready;
     wire [31:0] m_fft_q_index;

     wire [31:0] mixer_out_i;
     wire [31:0] mixer_out_q;

     wire [31:0] mag_i_axis_tdata;
     wire [31:0] mag_q_axis_tdata;

     wire [63:0] sq_mag_i_axis_tdata;
     wire        sq_mag_i_axis_tvalid;
     wire        sq_mag_i_axis_tlast;
     wire [63:0] sq_mag_q_axis_tdata;
     wire        sq_mag_q_axis_tvalid;
     wire        sq_mag_q_axis_tlast;
     wire       sq_mag_i_axis_tdata_overflow;
     wire       sq_mag_q_axis_tdata_overflow;
     wire [31:0] sq_mag_i_axis_tuser;
     wire [31:0] sq_mag_q_axis_tuser;
     wire [31:0] sq_mag_i_index;
     wire [31:0] sq_mag_q_index;

     wire [31:0] peak_index_i;
     wire [63:0] peak_tdata_i;
     wire peak_tvalid_i;
     wire peak_tlast_i;
     wire [31:0] peak_tuser_i;
     wire [31:0] num_peaks_i;

     wire [31:0] peak_index_q;
     wire [63:0] peak_tdata_q;
     wire peak_tvalid_q;
     wire peak_tlast_q;
     wire [31:0] peak_tuser_q;
     wire [31:0] num_peaks_q;

     reg [31:0] peak_result_i;
     reg [31:0] peak_result_q;
     reg [63:0] peak_val_i;
     reg [31:0] peak_num_i;
     reg [63:0] peak_val_q;
     reg [31:0] peak_num_q;
     reg new_peak_i;
     reg new_peak_q;

     wire [63:0] lpf_tdata_i;
     wire lpf_tvalid_i;
     wire lpf_tlast_i;
     wire [31:0] lpf_tuser_i;
     wire [31:0] lpf_index_i;

     wire [63:0] lpf_tdata_q;
     wire lpf_tvalid_q;
     wire lpf_tlast_q;
     wire [31:0] lpf_tuser_q;
     wire [31:0] lpf_index_q;

     wire [31:0] lpf_cutoff_ind;
     reg [63:0] peak_threshold_i_r;
     reg [63:0] peak_threshold_q_r;
     reg [63:0] peak_threshold_i_rr;
     reg [63:0] peak_threshold_q_rr;
     wire [63:0] peak_threshold_i;
     wire [63:0] peak_threshold_q;
     reg update_threshold_r;
     reg update_threshold_rr;

     wire [PK_AXI_DATA_WIDTH/2-1:0] dw_axis_tdata;

     reg pk_axis_tvalid_r;
     reg pk_axis_tlast_r;

     reg [PK_AXI_DATA_WIDTH/2-1:0] config_r;



//assign clk_out_491_52MHz = clk_491_52MHz;

assign dac_data_i = dac_iq_tdata[31:16];
assign dac_data_q = dac_iq_tdata[15:0];
assign adc_data_i = adc_iq_tdata[31:16];
assign adc_data_q = adc_iq_tdata[15:0];

assign s_fft_i_axis_tdata = {32'b0,mixer_out_i};
assign s_fft_i_axis_tvalid = iq_tvalid_shift[MIXER_LATENCY-1];
assign s_fft_i_axis_tlast = iq_tlast_shift[MIXER_LATENCY-1];

assign s_fft_q_axis_tdata = {32'b0,mixer_out_q};
assign s_fft_q_axis_tvalid = iq_tvalid_shift[MIXER_LATENCY-1];
assign s_fft_q_axis_tlast = iq_tlast_shift[MIXER_LATENCY-1];

assign iq_tready = s_fft_i_axis_tready & s_fft_q_axis_tready;

assign m_fft_i_axis_tready = 1'b1;
assign m_fft_q_axis_tready = 1'b1;

assign lpf_cutoff_ind = lpf_cutoff;
//assign lpf_cutoff_ind = FCUTOFF_IND;
// assign peak_threshold_i = {{(60-4*threshold_ctrl_i[7:4]){1'b0}},threshold_ctrl_i[3:0],{(4*threshold_ctrl_i[7:4]){1'b0}}};
// assign peak_threshold_q = {{(60-4*threshold_ctrl_q[7:4]){1'b0}},threshold_ctrl_q[3:0],{(4*threshold_ctrl_q[7:4]){1'b0}}};
//assign peak_threshold_i = {4'b0001,60'b0};
//assign peak_threshold_q = {4'b0001,60'b0};
assign peak_threshold_i = peak_threshold_i_rr;
assign peak_threshold_q = peak_threshold_q_rr;

assign dw_axis_tdata = {peak_num_i,peak_num_q,peak_val_i,peak_val_q,peak_result_i,peak_result_q};
assign pk_axis_tdata = {dw_axis_tdata,config_r};
//assign pk_axis_tdata = {peak_num_i,peak_num_q,peak_val_i,peak_val_q,peak_result_i,peak_result_q};
assign pk_axis_tvalid = pk_axis_tvalid_r;
assign pk_axis_tlast = pk_axis_tlast_r;

always @(posedge aclk) begin
  iq_tvalid_shift[0] <= iq_tvalid;
  iq_tlast_shift[0] <= iq_tlast;
  for(i=1;i<MIXER_LATENCY;i=i+1) begin
    iq_tvalid_shift[i] <= iq_tvalid_shift[i-1];
    iq_tlast_shift[i] <= iq_tlast_shift[i-1];
  end
end

always @(posedge aclk) begin
  if(iq_first) begin
    // config_r[63:0] <= counter_id;
    // config_r[95:64] <= chirp_control_word;
    // config_r[127:96] <= chirp_freq_offset;
    // config_r[159:128] <= chirp_tuning_word_coeff;
    // config_r[191:160] <= chirp_count_max;
    // config_r[199:192] <= threshold_ctrl_i;
    // config_r[207:200] <= threshold_ctrl_q;
    // config_r[223:208] <= 16'hbeef;
    // config_r[255:224] <= 32'h504b504b; // Ascii 'PKPK'
    config_r[31:0] <= 32'h504b504b;
    config_r[47:32] <= 16'hbeef;
    config_r[55:48] <= threshold_ctrl_i;
    config_r[63:56] <= threshold_ctrl_q;
    config_r[127:64] <= counter_id;
    config_r[159:128] <= chirp_control_word;
    config_r[191:160] <= chirp_freq_offset;
    config_r[223:192] <= chirp_tuning_word_coeff;
    config_r[255:224] <= chirp_count_max;
  end
end

always @(posedge aclk) begin
if(iq_first)begin
  peak_threshold_i_r <= 'b0;
  peak_threshold_q_r <= 'b0;
end else if (update_threshold_r) begin
  peak_threshold_i_r[4*threshold_ctrl_i[7:4]+3-:4] <=threshold_ctrl_i[3:0];
  peak_threshold_q_r[4*threshold_ctrl_q[7:4]+3-:4] <=threshold_ctrl_q[3:0];
end
end

always @(posedge aclk) begin
if(aresetn)begin
  peak_threshold_i_rr <= INIT_THRESHOLD;
  peak_threshold_q_rr <= INIT_THRESHOLD;
end else if (update_threshold_rr) begin
  peak_threshold_i_rr<=peak_threshold_i_r;
  peak_threshold_i_rr<=peak_threshold_i_r;
end
end

always @(posedge aclk) begin
if(iq_first)
  update_threshold_r <= 1'b1;
else
  update_threshold_r <= 1'b0;
end

always @(posedge aclk) begin
if(update_threshold_r)
  update_threshold_rr <= 1'b1;
else
  update_threshold_rr <= 1'b0;
end

always @(posedge aclk) begin
  if (!aresetn) begin
    new_peak_i <= 1'b0;
  end else if (peak_tlast_i & peak_tvalid_i) begin
    peak_result_i <= peak_index_i;
    peak_val_i <= peak_tdata_i;
    peak_num_i <= num_peaks_i;
    new_peak_i <= 1'b1;
  end else if (pk_axis_tvalid_r)begin
    new_peak_i <= 1'b0;
  end
end

always @(posedge aclk) begin
  if (!aresetn) begin
    new_peak_q <= 1'b0;
  end else if (peak_tlast_q & peak_tvalid_q) begin
    peak_result_q <= peak_index_q;
    peak_val_q <= peak_tdata_q;
    peak_num_q <= num_peaks_q;
    new_peak_q <= 1'b1;
  end else if (pk_axis_tvalid_r)begin
    new_peak_q <= 1'b0;
  end
end

always @(posedge aclk) begin
  if (!aresetn) begin
    pk_axis_tvalid_r <= 1'b0;
    pk_axis_tlast_r <= 1'b0;
  end else if(new_peak_i & new_peak_q & !pk_axis_tvalid_r)begin
    pk_axis_tvalid_r <= 1'b1;
    pk_axis_tlast_r <= 1'b1;
  end else if (pk_axis_tready)begin
    pk_axis_tvalid_r <= 1'b0;
    pk_axis_tlast_r <= 1'b0;
  end
end

mixer_mult_gen mixer_i (
 .CLK(aclk),  // input wire CLK
 .A(dac_data_i),      // input wire [15 : 0] A
 .B(adc_data_i),      // input wire [15 : 0] B
 //.P(s_fft_axis_tdata[31:0])      // output wire [31 : 0] P
  .P(mixer_out_i)       // output wire [31 : 0] P
);
mixer_mult_gen mixer_q (
 .CLK(aclk),  // input wire CLK
 .A(dac_data_q),      // input wire [15 : 0] A
 .B(adc_data_q),      // input wire [15 : 0] B
 //.P(s_fft_axis_tdata[63:32])      // output wire [31 : 0] P
 .P(mixer_out_q)    // output wire [31 : 0] P
);

sq_mag_estimate#(
    .DATA_LEN(32),
    .DIV_OR_OVERFLOW(0),  // (1): Divide output by 2, (0): use overflow bit
    .REGISTER_OUTPUT(1)
)
 sq_mag_i (
    .clk(aclk),
    .dataI(m_fft_i_axis_tdata[31:0]),
    .dataI_tvalid(m_fft_i_axis_tvalid),
    .dataI_tlast(m_fft_i_axis_tlast),
    .dataQ(m_fft_i_axis_tdata[63:32]),
    .dataQ_tvalid(m_fft_i_axis_tvalid),
    .dataQ_tlast(m_fft_i_axis_tlast),
    .data_index(m_fft_i_index),
    .data_tuser(chirp_tuning_word_coeff),
    .dataMagSq(sq_mag_i_axis_tdata),
    .dataMag_tvalid(sq_mag_i_axis_tvalid),
    .dataMag_tlast(sq_mag_i_axis_tlast),
    .dataMag_tuser(sq_mag_i_axis_tuser),
    .dataMag_index(sq_mag_i_index),
    .overflow(sq_mag_i_axis_tdata_overflow)
);

sq_mag_estimate#(
    .DATA_LEN(32),
    .DIV_OR_OVERFLOW(0),     // (1): Divide output by 2, (0): use overflow bit
    .REGISTER_OUTPUT(1)
)
 sq_mag_q (
   .clk(aclk),
   .dataI(m_fft_q_axis_tdata[31:0]),
   .dataI_tvalid(m_fft_q_axis_tvalid),
   .dataI_tlast(m_fft_q_axis_tlast),
   .dataQ(m_fft_q_axis_tdata[63:32]),
   .dataQ_tvalid(m_fft_q_axis_tvalid),
   .dataQ_tlast(m_fft_q_axis_tlast),
   .data_index(m_fft_q_index),
   .data_tuser(chirp_tuning_word_coeff),
   .dataMagSq(sq_mag_q_axis_tdata),
   .dataMag_tvalid(sq_mag_q_axis_tvalid),
   .dataMag_tlast(sq_mag_q_axis_tlast),
   .dataMag_tuser(sq_mag_q_axis_tuser),
   .dataMag_index(sq_mag_q_index),
   .overflow(sq_mag_q_axis_tdata_overflow)
);

freq_domain_lpf #(
    .DATA_LEN(64)
) freq_lpf_i(
     .clk(aclk),
     .aresetn(aresetn),
     .tdata(sq_mag_i_axis_tdata),
     .tvalid(sq_mag_i_axis_tvalid),
     .tlast(sq_mag_i_axis_tlast),
     .tuser(sq_mag_i_axis_tuser),
     .index(sq_mag_i_index),
     .cutoff(lpf_cutoff_ind),
     .lpf_index(lpf_index_i),
     .lpf_tdata(lpf_tdata_i),
     .lpf_tvalid(lpf_tvalid_i),
     .lpf_tlast(lpf_tlast_i),
     .lpf_tuser(lpf_tuser_i)
   );


 freq_domain_lpf #(
     .DATA_LEN(64)
 ) freq_lpf_q(
      .clk(aclk),
      .aresetn(aresetn),
      .tdata(sq_mag_q_axis_tdata),
      .tvalid(sq_mag_q_axis_tvalid),
      .tlast(sq_mag_q_axis_tlast),
      .tuser(sq_mag_q_axis_tuser),
      .index(sq_mag_q_index),
      .cutoff(lpf_cutoff_ind),
      .lpf_index(lpf_index_q),
      .lpf_tdata(lpf_tdata_q),
      .lpf_tvalid(lpf_tvalid_q),
      .lpf_tlast(lpf_tlast_q),
      .lpf_tuser(lpf_tuser_q)
    );

peak_finder #(
  .DATA_LEN(64)
) peak_finder_i(
  .clk(aclk),
  .aresetn(aresetn),
//      .tdata(sq_mag_i_axis_tdata),
//      .tvalid(sq_mag_i_axis_tvalid),
//      .tlast(sq_mag_i_axis_tlast),
//      .tuser(sq_mag_i_axis_tuser),
//      .index(sq_mag_i_index),
  .tdata(lpf_tdata_i),
  .tvalid(lpf_tvalid_i),
  .tlast(lpf_tlast_i),
  .tuser(lpf_tuser_i),
  .index(lpf_index_i),
  .threshold(peak_threshold_i),
  .peak_index(peak_index_i),
  .peak_tdata(peak_tdata_i),
  .peak_tvalid(peak_tvalid_i),
  .peak_tlast(peak_tlast_i),
  .peak_tuser(peak_tuser_i),
  .num_peaks(num_peaks_i)
);
peak_finder #(
  .DATA_LEN(64)
) peak_finder_q(
  .clk(aclk),
  .aresetn(aresetn),
  .tdata(lpf_tdata_q),
  .tvalid(lpf_tvalid_q),
  .tlast(lpf_tlast_q),
  .tuser(lpf_tuser_q),
  .index(lpf_index_q),
  .threshold(peak_threshold_q),
  .peak_index(peak_index_q),
  .peak_tdata(peak_tdata_q),
  .peak_tvalid(peak_tvalid_q),
  .peak_tlast(peak_tlast_q),
  .peak_tuser(peak_tuser_q),
  .num_peaks(num_peaks_q)
);

//c_mag_estimate#(
//    .DATA_LEN(32),
//    .ALPHA(0.9),
//    .BETA(0.4)
//)
// abs_i (
//    .clk(aclk),
//    .dataI(m_fft_axis_tdata[31:0]),
//    .dataQ(m_fft_axis_tdata[63:32]),
//    .dataMag(mag_i_axis_tdata)
//);

//c_mag_estimate#(
//    .DATA_LEN(32),
//    .ALPHA(0.9),
//    .BETA(0.4)
//)
// abs_q (
//    .clk(aclk),
//    .dataI(m_fft_axis_tdata[95:64]),
//    .dataQ(m_fft_axis_tdata[127:96]),
//    .dataMag(mag_q_axis_tdata)
//);


fft_dsp #(
  .FFT_LEN(FFT_LEN),
  .FFT_CHANNELS(1),
  .FFT_AXI_DATA_WIDTH (64),
  .SIMULATION(SIMULATION)
  )
  fft_dsp_i(

  .aclk (aclk),
  .aresetn (aresetn),

 .s_axis_tdata(s_fft_i_axis_tdata),
 .s_axis_tvalid (s_fft_i_axis_tvalid),
 .s_axis_tlast(s_fft_i_axis_tlast),
 .s_axis_tready(s_fft_i_axis_tready),

.m_axis_tdata(m_fft_i_axis_tdata),
.m_axis_tvalid(m_fft_i_axis_tvalid),
.m_axis_tlast(m_fft_i_axis_tlast),
.m_axis_tready(m_fft_i_axis_tready),

.m_index(m_fft_i_index),

   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable)

);

fft_dsp #(
  .FFT_LEN(FFT_LEN),
  .FFT_CHANNELS(1),
  .FFT_AXI_DATA_WIDTH (64),
  .SIMULATION(SIMULATION)
  )
  fft_dsp_q(

  .aclk (aclk),
  .aresetn (aresetn),

 .s_axis_tdata(s_fft_q_axis_tdata),
 .s_axis_tvalid (s_fft_q_axis_tvalid),
 .s_axis_tlast(s_fft_q_axis_tlast),
 .s_axis_tready(s_fft_q_axis_tready),

.m_axis_tdata(m_fft_q_axis_tdata),
.m_axis_tvalid(m_fft_q_axis_tvalid),
.m_axis_tlast(m_fft_q_axis_tlast),
.m_axis_tready(m_fft_q_axis_tready),

.m_index(m_fft_q_index),

   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable)

);





   endmodule
