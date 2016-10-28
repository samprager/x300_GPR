

include $(TOOLS_DIR)/make/viv_ip_builder.mak

LIB_IP_AXI_WAVEFORM_DATAMOVER_SRCS = $(IP_BUILD_DIR)/axi_waveform_datamover/axi_waveform_datamover.xci

LIB_IP_AXI_WAVEFORM_DATAMOVER_OUTS = $(addprefix $(IP_BUILD_DIR)/axi_waveform_datamover/, \
axi_waveform_datamover.xci.out \
synth/axi_waveform_datamover.vhd \
)

$(LIB_IP_AXI_WAVEFORM_DATAMOVER_SRCS) $(LIB_IP_AXI_WAVEFORM_DATAMOVER_OUTS) : $(GPR_IP_DIR)/axi_waveform_datamover/axi_waveform_datamover.xci
	$(call BUILD_VIVADO_IP,axi_waveform_datamover,$(ARCH),$(PART_ID),$(GPR_IP_DIR),$(IP_BUILD_DIR),0)
