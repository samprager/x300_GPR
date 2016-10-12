`timescale 1ps/100fs

module sim_tb_cmd_decoder;

   localparam AXI_TCLK_PERIOD          = 10000;         // 100 MHz
   localparam GTX_TCLK_PERIOD          = 8000;         // 125 MHz
   localparam FMC_TCLK_PERIOD          = 4069;         // 245.76 MHz
   localparam RESET_PERIOD = 320000; //in pSec
   localparam HOST_MAC_ADDR = 48'h985aebdb066f;
   localparam FPGA_MAC_ADDR = 48'h5a0102030405;

   localparam CHIRP_PRF_INT_COUNT_INIT = 32'h00000000;
   localparam CHIRP_PRF_FRAC_COUNT_INIT = 32'h00000010;//32'h927c0000;

   localparam use_test_packet = 1;

    reg axi_tresetn_i;
    reg axi_tclk_i;

    reg gtx_tresetn_i;
    reg gtx_tclk_i;

    reg fmc_tresetn_i;
    reg fmc_tclk_i;

  wire [7:0] gpio_led;

   wire                   axi_tclk;
   wire                   axi_tresetn;

   wire                   gtx_tclk;
   wire                   gtx_tresetn;

   wire                   fmc_tclk;
   wire                   fmc_tresetn;

     // data from ADC Data fifo
  reg       [7:0]                    rx_axis_tdata_reg;
  reg                                rx_axis_tvalid_reg;
  reg                                rx_axis_tlast_reg;
  reg                                rx_axis_tuser_reg;

  reg [7:0]                     temp_data;

  //reg [127:0] test_packet_1 = 128'h5a0102030405a45e60ee9f3500260200;
  //reg [127:0] test_packet_2 = 128'h46465757fc1700001e00000004000000;
  //reg [127:0] test_packet_3 = 128'h77000000000000000000010001040001;
  //reg [127:0]  test_packet_2 = 128'h43435757ce2b00000000000000010000;
  //reg [127:0]  test_packet_3 = 128'hc8000000000300000100000000100000;
  //reg [31:0] test_packet_4 = 32'h00000000;

  reg [127:0] test_packet_1 = 128'h5a0102030405a45e60ee9f3500260200;
  //reg [127:0] test_packet_2 = 128'h43435757df50910d0000000000004c1d;
  reg [127:0] test_packet_2 = 128'h43435757df50910d0000000000100000;
  reg [127:0] test_packet_3 = 128'hfe010000000b000001000000000e0000;//128'hc8000000000300000100000000100000;
  reg [31:0] test_packet_4 = 32'h10030000;

   reg [127:0] wfrm_packet_1;
   reg [127:0] wfrm_packet_2;
   reg [127:0] wfrm_packet_3;
   reg [31:0] wfrm_packet_4;

  // reg [127:0] chirp_fast_packet_1 = 128'h5a0102030405985aebdb066f00260000;
  // reg [127:0] chirp_fast_packet_2 = 128'h434357572747000000000000f6000000;
  // reg [127:0] chirp_fast_packet_3 = 128'hc8000000000300000100000000100000;
  // reg [31:0] chirp_fast_packet_4 = 32'h00000000;

  reg [127:0] chirp_default_packet_1 = 128'h5a0102030405985aebdb066f00260000;
  reg [127:0] chirp_default_packet_2 = 128'h43435757621600000000000000007c92;
  reg [127:0] chirp_default_packet_3 = 128'hc8000000000300000100000000100000;
  reg [31:0] chirp_default_packet_4 = 32'h00000000;

  reg [127:0] wfrm_test_packet_1 = 128'h5a0102030405a45e60ee9f3500260000;
  reg [127:0] wfrm_test_packet_2 = 128'h41445757adebaec9e65bddcc00000000;
  reg [127:0] wfrm_test_packet_3 = 128'h0600000000000000b3043a65724d0a2f;
  reg [31:0] wfrm_test_packet_4 = 32'h027adbbc;

  reg [127:0] wfrm_test_packet2_1 = 128'h5a0102030405a45e60ee9f3500260800;
  reg [127:0] wfrm_test_packet2_2 = 128'h41445757adebd17ee65bddcc01000000;
  reg [127:0] wfrm_test_packet2_3 = 128'h0600000000000000027aac82724dce06;
  reg [31:0] wfrm_test_packet2_4 = 32'hb304ff7f;


  reg [127:0] test_packet_rd_1 = 128'h5a0102030405a45e60ee9f35000e0100;
  reg[95:0] test_packet_rd_2 = 96'h4343525204000000efbeedfe;
//  reg[95:0] test_packet_rd_2 = 96'h646525275000000efbeedfe;


         // data from ADC Data fifo
wire       [7:0]                   rx_axis_tdata;
wire                                rx_axis_tvalid;
wire                                rx_axis_tlast;
wire                                rx_axis_tuser;

 wire                               rx_axis_tready;


 wire      [7:0]                    tx_axis_tdata;
 wire                               tx_axis_tvalid;
 wire                               tx_axis_tlast;
 wire                                tx_axis_tready;

 reg                                tx_axis_tready_reg;

 reg                tready_reg;
 reg                rx_axis_tvalid_select;

 reg [7:0]         data_counter = 'b0;
 reg [1:0]               test_flop = 2'b0;

 reg [6*8-1:0]     fpga_mac = FPGA_MAC_ADDR;
 reg [7:0] cmd_id_reg = 8'h00;
 reg [1:0] command_type;
 reg use_wr_packet = 1'b1;

 reg use_wfrm_packet = 1'b1;
 reg sel_wfrm_packet = 1'b0;

 reg [15:0] dds_route_ctrl;


 wire     frame_error;
 wire activity_flash;
 //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
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
      tx_axis_tready_reg = 1'b1; // initial value
      @(posedge gtx_tresetn_i); // wait for reset
      tx_axis_tready_reg = 1'b0;
      repeat(32) @(posedge gtx_tclk_i);
      tx_axis_tready_reg = 1'b1;
      use_wr_packet = 1'b1;
      repeat(16000) @(posedge gtx_tclk_i);
      //use_wr_packet = 1'b0;
      use_wfrm_packet = 1'b0;
      repeat(32000) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(32) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(1) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b1;
      // repeat(3) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(1) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b1;
      // repeat(2) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(1) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b1;
      // repeat(1) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(256) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b1;
      // repeat(2048) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b0;
      // repeat(2048) @(posedge gtx_tclk_i);
      // tx_axis_tready_reg = 1'b1;
      // repeat(2048) @(posedge gtx_tclk_i);
      $finish;
    end

    always @(posedge  gtx_tclk_i) begin
      if (~gtx_tresetn_i) begin
           data_counter <= 'b0;
           rx_axis_tdata_reg <= 8'h02;
           rx_axis_tvalid_reg <= 1'b0;
           rx_axis_tlast_reg <= 1'b0;
           rx_axis_tuser_reg <= 1'b0;
           cmd_id_reg <= 'b0;
           command_type <= 0;
           dds_route_ctrl <= 'b1;
           sel_wfrm_packet <= 1;

      end else if(use_wfrm_packet) begin
              data_counter <= data_counter + 1'b1;
               if (data_counter < 8'hcc)
                   rx_axis_tvalid_reg <= 1'b0;
               else
                   rx_axis_tvalid_reg <= 1'b1;

              if (sel_wfrm_packet) begin
                 wfrm_packet_1 <= wfrm_test_packet_1;
                 wfrm_packet_2 <= wfrm_test_packet_2;
                 wfrm_packet_3 <= wfrm_test_packet_3;
                 wfrm_packet_4 <= wfrm_test_packet_4;
              end else begin
                wfrm_packet_1 <= wfrm_test_packet2_1;
                wfrm_packet_2 <= wfrm_test_packet2_2;
                wfrm_packet_3 <= wfrm_test_packet2_3;
                wfrm_packet_4 <= wfrm_test_packet2_4;
              end

               if (data_counter == 8'hff)
                  rx_axis_tlast_reg <= 1'b1;
               else
                   rx_axis_tlast_reg <= 1'b0;

               if (data_counter >=8'hcc & data_counter<8'hdc) begin
                   rx_axis_tdata_reg <= wfrm_packet_1[8'h80-(8'h8*(data_counter-8'hcc))-1-:8];
               end else if (data_counter >=8'hdc & data_counter<8'hec) begin
                   rx_axis_tdata_reg <= wfrm_packet_2[8'h80-(8'h8*(data_counter-8'hdc))-1-:8];
               end else if (data_counter >=8'hec & data_counter<8'hfc)begin
                   rx_axis_tdata_reg <= wfrm_packet_3[8'h80-(8'h8*(data_counter-8'hec))-1-:8];
               end else if (data_counter >=8'hfc) begin
                   rx_axis_tdata_reg <= wfrm_packet_4[8'h20-(8'h8*(data_counter-8'hfc))-1-:8];
               end

             if (data_counter == 8'hff) begin
                sel_wfrm_packet <= !sel_wfrm_packet;
             end
      end else if(use_test_packet) begin
        if (use_wr_packet) begin
         data_counter <= data_counter + 1'b1;
          if (data_counter < 8'hcc)
              rx_axis_tvalid_reg <= 1'b0;
          else
              rx_axis_tvalid_reg <= 1'b1;

          if (data_counter == 8'hff)
             rx_axis_tlast_reg <= 1'b1;
          else
              rx_axis_tlast_reg <= 1'b0;

          if (data_counter >=8'hcc & data_counter<8'hdc) begin
              rx_axis_tdata_reg <= test_packet_1[8'h80-(8'h8*(data_counter-8'hcc))-1-:8];
          end else if (data_counter >=8'hdc & data_counter<8'hec) begin
              rx_axis_tdata_reg <= test_packet_2[8'h80-(8'h8*(data_counter-8'hdc))-1-:8];
              if (data_counter == 8'he1)
                test_packet_2[95:88] <= test_packet_2[95:88]+1;
          end else if (data_counter >=8'hec & data_counter<8'hfc)begin
              rx_axis_tdata_reg <= test_packet_3[8'h80-(8'h8*(data_counter-8'hec))-1-:8];
          end else if (data_counter >=8'hfc) begin
              rx_axis_tdata_reg <= test_packet_4[8'h20-(8'h8*(data_counter-8'hfc))-1-:8];
          end

//        if (data_counter == 8'hff) begin
//            test_packet_4[31:24] <= dds_route_ctrl[9:2];
//            dds_route_ctrl <= dds_route_ctrl+1'b1;
//        end
//           if (data_counter == 8'hff) begin
//             command_type <= command_type + 1;
//             if (command_type == 2'b0) begin
// //             test_packet_2 <= 128'h46465757fc1700001e00000004000000;
// //             test_packet_3 <= 128'h77000000000000000000010001040001;
//                test_packet_2 <= 128'h43435757ce2b00000000000000010000;
//                test_packet_3<= 128'hc8000000000300000100000000100000;
//            end else if (command_type == 2'b1) begin
//             // test_packet_2 <= 128'h46465757e42a00001e12070004000000;
//             // test_packet_3 <= 128'h77000000010101010000010001040001;
//            end else if (command_type == 2'b10)begin
//             // test_packet_2 <= 128'h464657573e2b00001e120700edfe0000;
//             // test_packet_3<= 128'h04030201010101010000000101080010;
//            end
//            else if (command_type == 2'b11)begin
//             // test_packet_2 <= 128'h43435757ce2b00000000000000007c92;
//             // test_packet_3<= 128'hc8000000000300000100000000100000;
//            end
//           end
        end else begin
          data_counter <= data_counter + 1'b1;
           if (data_counter < 8'he4)
               rx_axis_tvalid_reg <= 1'b0;
           else
               rx_axis_tvalid_reg <= 1'b1;
           if (data_counter == 8'hff)
              rx_axis_tlast_reg <= 1'b1;
           else
               rx_axis_tlast_reg <= 1'b0;

           if (data_counter >=8'he4 & data_counter<8'hf4) begin
               rx_axis_tdata_reg <= test_packet_rd_1[8'h80-(8'h8*(data_counter-8'he4))-1-:8];
           end else if (data_counter >=8'hf4) begin
               rx_axis_tdata_reg <= test_packet_rd_2[8'h60-(8'h8*(data_counter-8'hf4))-1-:8];
            end
           if (data_counter == 8'hff) begin
             command_type <= command_type + 1;
             if (command_type[0]) begin
              test_packet_rd_2 <= 96'h4343525204000000efbeedfe;
            end else  begin
              test_packet_rd_2 <= 96'h4646525275000000efbeedfe;
            end
            end
          end
        end else begin
           data_counter <= data_counter + 1'b1;
           if (data_counter < 8'h40)
               rx_axis_tvalid_reg <= 1'b0;
           else
               rx_axis_tvalid_reg <= 1'b1;
           if (data_counter == 8'hff)
              rx_axis_tlast_reg <= 1'b1;
           else
               rx_axis_tlast_reg <= 1'b0;

           if (data_counter >=8'h40 & data_counter<8'h46) begin
               rx_axis_tdata_reg <= fpga_mac[48-8*(data_counter-8'h40)-1-:8];
           end else if (data_counter == 8'h4c) begin
               rx_axis_tdata_reg <= 8'h00;
               temp_data <=rx_axis_tdata_reg+1'b1;
           end else if (data_counter == 8'h4d) begin
               rx_axis_tdata_reg <= 8'h22;
               temp_data <= temp_data + 1'b1;
           end else if (data_counter == 8'h4e) begin
              // rx_axis_tdata_reg <= 8'hd1;
              rx_axis_tdata_reg <= temp_data +1'b1;
   //        end else if (data_counter==8'h50) begin
   //             rx_axis_tdata_reg <= 8'h57;
   //             temp_data <=rx_axis_tdata_reg+1'b1;
           end

           else if (data_counter>=8'h50 & data_counter<8'h52)begin
                if(command_type[0])
                    rx_axis_tdata_reg <= 8'h43;
                else
                    rx_axis_tdata_reg <= 8'h46;
           end
           else if (data_counter>=8'h52 & data_counter<8'h54) begin
               if(command_type[1])
                   rx_axis_tdata_reg <= 8'h57;
               else
                   rx_axis_tdata_reg <= 8'h52;
           end
           else if (data_counter == 8'h54) begin
             rx_axis_tdata_reg <= cmd_id_reg;
             cmd_id_reg <= cmd_id_reg+1;
             command_type <= command_type + 1;
           end else if (data_counter == 8'h55) begin
             rx_axis_tdata_reg <= temp_data + 8'h08;
           end else if (rx_axis_tvalid_reg & rx_axis_tready & !rx_axis_tlast_reg)
               rx_axis_tdata_reg <= rx_axis_tdata_reg + 1'b1;
           else if (data_counter == 8'h40)
               rx_axis_tdata_reg <= rx_axis_tdata_reg + 1'b1;

        end
      end

 cmd_decoder_top #(
 .SIMULATION(1),
 .CHIRP_PRF_INT_COUNT_INIT(CHIRP_PRF_INT_COUNT_INIT),
 .CHIRP_PRF_FRAC_COUNT_INIT(CHIRP_PRF_FRAC_COUNT_INIT)
  ) u_cmd_decoder_top (
        .gtx_clk_bufg (gtx_tclk),
        .gtx_resetn (gtx_tresetn),
        .s_axi_aclk (axi_tclk),
        .s_axi_resetn (axi_tresetn),
        .clk_fmc150 (fmc_tclk),
        .resetn_fmc150 (fmc_tresetn),

        .gpio_dip_sw        (8'hff),
        .gpio_led        (gpio_led),
    // data from the RX data path
        .tx_axis_tdata       (tx_axis_tdata),
        .tx_axis_tvalid       (tx_axis_tvalid),
        .tx_axis_tlast       (tx_axis_tlast),
        .tx_axis_tready      (tx_axis_tready),

            .rx_axis_tdata       (rx_axis_tdata),
            .rx_axis_tvalid       (rx_axis_tvalid),
            .rx_axis_tlast       (rx_axis_tlast),
            .rx_axis_tready      (rx_axis_tready)

);

assign tx_axis_tready = tx_axis_tready_reg;

assign rx_axis_tdata =  rx_axis_tdata_reg;
assign rx_axis_tvalid =  rx_axis_tvalid_reg;
assign rx_axis_tlast =  rx_axis_tlast_reg;
assign rx_axis_tuser =  rx_axis_tuser_reg;





endmodule
