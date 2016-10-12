`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 07/25/2016 10:31:34 PM
// Design Name:
// Module Name: peakfinder_sim
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


module peakfinder_sim(

    );
    localparam AXI_TCLK_PERIOD          = 10000;         // 100 MHz
    localparam GTX_TCLK_PERIOD          = 8000;         // 125 MHz
    localparam FMC_TCLK_PERIOD          = 4069;         // 245.76 MHz
    localparam RESET_PERIOD = 320000; //in pSec

    localparam THRESH_CTRL =  8'h08;
    
    
        reg axi_tresetn_i;
        reg axi_tclk_i;

        reg gtx_tresetn_i;
        reg gtx_tclk_i;

        reg fmc_tresetn_i;
        reg fmc_tclk_i;

        reg [7:0] counter;
        reg [7:0] index;
        reg [7:0] test_data;
        reg [7:0] test_offset;

           wire                   axi_tclk;
        wire                   axi_tresetn;

        wire                   gtx_tclk;
        wire                   gtx_tresetn;

        wire                   fmc_tclk;
        wire                   fmc_tresetn;

        wire [63:0] m_fft_i_axis_tdata;
        wire m_fft_i_axis_tvalid;
        wire m_fft_i_axis_tlast;
        wire m_fft_i_axis_tready;

        reg m_fft_i_axis_tvalid_r;
        reg m_fft_i_axis_tlast_r;

        wire [63:0] m_fft_q_axis_tdata;
        wire m_fft_q_axis_tvalid;
        wire m_fft_q_axis_tlast;
        wire m_fft_q_axis_tready;

        reg m_fft_q_axis_tvalid_r;
        reg m_fft_q_axis_tlast_r;

             wire [63:0] sq_mag_i_axis_tdata;
        wire        sq_mag_i_axis_tvalid;
        wire        sq_mag_i_axis_tlast;
        wire [31:0] sq_mag_i_axis_tuser;
        wire [31:0] sq_mag_i_index;
        wire [63:0] sq_mag_q_axis_tdata;
        wire        sq_mag_q_axis_tvalid;
        wire        sq_mag_q_axis_tlast;
        wire [31:0] sq_mag_q_axis_tuser;
        wire [31:0] sq_mag_q_index;
        wire       sq_mag_i_axis_tdata_overflow;
        wire       sq_mag_q_axis_tdata_overflow;

        wire [31:0] peak_index_i;
        wire [63:0] peak_tdata_i;
        wire peak_tvalid_i;
         wire peak_tlast_i;
        wire [31:0] peak_tuser_i;
        wire [31:0]num_peaks_i;

        wire [31:0] peak_index_q;
        wire [63:0] peak_tdata_q;
        wire peak_tvalid_q;
        wire peak_tlast_q;
        wire [31:0] peak_tuser_q;
        wire [31:0]num_peaks_q;

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

        wire [7:0] config_pkt_tdata;
        wire config_pkt_tvalid;
        wire config_pkt_tready;
        wire config_pkt_tlast;

        wire [7:0] pk_axis_tdata;
        wire pk_axis_tvalid;
        wire pk_axis_tlast;
        wire pk_axis_tready;
        wire pk_axis_tuser;

        wire [7:0] dwout_axis_tdata;
        wire dwout_axis_tvalid;
        wire dwout_axis_tlast;
        wire dwout_axis_tready;

        //wire [255:0] dw_axis_tdata;
        wire [255:0] dw_axis_tdata;
        wire dw_axis_tvalid;
        wire dw_axis_tlast;
        wire dw_axis_tready;

        reg dw_axis_tvalid_r;
        reg dw_axis_tlast_r;
        
        wire [63:0] peak_threshold_i;
        wire [63:0] peak_threshold_q;
        reg [63:0] peak_threshold_i_r;
        reg [63:0] peak_threshold_q_r;
        reg [63:0] new_peak_threshold_i_r;
        reg [63:0] new_peak_threshold_q_r;
        reg update_threshold;
        wire[7:0] threshold_ctrl_i;
        wire[7:0] threshold_ctrl_q;
        reg[7:0] threshold_ctrl_i_r;
        reg[7:0] threshold_ctrl_q_r;



     initial begin
          axi_tresetn_i = 1'b0;
          #RESET_PERIOD
            axi_tresetn_i = 1'b1;
         end

         initial begin
           gtx_tresetn_i = 1'b0;
           #RESET_PERIOD
             gtx_tresetn_i = 1'b1;
          end

          initial begin
            fmc_tresetn_i = 1'b0;
            #RESET_PERIOD
              fmc_tresetn_i = 1'b1;
           end

        //**************************************************************************//
        // Clock Generation
        //**************************************************************************//

        initial
          begin
              axi_tclk_i = 1'b0;
          end
        always
          begin
              axi_tclk_i = #(AXI_TCLK_PERIOD/2.0) ~axi_tclk_i;
          end

        initial
          begin
              gtx_tclk_i = 1'b0;
          end
        always
          begin
              gtx_tclk_i = #(GTX_TCLK_PERIOD/2.0) ~gtx_tclk_i;
          end

        initial
          begin
              fmc_tclk_i = 1'b0;
          end
        always
          begin
              fmc_tclk_i = #(FMC_TCLK_PERIOD/2.0) ~fmc_tclk_i;
          end

         assign axi_tresetn = axi_tresetn_i;
         assign axi_tclk = axi_tclk_i;

         assign gtx_tresetn = gtx_tresetn_i;
         assign gtx_tclk = gtx_tclk_i;

         assign fmc_tresetn = fmc_tresetn_i;
         assign fmc_tclk = fmc_tclk_i;

         initial begin
              repeat(4096) @(posedge fmc_tclk_i);
              $finish;
            end

            always @(posedge  fmc_tclk_i) begin
              if (~fmc_tresetn_i) begin
                   counter <= 'b0;
                  m_fft_i_axis_tvalid_r <= 1'b0;
                  m_fft_q_axis_tvalid_r<= 1'b0;
                  m_fft_i_axis_tlast_r <= 1'b0;
                  m_fft_q_axis_tlast_r <= 1'b0;
                  index <= 'b0;
                  test_data <= 'b0;
                  peak_result_i <= 'b0;
                  peak_val_i <= 'b0;
                  peak_num_i <= 'b0;
                  peak_result_q <= 'b0;
                  peak_val_q <= 'b0;
                  peak_num_q <= 'b0;
                  new_peak_i <= 1'b0;
                  new_peak_q <= 1'b0;
                  dw_axis_tvalid_r <= 1'b0;
                  dw_axis_tlast_r <= 1'b0;

                  test_offset <= 'b0;
                  
                  threshold_ctrl_i_r <= 8'h01;
                  threshold_ctrl_q_r <= 8'h0a;
                  update_threshold <= 0;

              end else begin
                  counter <= counter + 1'b1;
                  index <= counter;
                  if(counter <= 8'hcf)
                    test_data <= counter+test_offset;
                  else
                    test_data <= test_data - 1'b1;

                  if(counter == 8'hff)
                    test_offset <= test_offset + 1'b1;

                  if (counter <= 8'hf0) begin
                    m_fft_i_axis_tvalid_r <= 1'b1;
                    m_fft_q_axis_tvalid_r<= 1'b1;
                    if (counter == 8'hf0) begin
                      m_fft_i_axis_tlast_r <= 1'b1;
                      m_fft_q_axis_tlast_r <= 1'b1;
                    end else begin
                        m_fft_i_axis_tlast_r <= 1'b0;
                        m_fft_q_axis_tlast_r <= 1'b0;
                    end
                  end else begin
                     m_fft_i_axis_tvalid_r <= 1'b0;
                    m_fft_q_axis_tvalid_r <= 1'b0;
                    m_fft_i_axis_tlast_r <= 1'b0;
                    m_fft_q_axis_tlast_r <= 1'b0;
                  end

                  if (peak_tlast_i & peak_tvalid_i) begin
                    peak_result_i <= peak_index_i;
                    peak_val_i <= peak_tdata_i;
                    peak_num_i <= num_peaks_i;
                    new_peak_i <= 1'b1;
                  end else if (dw_axis_tvalid_r)begin
                    new_peak_i <= 1'b0;
                  end

                  if (peak_tlast_q & peak_tvalid_q) begin
                    peak_result_q <= peak_index_q;
                    peak_val_q <= peak_tdata_q;
                    peak_num_q <= num_peaks_q;
                    new_peak_q <= 1'b1;
                  end else if (dw_axis_tvalid_r)begin
                    new_peak_q <= 1'b0;
                  end

                  if(new_peak_i & new_peak_q & !dw_axis_tvalid_r)begin
                    dw_axis_tvalid_r <= 1'b1;
                    dw_axis_tlast_r <= 1'b1;
                  end
                  else if (dw_axis_tready)begin
                    dw_axis_tvalid_r <= 1'b0;
                    dw_axis_tlast_r <= 1'b0;
                  end

                  if(counter == 8'h0)begin
                    new_peak_threshold_i_r <= 'b0;
                    new_peak_threshold_q_r <= 'b0;
                    update_threshold <= 1'b1;
                  end else if (update_threshold) begin
                    new_peak_threshold_i_r[4*threshold_ctrl_i[7:4]+3-:4] <=threshold_ctrl_i[3:0];
                    new_peak_threshold_q_r[4*threshold_ctrl_q[7:4]+3-:4] <=threshold_ctrl_q[3:0];
                    threshold_ctrl_i_r[7:4] <=  threshold_ctrl_i_r[7:4] + 1;
                    threshold_ctrl_q_r[7:4] <=  threshold_ctrl_q_r[7:4] + 1;
                    update_threshold <= 1'b0;
                 end else begin
                    peak_threshold_i_r <= new_peak_threshold_i_r;
                    peak_threshold_q_r <= new_peak_threshold_q_r;
                  end  
              end


            end

assign m_fft_i_axis_tdata = {28'b0,test_data[7:4],28'b0,test_data[3:0]};
assign m_fft_q_axis_tdata = {28'b0,counter[7:4],28'b0,counter[3:0]};

 assign m_fft_i_axis_tready = 1'b1;
 assign m_fft_q_axis_tready = 1'b1;

 assign m_fft_i_axis_tvalid = m_fft_i_axis_tvalid_r;
assign m_fft_q_axis_tvalid = m_fft_q_axis_tvalid_r;
assign m_fft_i_axis_tlast = m_fft_i_axis_tlast_r;
assign m_fft_q_axis_tlast = m_fft_q_axis_tlast_r;


        
//assign threshold_ctrl_i = {4'hf,4'h1};
//assign threshold_ctrl_q = {4'hf,4'h1};
assign threshold_ctrl_i = threshold_ctrl_i_r;
assign threshold_ctrl_q = threshold_ctrl_q_r;

//assign peak_threshold_i = {{(60-4*threshold_ctrl_i[7:4]){1'b0}},threshold_ctrl_i[3:0],{(4*threshold_ctrl_i[7:4]){1'b0}}};
//assign peak_threshold_q = {{(60-4*threshold_ctrl_q[7:4]){1'b0}},threshold_ctrl_q[3:0],{(4*threshold_ctrl_q[7:4]){1'b0}}};
//assign peak_threshold_i = {{(60-4*THRESH_CTRL[7:4]){1'b0}},THRESH_CTRL[3:0],{(4*THRESH_CTRL[7:4]){1'b0}}};
//assign peak_threshold_q = {{(60-4*THRESH_CTRL[7:4]){1'b0}},THRESH_CTRL[3:0],{(4*THRESH_CTRL[7:4]){1'b0}}};
assign peak_threshold_i = peak_threshold_i_r;
assign peak_threshold_q = peak_threshold_q_r;


    sq_mag_estimate#(
        .DATA_LEN(32),
        .DIV_OR_OVERFLOW(0),  // (1): Divide output by 2, (0): use overflow bit
        .REGISTER_OUTPUT(1)
    )
     sq_mag_i (
        .clk(fmc_tclk),
        .dataI(m_fft_i_axis_tdata[31:0]),
        .dataI_tvalid(m_fft_i_axis_tvalid),
        .dataI_tlast(m_fft_i_axis_tlast),
        .dataQ(m_fft_i_axis_tdata[63:32]),
        .dataQ_tvalid(m_fft_i_axis_tvalid),
        .dataQ_tlast(m_fft_i_axis_tlast),
        .data_index({24'b0,index}),
        .data_tuser({24'b0,counter}),
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
       .clk(fmc_tclk),
       .dataI(m_fft_q_axis_tdata[31:0]),
       .dataI_tvalid(m_fft_q_axis_tvalid),
       .dataI_tlast(m_fft_q_axis_tlast),
       .dataQ(m_fft_q_axis_tdata[63:32]),
       .dataQ_tvalid(m_fft_q_axis_tvalid),
       .dataQ_tlast(m_fft_q_axis_tlast),
       .data_index({24'b0,index}),
       .data_tuser({24'b0,counter}),
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
         .clk(fmc_tclk),
         .aresetn(fmc_tresetn_i),
         .tdata(sq_mag_i_axis_tdata),
         .tvalid(sq_mag_i_axis_tvalid),
         .tlast(sq_mag_i_axis_tlast),
         .tuser(sq_mag_i_axis_tuser),
         .index(sq_mag_i_index),
         .cutoff(32'he2),
         .lpf_index(lpf_index_i),
         .lpf_tdata(lpf_tdata_i),
         .lpf_tvalid(lpf_tvalid_i),
         .lpf_tlast(lpf_tlast_i),
         .lpf_tuser(lpf_tuser_i)
       );


     freq_domain_lpf #(
         .DATA_LEN(64)
     ) freq_lpf_q(
          .clk(fmc_tclk),
          .aresetn(fmc_tresetn_i),
          .tdata(sq_mag_q_axis_tdata),
          .tvalid(sq_mag_q_axis_tvalid),
          .tlast(sq_mag_q_axis_tlast),
          .tuser(sq_mag_q_axis_tuser),
          .index(sq_mag_q_index),
          .cutoff(32'he2),
          .lpf_index(lpf_index_q),
          .lpf_tdata(lpf_tdata_q),
          .lpf_tvalid(lpf_tvalid_q),
          .lpf_tlast(lpf_tlast_q),
          .lpf_tuser(lpf_tuser_q)
        );



    peak_finder #(
      .DATA_LEN(64)
    ) peak_finder_i(
      .clk(fmc_tclk),
      .aresetn(fmc_tresetn_i),
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
      .threshold({64'hff}),
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
      .clk(fmc_tclk),
      .aresetn(fmc_tresetn_i),
      .tdata(lpf_tdata_q),
      .tvalid(lpf_tvalid_q),
      .tlast(lpf_tlast_q),
      .tuser(lpf_tuser_q),
      .index(lpf_index_q),
      .threshold({64'hff}),
      .peak_index(peak_index_q),
      .peak_tdata(peak_tdata_q),
      .peak_tvalid(peak_tvalid_q),
      .peak_tlast(peak_tlast_q),
      .peak_tuser(peak_tuser_q),
      .num_peaks(num_peaks_q)
    );

    assign dw_axis_tdata = {peak_num_i,peak_num_q,peak_val_i,peak_val_q,peak_result_i,peak_result_q};
    assign dw_axis_tvalid = dw_axis_tvalid_r;
    assign dw_axis_tlast = dw_axis_tlast_r;
    peak_axis_dwidth_converter peak_axis_dwidth_converter_inst (
      .aclk(fmc_tclk),                    // input wire aclk
      .aresetn(fmc_tresetn_i),              // input wire aresetn
      .s_axis_tvalid(dw_axis_tvalid),  // input wire s_axis_tvalid
      .s_axis_tready(dw_axis_tready),  // output wire s_axis_tready
      .s_axis_tdata(dw_axis_tdata),    // input wire [255 : 0] s_axis_tdata
      .s_axis_tlast(dw_axis_tlast),    // input wire s_axis_tlast
      .m_axis_tvalid(dwout_axis_tvalid),  // output wire m_axis_tvalid
      .m_axis_tready(dwout_axis_tready),  // input wire m_axis_tready
      .m_axis_tdata(dwout_axis_tdata),    // output wire [7 : 0] m_axis_tdata
      .m_axis_tlast(dwout_axis_tlast)    // output wire m_axis_tlast
    );

    peak_axis_clock_converter peak_axis_clock_converter_inst (
      .s_axis_aresetn(fmc_tresetn_i),  // input wire s_axis_aresetn
      .m_axis_aresetn(gtx_tresetn_i),  // input wire m_axis_aresetn
      .s_axis_aclk(fmc_tclk),        // input wire s_axis_aclk
      .s_axis_tvalid(dwout_axis_tvalid),    // input wire s_axis_tvalid
      .s_axis_tready(dwout_axis_tready),    // output wire s_axis_tready
      .s_axis_tdata(dwout_axis_tdata),      // input wire [7 : 0] s_axis_tdata
      .s_axis_tlast(dwout_axis_tlast),      // input wire s_axis_tlast
      .m_axis_aclk(gtx_tclk),        // input wire m_axis_aclk
      .m_axis_tvalid(pk_axis_tvalid),    // output wire m_axis_tvalid
      .m_axis_tready(pk_axis_tready),    // input wire m_axis_tready
      .m_axis_tdata(pk_axis_tdata),      // output wire [7 : 0] m_axis_tdata
      .m_axis_tlast(pk_axis_tlast)      // output wire m_axis_tlast
    );

    assign pk_axis_tuser = 'b0;
    assign config_pkt_tready = 1'b1;
    kc705_ethernet_rgmii_axi_packetizer #(
       .DEST_ADDR                 (48'hda0102030405),
       .SRC_ADDR                  (48'h5a0102030405),
       .MAX_SIZE                  (32'd52),
       .MIN_SIZE                  (32'd52),
       .ENABLE_VLAN               (0),
       .VLAN_ID                   (12'd2),
       .VLAN_PRIORITY             (3'd2)
    ) config_packetizer_inst (
      //  .axi_tclk                  (axi_tclk),
      //  .axi_tresetn               (axi_tresetn),
       .axi_tclk                  (gtx_tclk),
       .axi_tresetn               (gtx_tresetn_i),
       .enable_adc_pkt            (1'b1),
       .speed                     (2'b10),

        // data from ADC Data fifo
        .adc_axis_tdata           (pk_axis_tdata),
        .adc_axis_tvalid          (pk_axis_tvalid),
        .adc_axis_tlast           (pk_axis_tlast),
        .adc_axis_tuser           (pk_axis_tuser),
        .adc_axis_tready          (pk_axis_tready),

       .tdata                     (config_pkt_tdata),
       .tvalid                    (config_pkt_tvalid),
       .tlast                     (config_pkt_tlast),
       .tready                    (config_pkt_tready)
    );

endmodule
