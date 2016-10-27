//////////////////////////////////////////////////////////////////////////////////
// Company:MiXIL
// Engineer: Samuel Prager
//
// Create Date: 10/11/2016 04:32:51 PM
// Design Name:
// Module Name: chirpgen
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
`timescale 1ps/1ps

module chirpgen #(
    parameter DDS_LATENCY = 2
 )(
        input clk,
        input rst,
        output [15:0] chirp_out_i,
        output [15:0] chirp_out_q,
        output chirp_out_valid,
        output chirp_out_last,

        output chirp_ready,
        output chirp_done,
        output chirp_active,
        input chirp_init,
        input chirp_enable,

        input [31:0] freq_offset_in,
        input [31:0] tuning_word_coeff_in,
        input [31:0] chirp_count_max_in
   );

   reg [15:0] chirp_i, chirp_q;
   reg chirp_valid;
   reg chirp_ready_r, chirp_active_r, chirp_done_r;
   reg [31:0] phase_acc, tuning_word, tuning_word_coeff, chirp_count, chirp_count_max, freq_offset;

   wire [31:0] dds_dout_tdata;
   wire dds_dout_tvalid;

   wire [15:0] dds_phase_tdata;
   wire dds_phase_tvalid;
   reg dds_phase_tvalid_r;

   reg [7:0] dds_latency_counter;
   reg dds_aresetn_r;
   wire dds_aresetn;


SP_DDS sp_dds_inst (
    .aclken(1'b1),
    .aclk(clk),
    .aresetn(dds_aresetn),
    .m_axis_data_tvalid(dds_dout_tvalid),
    .m_axis_data_tdata(dds_dout_tdata),
    .s_axis_phase_tvalid(dds_phase_tvalid),
    .s_axis_phase_tdata(dds_phase_tdata)
 );
 assign dds_phase_tdata = phase_acc[15:0];
 assign dds_phase_tvalid = dds_phase_tvalid_r;

 always @(posedge clk) begin
    if(rst)
        chirp_ready_r <= 0;
    else
        chirp_ready_r <= 1'b1;
 end

 always @(posedge clk) begin
    if(rst) begin
        chirp_count <= 'b0;
        tuning_word <= 'b0;
        phase_acc <= 'b0;
        chirp_i <= 'b0;
        chirp_q <= 'b0;
        chirp_active_r <= 0;
        chirp_done_r <= 0;
        dds_phase_tvalid_r <= 1'b0;
        dds_latency_counter <= 'b0;
        dds_aresetn_r <= 1'b1;
     end
     else if (chirp_init & ~chirp_active_r) begin
        chirp_count <= 'b0;
        tuning_word <= freq_offset_in+tuning_word_coeff_in;
        phase_acc <= freq_offset_in;
        chirp_i <= 'b0;
        chirp_q <= 'b0;
        chirp_active_r <= 1;
        chirp_done_r <= 0;

        tuning_word_coeff <= tuning_word_coeff_in;
        freq_offset <= freq_offset_in;
        chirp_count_max <= chirp_count_max_in;
        dds_phase_tvalid_r <= 1'b1;
        dds_aresetn_r <= 1'b1;
        dds_latency_counter <= 'b0;
    end
    else if (chirp_active_r) begin
        dds_phase_tvalid_r <= 1'b1;
        dds_aresetn_r <= 1'b1;
        if (chirp_done_r) begin
            chirp_active_r <= 0;
            chirp_done_r <= 0;
            chirp_i <= 'b0;
            chirp_q <= 'b0;
            chirp_valid <= 1'b0;
            dds_latency_counter <= DDS_LATENCY;
        end
        else begin
            phase_acc <= phase_acc + tuning_word;
            tuning_word <= tuning_word + tuning_word_coeff;
            if (dds_dout_tvalid) begin
                chirp_i <= dds_dout_tdata[15:0];
                chirp_q <= dds_dout_tdata[31:16];
                chirp_count <= chirp_count + 1'b1;
                chirp_valid <= 1'b1;
            end
            else begin
                chirp_valid <= 1'b0;
            end

            if(chirp_count >= chirp_count_max) begin
                chirp_done_r <= 1'b1;
                chirp_count <= 'b0;
            end
        end
    end
    else begin
        chirp_i <= 'b0;
        chirp_q <= 'b0;
        chirp_valid <= 1'b0;
        if (|dds_latency_counter) begin
            dds_phase_tvalid_r <= 1'b1;
            dds_latency_counter <= dds_latency_counter - 1'b1;
            dds_aresetn_r <= 1'b0;
        end else begin
            dds_phase_tvalid_r <= 1'b0;
            dds_aresetn_r <= 1'b1;
        end
    end
   end

    assign dds_aresetn = ~(~dds_aresetn_r | rst);
    assign chirp_ready = chirp_ready_r;
    assign chirp_active = chirp_active_r;
    assign chirp_done = chirp_done_r;
    assign chirp_out_i = chirp_i;
    assign chirp_out_q = chirp_q;
    assign chirp_out_valid = chirp_valid;
    assign chirp_out_last = chirp_done_r;

endmodule
