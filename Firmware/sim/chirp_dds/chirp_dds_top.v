`timescale 1ps/1ps

module chirp_dds_top #
  (
     parameter ADC_AXI_DATA_WIDTH = 512,
     parameter ADC_AXI_TID_WIDTH = 1,
     parameter ADC_AXI_TDEST_WIDTH = 1,
     parameter ADC_AXI_TUSER_WIDTH = 1,
     parameter ADC_AXI_STREAM_ID = 1'b0,
     parameter ADC_AXI_STREAM_DEST = 1'b0,

     parameter FFT_LEN = 32768,
     parameter SIMULATION = 0

   )
  (

   input    aclk, // AXI input clock
   input    aresetn, // Active low AXI reset signal

 // --KC705 Resources - from fmc150 example design
 input clk_245,
 input clk_245_rst,
 input cpu_reset,       // : in    std_logic; -- CPU RST button, SW7 on KC705
 // input sysclk_p,        // : in    std_logic;
 // input sysclk_n,        // : in    std_logic;
   // --ADC Data Out Signals
  output [ADC_AXI_DATA_WIDTH-1:0]     axis_adc_tdata,
  output axis_adc_tvalid,
  output axis_adc_tlast,
  output [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tkeep,
  output [ADC_AXI_DATA_WIDTH/8-1:0]   axis_adc_tstrb,
  output [ADC_AXI_TID_WIDTH-1:0] axis_adc_tid,
  output [ADC_AXI_TDEST_WIDTH-1:0] axis_adc_tdest,
  output [ADC_AXI_TUSER_WIDTH-1:0] axis_adc_tuser,
  input axis_adc_tready,

  input                                 wf_read_ready,
  input       [31:0]                    wfrm_axis_tdata,
  input                                 wfrm_axis_tvalid,
  input                                 wfrm_axis_tlast,
  output                                wfrm_axis_tready,

// Control Module signals
  output [3:0] fmc150_status_vector,
  output chirp_ready,
  output chirp_done,
  output chirp_active,
  input  chirp_init,
  input  chirp_enable,
  input  adc_enable,

  input [31:0] chirp_control_word,
  input [31:0] chirp_freq_offset,
  input [31:0] chirp_tuning_word_coeff,
  input [31:0] chirp_count_max,

  input [7:0] fmc150_ctrl_bus,
  input [67:0] fmc150_spi_ctrl_bus_in,
  output [47:0] fmc150_spi_ctrl_bus_out


   );

   localparam DDS_LATENCY = 2;
   localparam DDS_CHIRP_DELAY = 3;
   localparam DDS_WFRM_DELAY = 19;
   localparam DDS_WFRM_DELAY_END = 2;
   localparam FCUTOFF_IND = FFT_LEN/2;
   localparam ADC_DELAY = 100;

   integer d;

  wire rd_fifo_clk;
  wire clk_245_76MHz;
  wire clk_491_52MHz;

  wire [15:0] adc_data_i;
  wire [15:0] adc_data_q;
 wire [15:0] dac_data_i;
  wire [15:0] dac_data_q;

  wire [31:0] adc_data_iq;
  wire [31:0] dac_data_iq;
  wire data_valid;

  wire [31:0] adc_counter;
  wire adc_data_valid;

  wire [15:0] wfrm_data_i;
  wire [15:0] wfrm_data_q;
  wire wfrm_data_valid;


  reg [15:0] adc_data_i_r;
  reg [15:0] adc_data_q_r;
  reg [15:0] adc_data_i_rr;
  reg [15:0] adc_data_q_rr;
  reg [15:0] dac_data_i_r;
  reg [15:0] dac_data_q_r;
  reg [15:0] dac_data_i_rr;
  reg [15:0] dac_data_q_rr;

  reg [31:0] adc_counter_reg;
  reg adc_data_valid_r;
  reg adc_data_valid_rr;

  reg [15:0] adc_data_i_delay [ADC_DELAY-1:0];
  reg [15:0] adc_data_q_delay [ADC_DELAY-1:0];

  wire [63:0] adc_fifo_wr_tdata;
  wire       adc_fifo_wr_tvalid;
  wire       adc_fifo_wr_tlast;
  wire       adc_fifo_wr_pre_tlast;
  wire       adc_fifo_wr_first;
  reg        adc_fifo_wr_first_r;


  wire [15:0] dds_out_i;
  wire [15:0] dds_out_q;
  wire dds_out_valid;

  wire [31:0] data_out_lower;
  wire [31:0] data_out_upper;
   reg [31:0] data_out_lower_r;
  reg [31:0] data_out_upper_r;
//  reg data_out_lower_valid;
//  reg data_out_upper_valid;
  reg [7:0] dds_latency_counter;
  reg [63:0] glbl_counter_reg;
  wire [63:0] glbl_counter;

  reg [5:0] data_alignment_counter;
 reg [5:0] data_word_counter;

 wire align_data;

  wire [1:0] dds_route_ctrl_l;
  wire [1:0] dds_route_ctrl_u;
  wire [1:0] dds_source_ctrl;
  wire dds_source_select;

  wire wfrm_ready;
  wire wfrm_done;
  wire wfrm_active;
  wire wfrm_init;
  wire wfrm_enable;

  wire dds_ready;
  wire dds_done;
  wire dds_active;
  wire dds_init;
  wire dds_enable;

  reg [1:0] dds_route_ctrl_u_r;
  reg [1:0] dds_route_ctrl_l_r;
  reg [1:0] dds_source_ctrl_r;

  reg [ADC_AXI_DATA_WIDTH-1:0]     chirp_header;
  reg [7:0]  chirp_header_counter;
  reg chirp_init_r;
  reg chirp_init_rr;



     wire [12:0]              adc_fifo_wr_tdata_count;
     wire [9:0]               adc_fifo_rd_data_count;
     wire                       adc_fifo_wr_ack;
     wire                       adc_fifo_valid;
     wire                       adc_fifo_almost_full;
     wire                       adc_fifo_almost_empty;
     wire                      adc_fifo_wr_en;
     wire                      adc_fifo_rd_en;
     wire [ADC_AXI_DATA_WIDTH-1:0]  adc_fifo_data_out;
     wire [ADC_AXI_DATA_WIDTH-1:0]  adc_fifo_data_out_reversed;
     wire                     adc_fifo_full;
     wire                     adc_fifo_empty;

     reg                      adc_enable_r;
     reg                      adc_enable_rr;

    //  wire [63:0] s_fft_i_axis_tdata;
    //  wire s_fft_i_axis_tvalid;
    //  wire s_fft_i_axis_tlast;
    //  wire s_fft_i_axis_tready;
     //
    //  wire [63:0] s_fft_q_axis_tdata;
    //  wire s_fft_q_axis_tvalid;
    //  wire s_fft_q_axis_tlast;
    //  wire s_fft_q_axis_tready;
     //
    //  wire [63:0] m_fft_i_axis_tdata;
    //  wire m_fft_i_axis_tvalid;
    //  wire m_fft_i_axis_tlast;
    //  wire m_fft_i_axis_tready;
    //  wire [31:0] m_fft_i_index;
     //
    //  wire [63:0] m_fft_q_axis_tdata;
    //  wire m_fft_q_axis_tvalid;
    //  wire m_fft_q_axis_tlast;
    //  wire m_fft_q_axis_tready;
    //  wire [31:0] m_fft_q_index;
     //
    //  wire [31:0] mixer_out_i;
    //  wire [31:0] mixer_out_q;
     //
    //  wire [31:0] mag_i_axis_tdata;
    //  wire [31:0] mag_q_axis_tdata;
     //
    //  wire [63:0] sq_mag_i_axis_tdata;
    //  wire        sq_mag_i_axis_tvalid;
    //  wire        sq_mag_i_axis_tlast;
    //  wire [63:0] sq_mag_q_axis_tdata;
    //  wire        sq_mag_q_axis_tvalid;
    //  wire        sq_mag_q_axis_tlast;
    //  wire       sq_mag_i_axis_tdata_overflow;
    //  wire       sq_mag_q_axis_tdata_overflow;
    //  wire [31:0] sq_mag_i_axis_tuser;
    //  wire [31:0] sq_mag_q_axis_tuser;
    //  wire [31:0] sq_mag_i_index;
    //  wire [31:0] sq_mag_q_index;
     //
    //  wire [31:0] peak_index_i;
    //  wire [63:0] peak_tdata_i;
    //  wire peak_tvalid_i;
    //  wire peak_tlast_i;
    //  wire [31:0] peak_tuser_i;
    //  wire [31:0] num_peaks_i;
     //
    //  wire [31:0] peak_index_q;
    //  wire [63:0] peak_tdata_q;
    //  wire peak_tvalid_q;
    //  wire peak_tlast_q;
    //  wire [31:0] peak_tuser_q;
    //  wire [31:0] num_peaks_q;
     //
    //  reg [31:0] peak_result_i;
    //  reg [31:0] peak_result_q;
    //  reg [63:0] peak_val_i;
    //  reg [31:0] peak_num_i;
    //  reg [63:0] peak_val_q;
    //  reg [31:0] peak_num_q;
    //  reg new_peak_i;
    //  reg new_peak_q;
     //
    //  wire [63:0] lpf_tdata_i;
    //  wire lpf_tvalid_i;
    //  wire lpf_tlast_i;
    //  wire [31:0] lpf_tuser_i;
    //  wire [31:0] lpf_index_i;
     //
    //  wire [63:0] lpf_tdata_q;
    //  wire lpf_tvalid_q;
    //  wire lpf_tlast_q;
    //  wire [31:0] lpf_tuser_q;
    //  wire [31:0] lpf_index_q;

     wire [31:0] lpf_cutoff_ind;
      wire [63:0] peak_threshold_i;
      wire [63:0] peak_threshold_q;

     wire [511:0] dw_axis_tdata;
     wire dw_axis_tvalid;
     wire dw_axis_tlast;
     wire dw_axis_tready;

    //  reg dw_axis_tvalid_r;
    //  reg dw_axis_tlast_r;

    wire data_iq_tvalid;
    wire data_iq_tlast;
    wire data_iq_first;
    wire[63:0] data_counter_id;
    wire[7:0] threshold_ctrl_i;
    wire[7:0] threshold_ctrl_q;


     assign clk_245_76MHz = clk_245;
     // simulate adc outputs from fmc150 module with dds loopback
//     always @(posedge clk_245_76MHz) begin
//        adc_data_i_r <= dac_data_i_rr;
//        adc_data_q_r <= dac_data_q_rr;
//        adc_data_valid_r <= dds_out_valid;
//        adc_data_i_rr <= adc_data_i_r;
//        adc_data_q_rr <= adc_data_q_r;
//        adc_data_valid_rr <= adc_data_valid_r;
//     end
 always @(posedge clk_245_76MHz) begin
    if (clk_245_rst)
        adc_data_valid_rr <= 1'b0;
    else
       adc_data_valid_rr <= 1'b1;
 end

always @(posedge clk_245_76MHz) begin
     if (clk_245_rst) begin
         adc_data_i_delay[0] <= 'b0;
         adc_data_q_delay[0] <= 'b0;
     end else begin
        // Divide adc sample magnitudes by 2
        adc_data_i_delay[0] <= {dac_data_i_rr[15],dac_data_i_rr[15:1]};
        adc_data_q_delay[0] <= {dac_data_q_rr[15],dac_data_q_rr[15:1]};
    end
end
 always @(posedge clk_245_76MHz) begin
    for (d=1;d<ADC_DELAY;d=d+1) begin
        if (clk_245_rst) begin
            adc_data_i_delay[d] <= 'b0;
            adc_data_q_delay[d] <= 'b0;
        end else begin
            adc_data_i_delay[d] <= adc_data_i_delay[d-1];
            adc_data_q_delay[d] <= adc_data_q_delay[d-1];
        end
    end
end


     // simulate number of register stages in fmc150 module for dac (2)
     always @(posedge clk_245_76MHz) begin
        dac_data_i_r <= dds_out_i;
        dac_data_q_r <= dds_out_q;
        dac_data_i_rr <= dds_out_i;
        dac_data_q_rr <= dds_out_q;

     end

     always @(posedge clk_245_76MHz) begin
      if (cpu_reset) begin
        adc_counter_reg <= 'b0;
      end
      else begin
        if (adc_enable_rr & adc_data_valid_rr)
          adc_counter_reg <= adc_counter_reg+1;
      end
     end

     always @(posedge clk_245_76MHz) begin
      if (cpu_reset) begin
        glbl_counter_reg <= 'b0;
      end
      else begin
        glbl_counter_reg <= glbl_counter_reg+1;
      end
     end

     assign adc_data_iq = {adc_data_i,adc_data_q};
     assign dac_data_iq = {dac_data_i,dac_data_q};
     assign adc_data_valid = adc_data_valid_rr;
     assign data_valid = adc_data_valid_rr;
//     assign adc_data_i = adc_data_i_rr;
//     assign adc_data_q = adc_data_q_rr;
     assign adc_data_i = adc_data_i_delay[ADC_DELAY-1];
     assign adc_data_q = adc_data_q_delay[ADC_DELAY-1];

     assign dac_data_i = dac_data_i_rr;
     assign dac_data_q = dac_data_q_rr;


     assign adc_counter = adc_counter_reg;
     assign fmc150_spi_ctrl_bus_out = 'b0;
     assign fmc150_status_vector = 4'b1111;

     assign glbl_counter = glbl_counter_reg;



     CHIRP_DDS #(
     .DDS_LATENCY(DDS_LATENCY)
     ) u_chirp_dds(
         .CLOCK(clk_245),
         .RESET(clk_245_rst),
         .IF_OUT_I(dds_out_i),
         .IF_OUT_Q(dds_out_q),
         .IF_OUT_VALID(dds_out_valid),

         .chirp_ready (dds_ready),
         .chirp_done  (dds_done),
         .chirp_active (dds_active),
         .chirp_init  (dds_init),
         .chirp_enable (dds_enable),

         .freq_offset_in          (chirp_freq_offset),
         .tuning_word_coeff_in    (chirp_tuning_word_coeff),
         .chirp_count_max_in      (chirp_count_max)

     );

  assign dds_route_ctrl_l = chirp_control_word[1:0];
  assign dds_route_ctrl_u = chirp_control_word[5:4];


//  always @(dds_route_ctrl_l or adc_data_iq or dac_data_iq or adc_counter or glbl_counter  ) begin
//    case (dds_route_ctrl_l)
//    2'b00: data_out_lower_r = adc_data_iq;
//    2'b01: data_out_lower_r = dac_data_iq;
//    2'b10: data_out_lower_r = adc_counter;
//    2'b11: data_out_lower_r = glbl_counter;
//    default: data_out_lower_r = adc_data_iq;
//    endcase
//  end

// always @(dds_route_ctrl_u or adc_data_iq or dac_data_iq or adc_counter or glbl_counter  ) begin
//    case (dds_route_ctrl_u)
//    2'b00: data_out_upper_r = adc_data_iq;
//    2'b01: data_out_upper_r = dac_data_iq;
//    2'b10: data_out_upper_r = adc_counter;
//    2'b11: data_out_upper_r = glbl_counter;
//    default: data_out_upper_r = adc_counter;
//    endcase
//  end
//  assign data_out_lower = data_out_lower_r;
//  assign data_out_upper = data_out_upper_r;

//assign wfrm_init = (dds_source_select) ? chirp_init : 1'b0;
//assign dds_init = (!dds_source_select) ? chirp_init : 1'b0;
//assign wfrm_enable = (dds_source_select) ? chirp_enable : 1'b0;
//assign dds_enable = (!dds_source_select) ? chirp_enable : 1'b0;

assign wfrm_init = (dds_source_select & chirp_init);
assign dds_init = (!dds_source_select & chirp_init);
assign wfrm_enable = (dds_source_select & chirp_enable);
assign dds_enable = (!dds_source_select & chirp_enable);

assign chirp_done = ((dds_source_select & wfrm_done)|(!dds_source_select & dds_done));
assign chirp_active = ((dds_source_select & wfrm_active)|(!dds_source_select & dds_active));
assign chirp_ready =  ((dds_source_select & wfrm_ready)|(!dds_source_select & dds_ready));

assign dds_source_select = (&dds_source_ctrl);

assign data_out_lower  = (dds_route_ctrl_l == 2'b00) ? adc_data_iq : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b01) ? dac_data_iq : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b10) ? adc_counter : 32'bz,
    data_out_lower  = (dds_route_ctrl_l == 2'b11) ? glbl_counter : 32'bz;

assign data_out_upper  = (dds_route_ctrl_u == 2'b00) ? adc_data_iq : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b01) ? dac_data_iq : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b10) ? adc_counter : 32'bz,
          data_out_upper  = (dds_route_ctrl_u == 2'b11) ? glbl_counter : 32'bz;

//assign dds_route_ctrl_l = chirp_control_word[1:0];
//assign dds_route_ctrl_u = chirp_control_word[5:4];
assign dds_route_ctrl_l = dds_route_ctrl_l_r;
assign dds_route_ctrl_u = dds_route_ctrl_u_r;
assign dds_source_ctrl = dds_source_ctrl_r;


  always @(posedge clk_245_76MHz) begin
     dds_route_ctrl_l_r <= chirp_control_word[1:0];
     dds_route_ctrl_u_r <= chirp_control_word[5:4];
  end

  always @(posedge clk_245_76MHz) begin
     if (!chirp_enable)
         dds_source_ctrl_r <= chirp_control_word[9:8];
  end


   always @(posedge clk_245_76MHz) begin
    if (cpu_reset) begin
      adc_enable_r <= 1'b0;
      adc_enable_rr <= 1'b0;
    end else begin
      adc_enable_r <= adc_enable;
      if (!(|dds_latency_counter) & !align_data)
        adc_enable_rr <= adc_enable_r;
      else
        adc_enable_rr <=adc_enable_rr;
    end
   end


   always @(posedge clk_245_76MHz) begin
     if (clk_245_rst)
       dds_latency_counter <= 'b0;
     else if( chirp_init) begin
         if(dds_source_select )
             dds_latency_counter <= DDS_WFRM_DELAY;
          else
             dds_latency_counter <= DDS_CHIRP_DELAY;
    end else if(adc_enable_r & !adc_enable) begin
       if(dds_source_select )
         // dds_latency_counter <= DDS_WFRM_DELAY;
         dds_latency_counter <= DDS_WFRM_DELAY_END;
       else
         dds_latency_counter <= DDS_CHIRP_DELAY;
    end else if(|dds_latency_counter) begin
       dds_latency_counter <= dds_latency_counter-1;
    end
   end

  always @(posedge clk_245_76MHz) begin
    if (clk_245_rst)
      data_word_counter <= 'b0;
   else if (!(|dds_latency_counter)&(adc_enable_r)&(!adc_enable_rr))
      data_word_counter <= 'b0;
    else if(adc_enable_rr & adc_data_valid)
      data_word_counter <= data_word_counter + 1'b1;
  end

   always @(posedge clk_245_76MHz) begin
      if (clk_245_rst)
        data_alignment_counter <= 'b0;
     else if(adc_fifo_wr_pre_tlast)
        data_alignment_counter <= (data_word_counter+1'b1)^6'b111111;
      else if(|data_alignment_counter)
        data_alignment_counter <= data_alignment_counter - 1'b1;
    end

    assign align_data = |data_alignment_counter;


   always @(posedge clk_245_76MHz) begin
    if (cpu_reset) begin
      adc_fifo_wr_first_r <= 1'b0;
    end else begin
      if (!(|dds_latency_counter)&(adc_enable_r)&(!adc_enable_rr))
        adc_fifo_wr_first_r <= 1'b1;
      else
        adc_fifo_wr_first_r <= 1'b0;
    end
   end


   always @(posedge clk_245_76MHz) begin
    if (cpu_reset)
      chirp_header_counter <= 'b0;
     else if (chirp_init)
      chirp_header_counter <= ADC_AXI_DATA_WIDTH/64-1;
     else if (|chirp_header_counter)
      chirp_header_counter <= chirp_header_counter-1;
    end

    always @(posedge clk_245_76MHz) begin
     if (cpu_reset)
       chirp_init_r <= 1'b0;
     else if (chirp_init)
       chirp_init_r <= chirp_init;
    else if (!(|chirp_header_counter))
       chirp_init_r <= 1'b0;
    end

    always @(posedge clk_245_76MHz) begin
     if (cpu_reset)
       chirp_init_rr <= 1'b0;
     else if (!(|chirp_header_counter))
       chirp_init_rr <= chirp_init_r;
    end

    always @(posedge clk_245_76MHz) begin
     if (cpu_reset)
       chirp_header <= 'b0;
     else if (chirp_init_r)
       chirp_header[64+64*chirp_header_counter-1-:64] <= glbl_counter;
    end


    waveform_dds waveform_dds_inst(
        .axi_tclk(clk_245_76MHz),
        .axi_tresetn(!clk_245_rst),
        .wf_read_ready(wf_read_ready),

        .chirp_ready (wfrm_ready),
        .chirp_done (wfrm_done),
        .chirp_active (wfrm_active),
        .chirp_init  (wfrm_init),
        .chirp_enable  (wfrm_enable),

        .dds_source_select(dds_source_select),

        .wfrm_axis_tdata(wfrm_axis_tdata),
        .wfrm_axis_tvalid(wfrm_axis_tvalid),
        .wfrm_axis_tlast(wfrm_axis_tlast),
        .wfrm_axis_tready(wfrm_axis_tready),

        .wfrm_data_valid(wfrm_data_valid),
        .wfrm_data_i(wfrm_data_i),
        .wfrm_data_q(wfrm_data_q)
    );
// asynchoronous fifo for converting 245.76 MHz 32 bit adc samples (16 i, 16 q)
// to rd clk domain 64 bit adc samples (i1 q1 i2 q2)
   fifo_generator_adc u_fifo_generator_adc
   (
   .wr_clk                    (clk_245_76MHz),
   .rd_clk                    (rd_fifo_clk),
   .wr_data_count             (adc_fifo_wr_tdata_count),
   .rd_data_count             (adc_fifo_rd_data_count),
   .wr_ack                    (adc_fifo_wr_ack),
   .valid                     (adc_fifo_valid),
   .almost_full               (adc_fifo_almost_full),
   .almost_empty              (adc_fifo_almost_empty),
   .rst                       (cpu_reset),
   //.wr_en                     (adc_fifo_wr_en),
   .wr_en                     (adc_fifo_wr_en),
   //.rd_en                     (adc_fifo_rd_en),
   .rd_en                     (adc_fifo_rd_en),
   .din                       (adc_fifo_wr_tdata),
   .dout                      (adc_fifo_data_out),
   .full                      (adc_fifo_full),
   .empty                     (adc_fifo_empty)

   );

   genvar i;
   generate
   for (i=0;i<ADC_AXI_DATA_WIDTH;i=i+64) begin
      assign adc_fifo_data_out_reversed[i+63-:64] = adc_fifo_data_out[ADC_AXI_DATA_WIDTH-i-1-:64];
   end
   endgenerate

   adc_data_axis_wrapper #(
     .ADC_AXI_DATA_WIDTH(ADC_AXI_DATA_WIDTH),
     .ADC_AXI_TID_WIDTH(ADC_AXI_TID_WIDTH),
     .ADC_AXI_TDEST_WIDTH(ADC_AXI_TDEST_WIDTH),
     .ADC_AXI_TUSER_WIDTH(ADC_AXI_TUSER_WIDTH),
     .ADC_AXI_STREAM_ID(ADC_AXI_STREAM_ID),
     .ADC_AXI_STREAM_DEST(ADC_AXI_STREAM_DEST)
    )
    adc_data_axis_wrapper_inst (
      .axi_tclk                   (aclk),
      .axi_tresetn                (aresetn),
      // .adc_data                   (adc_fifo_data_out),
      .adc_data                   (adc_fifo_data_out_reversed),
      .adc_fifo_data_valid        (adc_fifo_valid),
      .adc_fifo_empty             (adc_fifo_empty),
      .adc_fifo_almost_empty      (adc_fifo_almost_empty),
      .adc_fifo_rd_en             (adc_fifo_rd_en),

      .tdata                      (axis_adc_tdata),
      .tvalid                     (axis_adc_tvalid),
      .tlast                      (axis_adc_tlast),
      .tkeep                      (axis_adc_tkeep),
      .tstrb                      (axis_adc_tstrb),
      .tid                        (axis_adc_tid),
      .tdest                      (axis_adc_tdest),
      .tuser                      (axis_adc_tuser),
      .tready                     (axis_adc_tready)
      );

//   assign adc_data_iq = {adc_data_i,adc_data_q};
//   assign adc_fifo_wr_tdata = {adc_counter,adc_data_iq};
//   assign adc_fifo_wr_tvalid = adc_data_valid & adc_enable_rr;

assign adc_fifo_wr_tdata  = (adc_fifo_wr_first | adc_fifo_wr_tlast) ? {glbl_counter[31:0],adc_counter} : {data_out_upper,data_out_lower};

//assign adc_fifo_wr_tdata = {data_out_upper,data_out_lower};

//   assign adc_fifo_wr_tvalid = data_out_upper_valid & data_out_lower_valid & adc_enable_rr;
    assign adc_fifo_wr_tvalid = data_valid & adc_enable_rr;

   assign adc_fifo_wr_first = adc_fifo_wr_first_r;

   assign adc_fifo_wr_tlast = (!(|dds_latency_counter))&(adc_enable_rr)&(!adc_enable_r)&(!align_data);

   assign adc_fifo_wr_pre_tlast = (dds_latency_counter==1)&(adc_enable_rr)&(!adc_enable_r);

//   assign adc_fifo_wr_en = adc_enable_rr & adc_data_valid;
 //  assign adc_fifo_wr_en = adc_enable_rr & data_out_upper_valid & data_out_lower_valid;
    assign adc_fifo_wr_en = adc_enable_rr & data_valid;



assign rd_fifo_clk = aclk;

//assign clk_out_491_52MHz = clk_491_52MHz;

assign data_iq_tvalid = adc_enable_rr & adc_data_valid & (!adc_fifo_wr_first) & (!adc_fifo_wr_tlast)&(!align_data);
//assign data_iq_tvalid = adc_enable_rr & adc_data_valid & (!adc_fifo_wr_first);
assign data_iq_tlast = (dds_latency_counter==1)&(adc_enable_rr)&(!adc_enable_r);
assign data_iq_first = adc_fifo_wr_first_r;
assign data_counter_id = {glbl_counter[31:0],adc_counter};
assign dw_axis_tready = glbl_counter[4] | glbl_counter[1]; //1'b1;
assign lpf_cutoff_ind = 2048; //FCUTOFF_IND;
assign threshold_ctrl_i = {4'hf,4'h1};
assign threshold_ctrl_q = {4'hf,4'h1};
//assign peak_threshold_i = {{(60-4*threshold_ctrl_i[7:4]){1'b0}},threshold_ctrl_i[3:0],{(4*threshold_ctrl_i[7:4]){1'b0}}};
//assign peak_threshold_q = {{(60-4*threshold_ctrl_q[7:4]){1'b0}},threshold_ctrl_q[3:0],{(4*threshold_ctrl_q[7:4]){1'b0}}};

// matched_filter_range_detector #
//   (
//      .PK_AXI_DATA_WIDTH(512),
//      .PK_AXI_TID_WIDTH (1),
//      .PK_AXI_TDEST_WIDTH(1),
//      .PK_AXI_TUSER_WIDTH(1),
//      .PK_AXI_STREAM_ID (1'b0),
//      .PK_AXI_STREAM_DEST (1'b0),
//      .FFT_LEN(4096),
//      .SIMULATION(SIMULATION)
//
//   )matched_filter_range_detector_inst(
//
//    .aclk(clk_245_76MHz), // AXI input clock
//    .aresetn(!clk_245_rst), // Active low AXI reset signal
//
//    // --ADC Data Out Signals
//   .adc_iq_tdata(adc_data_iq),
//   .dac_iq_tdata(dac_data_iq),
//   .iq_tvalid(data_iq_tvalid),
//   .iq_tlast(data_iq_tlast),
//   .iq_tready(data_iq_tready),
//   .iq_first(data_iq_first),
//   .counter_id(data_counter_id),
//
//   .pk_axis_tdata(dw_axis_tdata),
//   .pk_axis_tvalid(dw_axis_tvalid),
//   .pk_axis_tlast(dw_axis_tlast),
//   .pk_axis_tkeep(),
//   .pk_axis_tdest(),
//   .pk_axis_tid(),
//   .pk_axis_tstrb(),
//   .pk_axis_tuser(),
//   .pk_axis_tready(dw_axis_tready),
//
//   .lpf_cutoff(lpf_cutoff_ind),
//   .threshold_ctrl(threshold_ctrl_i),    // {4b word index, 4b word value} in 64bit threshold
//  // .threshold_ctrl(threshold_ctrl_q),    // {4b word index, 4b word value} in 64bit threshold
//
// // Control Module signals
//  .chirp_ready                         (chirp_ready),
//  .chirp_done                          (chirp_done),
//  .chirp_active                        (chirp_active),
//  .chirp_init                          (chirp_init),
//  .chirp_enable                        (chirp_enable),
//  .adc_enable                          (adc_enable),
//  .chirp_control_word          (chirp_control_word),
//  .chirp_freq_offset           (chirp_freq_offset),
//  .chirp_tuning_word_coeff     (chirp_tuning_word_coeff),
//  .chirp_count_max             (chirp_count_max)
//
//    );

/*
dsp_range_detector #
  (
     .PK_AXI_DATA_WIDTH(512),
     .PK_AXI_TID_WIDTH (1),
     .PK_AXI_TDEST_WIDTH(1),
     .PK_AXI_TUSER_WIDTH(1),
     .PK_AXI_STREAM_ID (1'b0),
     .PK_AXI_STREAM_DEST (1'b0),
     .FFT_LEN(FFT_LEN),
     .SIMULATION(SIMULATION)

  )dsp_range_detector_inst(

   .aclk(clk_245_76MHz), // AXI input clock
   .aresetn(!clk_245_rst), // Active low AXI reset signal

   // --ADC Data Out Signals
  .adc_iq_tdata(adc_data_iq),
  .dac_iq_tdata(dac_data_iq),
  .iq_tvalid(data_iq_tvalid),
  .iq_tlast(data_iq_tlast),
  .iq_tready(data_iq_tready),
  .iq_first(data_iq_first),
  .counter_id(data_counter_id),

  .pk_axis_tdata(dw_axis_tdata),
  .pk_axis_tvalid(dw_axis_tvalid),
  .pk_axis_tlast(dw_axis_tlast),
  .pk_axis_tkeep(),
  .pk_axis_tdest(),
  .pk_axis_tid(),
  .pk_axis_tstrb(),
  .pk_axis_tuser(),
  .pk_axis_tready(dw_axis_tready),

  .lpf_cutoff(lpf_cutoff_ind),
  .threshold_ctrl_i(threshold_ctrl_i),    // {4b word index, 4b word value} in 64bit threshold
  .threshold_ctrl_q(threshold_ctrl_q),    // {4b word index, 4b word value} in 64bit threshold

// Control Module signals
 .chirp_ready                         (chirp_ready),
 .chirp_done                          (chirp_done),
 .chirp_active                        (chirp_active),
 .chirp_init                          (chirp_init),
 .chirp_enable                        (chirp_enable),
 .adc_enable                          (adc_enable),
 .chirp_control_word          (chirp_control_word),
 .chirp_freq_offset           (chirp_freq_offset),
 .chirp_tuning_word_coeff     (chirp_tuning_word_coeff),
 .chirp_count_max             (chirp_count_max)

   );
*/


   endmodule
