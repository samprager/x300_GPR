`timescale 1ps/100fs

module sim_tb_decoder;

   localparam AXI_TCLK_PERIOD          = 8000;         // 125 MHz
  localparam RESET_PERIOD = 320000; //in pSec
  localparam HOST_MAC_ADDR = 48'h985aebdb066f;
  localparam FPGA_MAC_ADDR = 48'h5a0102030405;

    reg axi_tresetn_i;
    reg axi_tclk_i;

   wire                   axi_tclk;
   wire                   axi_tresetn;

     // data from ADC Data fifo
  reg       [7:0]                    rx_axis_tdata_reg;
  reg                                rx_axis_tvalid_reg;
  reg                                rx_axis_tlast_reg;
  reg                                rx_axis_tuser_reg;

  reg [7:0]                     temp_data;

         // data from ADC Data fifo
wire       [7:0]                    rx_axis_tdata;
wire                                rx_axis_tvalid;
wire                                rx_axis_tlast;
wire                                rx_axis_tuser;

 wire                               rx_axis_tready;


 wire  [31:0]       tdata;
 wire              tvalid;
 wire              tlast;
 wire              tready;

 // data TO the TX data path
 //        .tx_axis_tdata       (tx_axis_tdata),
 //        .tx_axis_tvalid       (tx_axis_tvalid),
 //        .tx_axis_tlast       (tx_axis_tlast),
 //        .tx_axis_tready      (tx_axis_tready)
 wire      [31:0]                    tx_axis_tdata;
 wire                               tx_axis_tvalid;
 wire                               tx_axis_tlast;
 wire                                tx_axis_tready;

 reg                                tx_axis_tready_reg;

 reg                tready_reg;
 reg                rx_axis_tvalid_select;

 reg [7:0]         data_counter = 'b0;
 reg                test_flop = 1'b1;

 reg [6*8-1:0]     fpga_mac = FPGA_MAC_ADDR;
 reg [7:0] cmd_id_reg = 8'h00;

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


   assign axi_tresetn = axi_tresetn_i;
   assign axi_tclk = axi_tclk_i;


 initial begin
      tx_axis_tready_reg = 1'b1; // initial value
      @(posedge axi_tresetn_i); // wait for reset
      tx_axis_tready_reg = 1'b0;
      repeat(32) @(posedge axi_tclk_i);
      tx_axis_tready_reg = 1'b1;
      repeat(8192) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(32) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(1) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b1;
//      repeat(3) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(1) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b1;
//      repeat(2) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(1) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b1;
//      repeat(1) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(256) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b1;
//      repeat(2048) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b0;
//      repeat(2048) @(posedge axi_tclk_i);
//      tx_axis_tready_reg = 1'b1;
//      repeat(2048) @(posedge axi_tclk_i);
      $finish;
    end


 always @(posedge  axi_tclk_i) begin
    if (~axi_tresetn_i) begin
        data_counter <= 'b0;
        rx_axis_tdata_reg <= 8'h02;
        rx_axis_tvalid_reg <= 1'b0;
        rx_axis_tlast_reg <= 1'b0;
        rx_axis_tuser_reg <= 1'b0;
        cmd_id_reg <= 'b0;
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
        end else if (data_counter>=8'h50 & data_counter<8'h54)
          rx_axis_tdata_reg <= 8'h57;
        else if (data_counter == 8'h54) begin
          rx_axis_tdata_reg <= cmd_id_reg;
          cmd_id_reg <= cmd_id_reg+1; 
        end else if (data_counter == 8'h55) begin
          rx_axis_tdata_reg <= temp_data + 8'h08;
        end else if (rx_axis_tvalid_reg & rx_axis_tready & !rx_axis_tlast_reg)
            rx_axis_tdata_reg <= rx_axis_tdata_reg + 1'b1;
        else if (data_counter == 8'h40)
            rx_axis_tdata_reg <= rx_axis_tdata_reg + 1'b1;
     end
   end
//        if (rx_axis_tready & rx_axis_tvalid) begin
//            if (data_counter < 8'h06)
//                rx_axis_tdata_reg <= dest_mac_addr[8*(6-data_counter)-1-:8];
//            else if (data_counter == 8'h0c)
//                rx_axis_tdata_reg <= 8'h0;
//            else if (data_counter == 8'h0d)
//                rx_axis_tdata_reg <= 8'h22;
//            else
//                rx_axis_tdata_reg <= data_counter;
//        end
//       // if (&rx_axis_tdata_reg[5:0]) begin
//        if ((rx_axis_tdata_reg == (8'h22+8'h0c)) & (data_counter >8'h0f)) begin
//            rx_axis_tlast_reg <= 1'b1;
//            if (test_flop)
//                data_counter <= 0;
//            else
//                data_counter <= 1'b1;
//            test_flop <= !test_flop;
//        end else if (rx_axis_tready & rx_axis_tvalid)begin
//            rx_axis_tlast_reg <= 1'b0;
//            data_counter <= data_counter + 1'b1;
//        end
//    end
//end


// initial begin
//     rx_axis_tvalid_select = 1'b0; // initial value
//     @(posedge axi_tresetn_i); // wait for reset
//     rx_axis_tvalid_select = 1'b0;
//     repeat(300) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(150) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b0;
//     repeat(32) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(1) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(3) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b0;
//     repeat(1) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(2) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b0;
//     repeat(1) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(1) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b0;
//     repeat(20) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//     repeat(1000) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b0;
//     repeat(2000) @(posedge axi_tclk_i);
//     rx_axis_tvalid_select = 1'b1;
//   end

// initial begin
//     rx_axis_tdata_reg = 7'b0;
//     rx_axis_tvalid_reg = 1'b0;
//     rx_axis_tlast_reg = 1'b0;
//     rx_axis_tuser_reg = 1'b0;
// end

 decoder_top #(
   //   parameter                            DEST_ADDR       = 48'hda0102030405,
      .DEST_ADDR       (HOST_MAC_ADDR),
      .SRC_ADDR        (FPGA_MAC_ADDR)

  ) u_decoder_top (
        .rx_fifo_clock (axi_tclk),
        .rx_fifo_resetn (axi_tresetn),

        .enable_rx_decode        (1'b1),
        .speed                  (2'b10),

    // data from the RX data path
            .rx_axis_tdata       (rx_axis_tdata),
            .rx_axis_tvalid       (rx_axis_tvalid),
            .rx_axis_tlast       (rx_axis_tlast),
            .rx_axis_tready      (rx_axis_tready),

    // data TO the TX data path
            .cmd_axis_tdata       (tx_axis_tdata),
            .cmd_axis_tvalid       (tx_axis_tvalid),
            .cmd_axis_tlast       (tx_axis_tlast),
            .cmd_axis_tready      (tx_axis_tready)
);

//kc705_ethernet_rgmii_axi_packetizer u_packetizer_top
//(
//       .axi_tclk (axi_tclk),
//       .axi_tresetn (axi_tresetn),

//        .enable_adc_pkt (1'b1),
//        .speed  (2'b10),

//    // data from ADC Data fifo
//        .rx_axis_tdata               (rx_axis_tdata),
//        .rx_axis_tvalid              (rx_axis_tvalid),
//        .rx_axis_tlast              (rx_axis_tlast),
//        .rx_axis_tuser          (rx_axis_tuser),
//        .rx_axis_tready              (rx_axis_tready),

//        .tdata       (tdata),
//        .tvalid       (tvalid),
//        .tlast       (tlast),
//        .tready       (tready)
//);

assign tx_axis_tready = tx_axis_tready_reg;

assign rx_axis_tdata =  rx_axis_tdata_reg;
//assign rx_axis_tvalid =  rx_axis_tvalid_reg & rx_axis_tvalid_select;
assign rx_axis_tvalid =  rx_axis_tvalid_reg;

assign rx_axis_tlast =  rx_axis_tlast_reg;
assign rx_axis_tuser =  rx_axis_tuser_reg;



endmodule
