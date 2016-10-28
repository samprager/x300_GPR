
include $(TOOLS_DIR)/make/viv_ip_builder.mak

LIB_IP_FIFO_GENERATOR_ADC_SRCS = $(IP_BUILD_DIR)/fifo_generator_adc/fifo_generator_adc.xci

LIB_IP_FIFO_GENERATOR_ADC_OUTS = $(addprefix $(IP_BUILD_DIR)/fifo_generator_adc/, \
fifo_generator_adc.xci.out \
synth/fifo_generator_adc.vhd \
)

$(LIB_IP_FIFO_GENERATOR_ADC_SRCS) $(LIB_IP_FIFO_GENERATOR_ADC_OUTS) : $(GPR_IP_DIR)/fifo_generator_adc/fifo_generator_adc.xci
	$(call BUILD_VIVADO_IP,fifo_generator_adc,$(ARCH),$(PART_ID),$(GPR_IP_DIR),$(IP_BUILD_DIR),0)
