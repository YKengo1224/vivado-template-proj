IS_VITIS_AI := true
#IS_VITIS_AI := false

#remote host address
REMOTE_NAME     := castella.local

#directory config
VIVADO_DIR      := vivado-work
VITIS_DIR       := vitis-work
BUILD_DIR       := build
HARDWARE_DIR    := $(BUILD_DIR)/hardware
DTS_DIR         := $(BUILD_DIR)/device-tree
INSTALL_DIR     := $(BUILD_DIR)/install
FIRMWARE_DIR    := my-firmware
PROJ_DIR        := vivado_proj
LOG_DIR         := log
BOARD_DIR       := ./board_files 
TCL_DIR         := ./tcl
PY_DIR          := ./scripts
RTL_DIR         := ./rtl
TB_DIR          := ./tb
WAVE_DIR        := ./wave
SIM_LOG_DIR     := ./sim_log
SIM_WORK_DIR    := ./sim_work


# device tree generator repo
DEVICETREE_REPO := $(VITIS_DIR)/device-tree-xlnx


#simulation Makefile path
#SIM_MK          := ./sim_iverilog.mk
SIM_MK          := ./sim.mk


#FPGA board config
#BOARD           := zybo-z7-20
BOARD           := kv260
#BOARD           := kr260

#FPGA architecture
ifeq ($(BOARD),zybo-z7-20)
	ARCH           := zynq
	PROC           := ps7_cortexa9_0
else
	ARCH           := zynqmp
	PROC           := psu_cortexa53_0
endif


#Block design config
BD_NAME         := jpeg_encoder
BD_WRAPPER_NAME := $(BD_NAME)_wrapper

#file name config
BIN_NAME        := $(BD_WRAPPER_NAME).bit.bin
VITIS_DTS_NAME  := pl.dtsi
DTS_NAME        := pl.dtsi
DTBO_NAME       := pl.dtbo
HWINFO_NAME     := hwinfo.json
VITIS_DTS_DIR_NAME  := vitis_dtsi
VITIS_DTS_DIR   := $(BUILD_DIR)/$(VITIS_DTS_DIR_NAME)/$(VITIS_DTS_DIR_NAME)/$(BD_WRAPPER_NAME)/$(PROC)/device_tree_domain/bsp

#tcl file config
BD_TCL          := $(TCL_DIR)/gen_bd.tcl
CREATE_TCL      := $(TCL_DIR)/create_proj.tcl

#############generate file config##################
#vivado project file
XPR_FILE        := $(PROJ_DIR)/$(PROJ_DIR).xpr
# Block Design file
BD_FILE         := $(CURDIR)/$(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).srcs/sources_1/bd/$(BD_NAME)/$(BD_NAME).bd
# bitstream file
BITSTREAM_FILE  := $(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).runs/impl_1/$(BD_WRAPPER_NAME).bit
#hardware platform file
HARDWARE_FILE   := $(VIVADO_DIR)/$(BD_WRAPPER_NAME).xsa
#hardware info file
HWH_FILE        = $(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).gen/sources_1/bd/$(BD_NAME)/hw_handoff/$(BD_NAME).hwh
#bin file(default generate file path)
BIN_DEFO_FILE  := $(VIVADO_DIR)/$(PROJ_DIR)/$(PROJ_DIR).runs/impl_1/$(BIN_NAME)
# bin file (use to device tree ovalay)
BIN_FILE        := $(INSTALL_DIR)/$(BIN_NAME)
#vitis generate dts file (device tree source)
VITIS_DTS_FILE  := $(VITIS_DTS_DIR)/$(VITIS_DTS_NAME)
#generate dts file (device tree source)
DTS_FILE        := $(INSTALL_DIR)/$(DTS_NAME)
#hardware info file
HWINFO_FILE     := $(INSTALL_DIR)/$(HWINFO_NAME)
#generate dtbo file (device tree binary)
DTBO_FILE       := $(INSTALL_DIR)/$(DTBO_NAME)
#limote work Makefile
LIMOTE_MAKEFILE := remote.mk


#	python scripts/ex.py $(HWH_FILE)	

#vivado option
VIVADO_VERSION  := 2022.1
VIVADO_OPTS     := -log $(LOG_DIR)/vivado.log -journal $(LOG_DIR)/vivado.jou
VIVADO_TCL_OPTS := -mode tcl -source
VIVADO_JOBS     := 20

##########################################################

.PHONY : create gui gen bd sim wave  help

.DEFAULT_GOAL := help

################vivado command################
create:$(VIVADO_DIR)/$(XPR_FILE) ## create vivado proj  ## make create

gui: $(VIVADO_DIR)/$(XPR_FILE) ## open vivado gui ## make gui
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(XPR_FILE) &

gen:$(BITSTREAM_FILE) ## generate bitstream and hw platform  ## make gen

bd: $(BD_FILE) ## export block design ## make bd
		cd $(VIVADO_DIR) && echo "open_project $(XPR_FILE);open_bd_design $(BD_FILE);write_bd_tcl -force ../$(BD_TCL)" | vivado $(VIVADO_OPTS) -mode tcl


viv_clean: ## clean vivado project ## make viv_clean
	rm -rf $(VIVADO_DIR)

$(VIVADO_DIR)/$(XPR_FILE):
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) ../$(CREATE_TCL)	-tclargs $(PROJ_DIR) $(BOARD_DIR) $(BOARD) $(BD_NAME) $(BD_TCL) $(IS_VITIS_AI)

$(BITSTREAM_FILE):$(VIVADO_DIR)/$(XPR_FILE) $(BD_FILE)
	mkdir -p $(VIVADO_DIR)/$(LOG_DIR)
	cd $(VIVADO_DIR) && vivado $(VIVADO_OPTS) $(VIVADO_TCL_OPTS) ../$(TCL_DIR)/generate_bitstream.tcl -tclargs $(PROJ_DIR) $(BD_WRAPPER_NAME) $(VIVADO_JOBS)

##############################################



################vitis command################
vitis: ## open vitis gui ## make vits
	cd $(VITIS_DIR) && vitis -workspace . &

gen_bin:$(BIN_FILE) ## generate bin file ## make bin

gen_dts:$(DTS_FILE) ## generate device tree source ##make gen_dts

gen_dtbo:$(DTBO_FILE) ## generate device tree binary ##make gen_dtbo

vit_clean: ##clean vitis project ##make vit_clean
	rm -rf $(VITIS_DIR)

$(BIN_FILE):$(BITSTREAM_FILE)
	mkdir -p $(INSTALL_DIR)
ifeq ($(ARCH),zynqmp)
	echo 'all:{[destination_device = pl] $(BITSTREAM_FILE) }' > pl.bif
else
	echo 'all:{$(BITSTREAM_FILE) }' > pl.bif
endif
	bootgen -w -arch $(ARCH) -image pl.bif -process_bitstream bin
	cp $(BIN_DEFO_FILE) $(BIN_FILE)
	rm -f pl.bif
 

$(VITIS_DTS_FILE):$(BIN_FILE)
#	mkdir -p $(DTS_DIR)
	cd $(BUILD_DIR) && echo "createdts -hw ../$(HARDWARE_FILE)	-platform-name $(BD_WRAPPER_NAME) -git-branch xlnx_rel_v$(VIVADO_VERSION) -overlay -compile -out vitis_dtsi" | xsct

$(DTS_FILE):$(VITIS_DTS_FILE)
	cd $(PY_DIR) && python3 generate_dt.py ../$(VITIS_DTS_FILE) ../$(HWH_FILE) ../$(DTS_FILE) ../$(HWINFO_FILE) $(VIVADO_VERSION)

$(DTBO_FILE):$(DTS_FILE)
	dtc -@ -O dtb -I dts -o $@ $<

#############################################

############lemote work command################
install:$(DTBO_FILE) $(INSTALL_DIR)/Makefile
	rsync -av $(INSTALL_DIR)/* $(REMOTE_NAME):~/work/$(BD_NAME)/

$(INSTALL_DIR)/Makefile:
	mkdir -p $(INSTALL_DIR)
	cp $(LIMOTE_MAKEFILE)  $(INSTALL_DIR)/Makefile
	sed -i '1i  PROJ_NAME = $(BD_NAME)\nBIN_FILE = $(BIN_NAME)\n\
	DTS_FILE = $(DTS_NAME)\n\
	DTBO_FILE = $(DTBO_NAME)\n' $@


##############################################


############simuration command################
include $(SIM_MK)
##############################################


help:  ## print this message
	@echo "RTL development pretarions by Makefile"
	@echo ""
	@echo "Usage : make SUB_COMMAND argument_name=argument_value"
	@echo ""
	@echo "Command list"
	@echo ""
	@echo =============Vivado============
	@echo
	@printf "\033[36m%-30s\033[0m %-50s %s\n" "[Sub command]" "[Description]" "[Example]"
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' Makefile | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'
#@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | perl -pe 's%^([/a-zA-Z_-]+):.*?(##)%$$1 $$2%' | awk -F " *?## *?" '{printf "\033[36m%-30s\033[0m %-50s %s\n", $$1, $$2, $$3}'
	@echo
	@echo ===========simulation==========
	@echo
	@printf "\033[36m%-30s\033[0m %-50s %s\n" "[Sub command]" "[Description]" "[Example]" 
	@$(MAKE)  --no-print-directory sim_help
