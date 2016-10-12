//------------------------------------------------------------------------------
// File       : ethernet_rgmii_packet_gen.v
// Author     : Samuel Prager
// -----------------------------------------------------------------------------

`timescale 1 ps/1 ps

(* DowngradeIPIdentifiedWarnings = "yes" *)
module ethernet_rgmii_packet_gen #(
 //   parameter                            DEST_ADDR       = 48'hda0102030405,
    parameter                            DEST_ADDR       = 48'h985aebdb066f,
    parameter                            SRC_ADDR        = 48'h5a0102030405,
    parameter                            MAX_SIZE        = 16'd532,//16'd500,
 //   parameter                            MIN_SIZE        = 16'd64,
    parameter                            MIN_SIZE        = 16'd532,//16'd500,
    parameter                            ENABLE_VLAN     = 1'b0,
    parameter                            VLAN_ID         = 12'd2,
    parameter                            VLAN_PRIORITY   = 3'd2
)(
    input                                axi_tclk,
    input                                axi_tresetn,
    input                                check_resetn,

    input                                enable_pat_gen,
    input                                enable_pat_chk,
    input                                enable_address_swap,
    input       [1:0]                    speed,

    // data from the RX data path
    input       [7:0]                    rx_axis_tdata,
    input                                rx_axis_tvalid,
    input                                rx_axis_tlast,
    input                                rx_axis_tuser,
    output                               rx_axis_tready,
    // data TO the TX data path
    output      [7:0]                    tx_axis_tdata,
    output                               tx_axis_tvalid,
    output                               tx_axis_tlast,
    input                                tx_axis_tready,

    // data from ADC Data fifo
    input                                enable_adc_pkt,
    input       [7:0]                    adc_axis_tdata,
    input                                adc_axis_tvalid,
    input                                adc_axis_tlast,
    input                                adc_axis_tuser,
    output                               adc_axis_tready,

    output                               frame_error,
    output                               activity_flash
);

wire     [7:0]       rx_axis_tdata_int;
wire                 rx_axis_tvalid_int;
wire                 rx_axis_tlast_int;
wire                 rx_axis_tready_int;

wire     [7:0]       tx_axis_tdata_int;
wire                 tx_axis_tvalid_int;
wire                 tx_axis_tlast_int;
wire                 tx_axis_tready_int;

wire     [7:0]       pat_gen_tdata;
wire                 pat_gen_tvalid;
wire                 pat_gen_tlast;
wire                 pat_gen_tready;
wire                 pat_gen_tready_int;

wire     [7:0]       adc_pkt_tdata;
wire                 adc_pkt_tvalid;
wire                 adc_pkt_tlast;
wire                 adc_pkt_tready;
wire                 adc_pkt_tready_int;

wire     [7:0]       mux1_tdata;
wire                 mux1_tvalid;
wire                 mux1_tlast;
wire                 mux1_tready;

//wire     [7:0]       mux2_tdata;
//wire                 mux2_tvalid;
//wire                 mux2_tlast;
//wire                 mux2_tready;

wire     [7:0]       tx_axis_as_tdata;
wire                 tx_axis_as_tvalid;
wire                 tx_axis_as_tlast;
wire                 tx_axis_as_tready;

wire       [7:0]                    adc_axis_tdata_ila;
wire                                adc_axis_tvalid_ila;
wire                                adc_axis_tlast_ila;
wire                                adc_axis_tuser_ila;
wire                               adc_axis_tready_ila;

wire     [7:0]       adc_pkt_tdata_ila;
wire                 adc_pkt_tvalid_ila;
wire                 adc_pkt_tlast_ila;
wire                 adc_pkt_tready_ila;

//   assign tx_axis_tdata = tx_axis_as_tdata;
//   assign tx_axis_tvalid = tx_axis_as_tvalid;
//   assign tx_axis_tlast = tx_axis_as_tlast;
//   assign tx_axis_as_tready = tx_axis_tready;
   assign tx_axis_tdata = tx_axis_tdata_int;
   assign tx_axis_tvalid = tx_axis_tvalid_int;
   assign tx_axis_tlast = tx_axis_tlast_int;
   assign tx_axis_tready_int = tx_axis_tready;

   assign pat_gen_tready = pat_gen_tready_int;

   assign adc_pkt_tready = adc_pkt_tready_int;

ethernet_rgmii_axi_packetizer #(
   .DEST_ADDR                 (DEST_ADDR),
   .SRC_ADDR                  (SRC_ADDR),
   .MAX_SIZE                  (MAX_SIZE),
   .MIN_SIZE                  (MIN_SIZE),
   .ENABLE_VLAN               (ENABLE_VLAN),
   .VLAN_ID                   (VLAN_ID),
   .VLAN_PRIORITY             (VLAN_PRIORITY)
) axi_packetizer_inst (
   .axi_tclk                  (axi_tclk),
   .axi_tresetn               (axi_tresetn),

   .enable_adc_pkt            (enable_adc_pkt),
   .speed                     (speed),

    // data from ADC Data fifo
    .adc_axis_tdata           (adc_axis_tdata),
    .adc_axis_tvalid          (adc_axis_tvalid),
    .adc_axis_tlast           (adc_axis_tlast),
    .adc_axis_tuser           (adc_axis_tuser),
    .adc_axis_tready          (adc_axis_tready),

   .tdata                     (adc_pkt_tdata),
   .tvalid                    (adc_pkt_tvalid),
   .tlast                     (adc_pkt_tlast),
   .tready                    (adc_pkt_tready)
);





// simple mux between the rx_fifo AXI interface and the pat gen output
// this is not registered as it is passed through a pipeline stage to limit the impact
ethernet_rgmii_axi_mux axi_mux_inst1(
   //.mux_select                (enable_pat_gen),
    .mux_select                (enable_adc_pkt),


//   .tdata0                    (rx_axis_tdata),
//   .tvalid0                   (rx_axis_tvalid),
//   .tlast0                    (rx_axis_tlast),
//   .tready0                   (rx_axis_tready),
    .tdata0                    (tx_axis_as_tdata),
    .tvalid0                   (tx_axis_as_tvalid),
    .tlast0                    (tx_axis_as_tlast),
    .tready0                   (tx_axis_as_tready),

//   .tdata1                    (pat_gen_tdata),
//   .tvalid1                   (pat_gen_tvalid),
//   .tlast1                    (pat_gen_tlast),
//   .tready1                   (pat_gen_tready_int),\
   .tdata1                     (adc_pkt_tdata),
    .tvalid1                   (adc_pkt_tvalid),
    .tlast1                    (adc_pkt_tlast),
    .tready1                   (adc_pkt_tready_int),

   .tdata                     (mux1_tdata),
   .tvalid                    (mux1_tvalid),
   .tlast                     (mux1_tlast),
   .tready                    (mux1_tready)
);



// a pipeline stage has been added to reduce timing issues and allow
// a pattern generator to be muxed into the path
ethernet_rgmii_axi_pipe axi_pipe_inst (
   .axi_tclk                  (axi_tclk),
   .axi_tresetn               (axi_tresetn),

   .rx_axis_fifo_tdata_in     (mux1_tdata),
   .rx_axis_fifo_tvalid_in    (mux1_tvalid),
   .rx_axis_fifo_tlast_in     (mux1_tlast),
   .rx_axis_fifo_tready_in    (mux1_tready),

//   .rx_axis_fifo_tdata_out    (rx_axis_tdata_int),
//   .rx_axis_fifo_tvalid_out   (rx_axis_tvalid_int),
//   .rx_axis_fifo_tlast_out    (rx_axis_tlast_int),
//   .rx_axis_fifo_tready_out   (rx_axis_tready_int)
   .rx_axis_fifo_tdata_out    (tx_axis_tdata_int),
   .rx_axis_fifo_tvalid_out   (tx_axis_tvalid_int),
   .rx_axis_fifo_tlast_out    (tx_axis_tlast_int),
   .rx_axis_fifo_tready_out   (tx_axis_tready_int)

);

// address swap module: based around a Dual port distributed ram
// data is written in and the read only starts once the da/sa have been
// stored.  Can cope with a gap of one cycle between packets.
ethernet_rgmii_address_swap address_swap_inst (
   .axi_tclk                  (axi_tclk),
   .axi_tresetn               (axi_tresetn),

   .enable_address_swap       (enable_address_swap),

//   .rx_axis_fifo_tdata        (rx_axis_tdata_int),
//   .rx_axis_fifo_tvalid       (rx_axis_tvalid_int),
//   .rx_axis_fifo_tlast        (rx_axis_tlast_int),
//   .rx_axis_fifo_tready       (rx_axis_tready_int),
   .rx_axis_fifo_tdata        (rx_axis_tdata),
   .rx_axis_fifo_tvalid       (rx_axis_tvalid),
   .rx_axis_fifo_tlast        (rx_axis_tlast),
   .rx_axis_fifo_tready       (rx_axis_tready),

   .tx_axis_fifo_tdata        (tx_axis_as_tdata),
   .tx_axis_fifo_tvalid       (tx_axis_as_tvalid),
   .tx_axis_fifo_tlast        (tx_axis_as_tlast),
   .tx_axis_fifo_tready       (tx_axis_as_tready)
);


endmodule
