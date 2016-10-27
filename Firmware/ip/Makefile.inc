
include $(TOOLS_DIR)/make/viv_ip_builder.mak

GPR_IP_SRCS = $(addprefix $(GPR_IP_DIR)/, \
axis_data_fifo_0.xcix \
axi_waveform_bram_ctrl.xcix \
axi_waveform_datamover.xcix \
fifo_generator_adc.xcix \
SP_DDS.xcix \
)
# cmpy_16b.xcix \
# axis_interconnect_1m2s.xcix \
# axis_interconnect_1s2m.xcix \
# axi_vfifo_ctrl_0.xcix \
# ethernet_rgmii.xcix \
# ethernet_tx_axis_interconnect.xcix \
# mixer_mult_gen.xcix \
# mult_gen_32b.xcix \
# mult_gen_32b.xcix.tmp \
# peak_axis_clock_converter.xcix \
# peak_axis_dwidth_converter.xcix \
# rx_cmd_1s4m_axis_interconnect.xcix \
# xfft_0.xcix \
# xfft_short_16b.xcix \
# xfft_short_32b.xcix \

GPR_IP_OUTS = $(addprefix $(GPR_IP_DIR)/, \
axis_data_fifo_0.xcix \
axi_waveform_bram_ctrl.xcix \
axi_waveform_datamover.xcix \
fifo_generator_adc.xcix \
SP_DDS.xcix \
)
