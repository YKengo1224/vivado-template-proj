 # PROJ_NAME := 
# BIN_FILE  := 
# DTS_FILE  := 
# DTBO_FILE := 

.PHONY:comp install run stop remove

comp:$(DTS_FILE)
	dtc -I dts -O dtb  -o $(DTBO_FILE) $^

install :$(DTBO_FILE) $(BIN_FILE)
ifeq ($(BOARD),zybo-z7-20)
	sudo cp $(BIN_FILE) /lib/firmware
	sudo mkdir -p /config/device-tree/overlays/$(PROJ_NAME)
	sudo cp $(DTBO_FILE) /config/device-tree/overlays/$(PROJ_NAME)/dtbo
	sudo rm /lib/firmware/$(BIN_FILE)
else
	sudo mkdir -p /lib/firmware/xilinx/$(PROJ_NAME)
	sudo cp $(DTBO_FILE) $(BIN_FILE) /lib/firmware/xilinx/$(PROJ_NAME)
	echo -e '{\n  "shell_type": "XRT_FLAT",\n  "num_slots": "1"\n}' | sudo tee /lib/firmware/xilinx/$(PROJ_NAME)/shell.json > /dev/null
	sudo xmutil unloadapp
	sudo xmutil loadapp $(PROJ_NAME)
endif

# run:install
# 	sudo cp $(BIN_FILE) /lib/firmware/
# 	sudo sh -c "echo 1 > /config/device-tree/overlays/$(PROJ_NAME)/status"
# 	sudo rm /lib/firmware/$(BIN_FILE)

# stop:
# 	sudo sh -c "echo 0 > /config/device-tree/overlays/$(PROJ_NAME)/status"

remove:stop
	sudo rmdir /config/device-tree/overlays/$(PROJ_NAME)/
