
include $(TOOLS_DIR)/make/viv_ip_builder.mak

LIB_IP_SP_DDS_SRCS = $(IP_BUILD_DIR)/SP_DDS/SP_DDS.xci

LIB_IP_SP_DDS_OUTS = $(addprefix $(IP_BUILD_DIR)/SP_DDS/, \
SP_DDS.xci.out \
synth/SP_DDS.vhd \
)

$(LIB_IP_SP_DDS_SRCS) $(LIB_IP_SP_DDS_OUTS) : $(GPR_IP_DIR)/SP_DDS/SP_DDS.xci
	$(call BUILD_VIVADO_IP,SP_DDS,$(ARCH),$(PART_ID),$(GPR_IP_DIR),$(IP_BUILD_DIR),0)
