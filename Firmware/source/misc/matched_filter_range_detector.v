`timescale 1ps/1ps

module matched_filter_range_detector #
  (
     parameter PK_AXI_DATA_WIDTH = 512,
     parameter PK_AXI_TID_WIDTH = 1,
     parameter PK_AXI_TDEST_WIDTH = 1,
     parameter PK_AXI_TUSER_WIDTH = 1,
     parameter PK_AXI_STREAM_ID = 1'b0,
     parameter PK_AXI_STREAM_DEST = 1'b0,

     parameter FFT_LEN = 4096,
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
  input [7:0] threshold_ctrl,    // {4b word index, 4b word value} in 64bit threshold

// Control Module signals
  input chirp_ready,
  input chirp_done,
  input chirp_active,
  input chirp_init,
  input chirp_enable,
  input adc_enable,
  input [31:0] awg_control_word,
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


     wire [31:0] s_fft_dac_axis_tdata;
     wire s_fft_dac_axis_tvalid;
     wire s_fft_dac_axis_tlast;
     wire s_fft_dac_axis_tready;

     wire [31:0] s_fft_adc_axis_tdata;
     wire s_fft_adc_axis_tvalid;
     wire s_fft_adc_axis_tlast;
     wire s_fft_adc_axis_tready;

     wire [31:0] m_fft_dac_axis_tdata;
     wire m_fft_dac_axis_tvalid;
     wire m_fft_dac_axis_tlast;
     wire m_fft_dac_axis_tready;
     wire [31:0] m_fft_dac_index;

     wire [15:0] m_fft_dac_conj_i_axis_tdata;
     wire [15:0] m_fft_dac_conj_q_axis_tdata;

     wire [31:0] m_fft_adc_axis_tdata;
     wire m_fft_adc_axis_tvalid;
     wire m_fft_adc_axis_tlast;
     wire m_fft_adc_axis_tready;
     wire [31:0] m_fft_adc_index;

     wire m_cmpy_axis_tvalid;
     wire m_cmpy_axis_tready;
     wire [63:0] m_cmpy_index;
     wire m_cmpy_axis_tlast;
     wire [63:0] m_cmpy_axis_tdata;

     wire m_ifft_axis_tvalid;
     wire m_ifft_axis_tready;
     wire [31:0] m_ifft_index;
     wire m_ifft_axis_tlast;
     wire [63:0] m_ifft_axis_tdata;

     wire [63:0] sq_mag_axis_tdata;
     wire        sq_mag_axis_tvalid;
     wire        sq_mag_axis_tlast;
     wire       sq_mag_axis_tdata_overflow;
     wire [31:0] sq_mag_axis_tuser;
     wire [31:0] sq_mag_index;

     wire [31:0] peak_index;
     wire [63:0] peak_tdata;
     wire peak_tvalid;
     wire peak_tlast;
     wire [31:0] peak_tuser;
     wire [31:0] num_peaks;

     reg [31:0] peak_result;
     reg [63:0] peak_val;
     reg [31:0] peak_num;
     reg new_peak;

     wire [63:0] lpf_tdata;
     wire lpf_tvalid;
     wire lpf_tlast;
     wire [31:0] lpf_tuser;
     wire [31:0] lpf_index;

     wire [31:0] lpf_cutoff_ind;
     reg [63:0] peak_threshold_r;
     reg [63:0] peak_threshold_rr;
     wire [63:0] peak_threshold;
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

assign s_fft_dac_axis_tdata = {dac_data_q,dac_data_i};
// assign s_fft_dac_axis_tvalid = iq_tvalid_shift[MIXER_LATENCY-1];
// assign s_fft_dac_axis_tlast = iq_tlast_shift[MIXER_LATENCY-1];
assign s_fft_dac_axis_tvalid = iq_tvalid;
assign s_fft_dac_axis_tlast = iq_tlast;

assign s_fft_adc_axis_tdata = {adc_data_q,adc_data_i};
// assign s_fft_adc_axis_tvalid = iq_tvalid_shift[MIXER_LATENCY-1];
// assign s_fft_adc_axis_tlast = iq_tlast_shift[MIXER_LATENCY-1];
assign s_fft_adc_axis_tvalid = iq_tvalid;
assign s_fft_adc_axis_tlast = iq_tlast;

assign iq_tready = s_fft_dac_axis_tready & s_fft_adc_axis_tready;

//assign m_fft_dac_axis_tready = 1'b1;
//assign m_fft_adc_axis_tready = 1'b1;

assign lpf_cutoff_ind = lpf_cutoff;
//assign lpf_cutoff_ind = FCUTOFF_IND;
// assign peak_threshold_i = {{(60-4*threshold_ctrl_i[7:4]){1'b0}},threshold_ctrl_i[3:0],{(4*threshold_ctrl_i[7:4]){1'b0}}};
// assign peak_threshold_q = {{(60-4*threshold_ctrl_q[7:4]){1'b0}},threshold_ctrl_q[3:0],{(4*threshold_ctrl_q[7:4]){1'b0}}};
//assign peak_threshold_i = {4'b0001,60'b0};
//assign peak_threshold_q = {4'b0001,60'b0};
assign peak_threshold = peak_threshold_rr;

assign dw_axis_tdata = {peak_num,peak_num,peak_val,peak_val,peak_result,peak_result};

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
    // config_r[95:64] <= awg_control_word;
    // config_r[127:96] <= chirp_freq_offset;
    // config_r[159:128] <= chirp_tuning_word_coeff;
    // config_r[191:160] <= chirp_count_max;
    // config_r[199:192] <= threshold_ctrl_i;
    // config_r[207:200] <= threshold_ctrl_q;
    // config_r[223:208] <= 16'hbeef;
    // config_r[255:224] <= 32'h504b504b; // Ascii 'PKPK'
    config_r[31:0] <= 32'h504b504b;
    config_r[47:32] <= 16'hbeef;
    config_r[55:48] <= threshold_ctrl;
    config_r[63:56] <= threshold_ctrl;
    config_r[127:64] <= counter_id;
    config_r[159:128] <= awg_control_word;
    config_r[191:160] <= chirp_freq_offset;
    config_r[223:192] <= chirp_tuning_word_coeff;
    config_r[255:224] <= chirp_count_max;
  end
end

always @(posedge aclk) begin
if(iq_first)begin
  peak_threshold_r <= 'b0;
end else if (update_threshold_r) begin
  peak_threshold_r[4*threshold_ctrl[7:4]+3-:4] <=threshold_ctrl[3:0];
end
end

always @(posedge aclk) begin
if(aresetn)begin
  peak_threshold_rr <= INIT_THRESHOLD;
end else if (update_threshold_rr) begin
  peak_threshold_rr<=peak_threshold_r;
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
    new_peak <= 1'b0;
  end else if (peak_tlast & peak_tvalid) begin
    peak_result <= peak_index;
    peak_val <= peak_tdata;
    peak_num <= num_peaks;
    new_peak <= 1'b1;
  end else if (pk_axis_tvalid_r)begin
    new_peak <= 1'b0;
  end
end


always @(posedge aclk) begin
  if (!aresetn) begin
    pk_axis_tvalid_r <= 1'b0;
    pk_axis_tlast_r <= 1'b0;
  end else if(new_peak & !pk_axis_tvalid_r)begin
    pk_axis_tvalid_r <= 1'b1;
    pk_axis_tlast_r <= 1'b1;
  end else if (pk_axis_tready)begin
    pk_axis_tvalid_r <= 1'b0;
    pk_axis_tlast_r <= 1'b0;
  end
end



sq_mag_estimate#(
    .DATA_LEN(32),
    .DIV_OR_OVERFLOW(0),  // (1): Divide output by 2, (0): use overflow bit
    .REGISTER_OUTPUT(1)
)
 sq_mag_corr (
    .clk(aclk),
    .dataI(m_ifft_axis_tdata[31:0]),
    .dataI_tvalid(m_ifft_axis_tvalid),
    .dataI_tlast(m_ifft_axis_tlast),
    .dataQ(m_ifft_axis_tdata[63:32]),
    .dataQ_tvalid(m_ifft_axis_tvalid),
    .dataQ_tlast(m_ifft_axis_tlast),
    .data_index(m_ifft_index[31:0]),    // upper and lower 32 bits should be identical
    .data_tuser(chirp_tuning_word_coeff),
    .dataMagSq(sq_mag_axis_tdata),
    .dataMag_tvalid(sq_mag_axis_tvalid),
    .dataMag_tlast(sq_mag_axis_tlast),
    .dataMag_tuser(sq_mag_axis_tuser),
    .dataMag_index(sq_mag_index),
    .overflow(sq_mag_axis_tdata_overflow)
);


freq_domain_lpf #(
    .DATA_LEN(64)
) freq_lpf_corr(
     .clk(aclk),
     .aresetn(aresetn),
     .tdata(sq_mag_axis_tdata),
     .tvalid(sq_mag_axis_tvalid),
     .tlast(sq_mag_axis_tlast),
     .tuser(sq_mag_axis_tuser),
     .index(sq_mag_index),
     .cutoff(lpf_cutoff_ind),
     .lpf_index(lpf_index),
     .lpf_tdata(lpf_tdata),
     .lpf_tvalid(lpf_tvalid),
     .lpf_tlast(lpf_tlast),
     .lpf_tuser(lpf_tuser)
   );


peak_finder #(
  .DATA_LEN(64)
) peak_finder_corr(
  .clk(aclk),
  .aresetn(aresetn),
//      .tdata(sq_mag_i_axis_tdata),
//      .tvalid(sq_mag_i_axis_tvalid),
//      .tlast(sq_mag_i_axis_tlast),
//      .tuser(sq_mag_i_axis_tuser),
//      .index(sq_mag_i_index),
  .tdata(lpf_tdata),
  .tvalid(lpf_tvalid),
  .tlast(lpf_tlast),
  .tuser(lpf_tuser),
  .index(lpf_index),
  .threshold(peak_threshold),
  .peak_index(peak_index),
  .peak_tdata(peak_tdata),
  .peak_tvalid(peak_tvalid),
  .peak_tlast(peak_tlast),
  .peak_tuser(peak_tuser),
  .num_peaks(num_peaks)
);


cmpy_16b corr_complex_mult (
  .aclk(aclk),                              // input wire aclk
  .s_axis_a_tvalid(m_fft_dac_axis_tvalid),        // input wire s_axis_a_tvalid
  .s_axis_a_tready(m_fft_dac_axis_tready),
  .s_axis_a_tuser(m_fft_dac_index),          // input wire [31 : 0] s_axis_a_tuser
  .s_axis_a_tlast(m_fft_dac_axis_tlast),          // input wire s_axis_a_tlast
  .s_axis_a_tdata({m_fft_dac_conj_q_axis_tdata,m_fft_dac_conj_i_axis_tdata}),          // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(m_fft_adc_axis_tvalid),        // input wire s_axis_b_tvalid
  .s_axis_b_tready(m_fft_adc_axis_tready),
  .s_axis_b_tuser(m_fft_adc_index),          // input wire [31 : 0] s_axis_b_tuser
  .s_axis_b_tlast(m_fft_adc_axis_tlast),          // input wire s_axis_b_tlast
  .s_axis_b_tdata(m_fft_adc_axis_tdata),          // input wire [31 : 0] s_axis_b_tdata
  .m_axis_dout_tvalid(m_cmpy_axis_tvalid),  // output wire m_axis_dout_tvalid
  .m_axis_dout_tready(m_cmpy_axis_tready),
  .m_axis_dout_tuser(m_cmpy_index),    // output wire [63 : 0] m_axis_dout_tuser
  .m_axis_dout_tlast(m_cmpy_axis_tlast),    // output wire m_axis_dout_tlast
  .m_axis_dout_tdata(m_cmpy_axis_tdata)    // output wire [63 : 0] m_axis_dout_tdata
);

assign m_fft_dac_conj_i_axis_tdata = m_fft_dac_axis_tdata[15:0];
assign m_fft_dac_conj_q_axis_tdata = -m_fft_dac_axis_tdata[31:16];

fft_corr #(
  .FFT_DIRECTION(1),
  .FFT_LEN(FFT_LEN),
  .FFT_CHANNELS(1),
  .FFT_AXI_DATA_WIDTH (32),
  .FFT_RUNTIME_CONFIG (0),
  .SIMULATION(SIMULATION)
  )
  fft_corr_dac(

  .aclk (aclk),
  .aresetn (aresetn),

 .s_axis_tdata(s_fft_dac_axis_tdata),
 .s_axis_tvalid (s_fft_dac_axis_tvalid),
 .s_axis_tlast(s_fft_dac_axis_tlast),
 .s_axis_tready(s_fft_dac_axis_tready),

.m_axis_tdata(m_fft_dac_axis_tdata),
.m_axis_tvalid(m_fft_dac_axis_tvalid),
.m_axis_tlast(m_fft_dac_axis_tlast),
.m_axis_tready(m_fft_dac_axis_tready),

.m_index(m_fft_dac_index),

   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable)

);

fft_corr #(
  .FFT_DIRECTION(1),
  .FFT_LEN(FFT_LEN),
  .FFT_CHANNELS(1),
  .FFT_AXI_DATA_WIDTH (32),
  .FFT_RUNTIME_CONFIG (0),
  .SIMULATION(SIMULATION)
  )
  fft_corr_adc(

  .aclk (aclk),
  .aresetn (aresetn),

  .s_axis_tdata(s_fft_adc_axis_tdata),
  .s_axis_tvalid (s_fft_adc_axis_tvalid),
  .s_axis_tlast(s_fft_adc_axis_tlast),
  .s_axis_tready(s_fft_adc_axis_tready),

 .m_axis_tdata(m_fft_adc_axis_tdata),
 .m_axis_tvalid(m_fft_adc_axis_tvalid),
 .m_axis_tlast(m_fft_adc_axis_tlast),
 .m_axis_tready(m_fft_adc_axis_tready),

.m_index(m_fft_adc_index),

   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable)

);

assign m_ifft_axis_tready = 1'b1;
fft_corr #(
  .FFT_DIRECTION(0),
  .FFT_LEN(FFT_LEN),
  .FFT_CHANNELS(1),
  .FFT_AXI_DATA_WIDTH (64),
  .FFT_RUNTIME_CONFIG (0),
  .SIMULATION(SIMULATION)
  )
  ifft_corr(

  .aclk (aclk),
  .aresetn (aresetn),

 .s_axis_tdata(m_cmpy_axis_tdata),
 .s_axis_tvalid(m_cmpy_axis_tvalid),
 .s_axis_tlast(m_cmpy_axis_tlast),
 .s_axis_tready(m_cmpy_axis_tready),

 .m_axis_tdata(m_ifft_axis_tdata),
 .m_axis_tvalid(m_ifft_axis_tvalid),
 .m_axis_tlast(m_ifft_axis_tlast),
 .m_axis_tready(m_ifft_axis_tready),

 .m_index(m_ifft_index),

   .chirp_ready                         (chirp_ready),
   .chirp_done                          (chirp_done),
   .chirp_active                        (chirp_active),
   .chirp_init                          (chirp_init),
   .chirp_enable                        (chirp_enable),
   .adc_enable                          (adc_enable)

);





   endmodule
