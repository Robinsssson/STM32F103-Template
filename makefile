# name for output binary files
PROJECT ?= template

# path to STM32F103 standard peripheral library
CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy

CC_PATH = /opt/gcc-arm-none-eabi/arm-none-eabi
STD_PERIPH_LIBS ?= ./STM32F10x_StdPeriph_Lib_V3.6.0/

SOURCES_DIR = src
BUILD_DIR   = build
INCLUDE_DIR = include
STARTUP_DIR = startup
LIB_DIR = lib
3RD_LIB_DIR = 3rdparty

# list of source files
SOURCES  = $(SOURCES_DIR)/main.c
SOURCES += $(SOURCES_DIR)/stm32f10x_it.c
SOURCES += $(SOURCES_DIR)/system_stm32f10x.c
SOURCES += $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_rcc.c
# SOURCES += $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/*.c
SOURCES += $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_gpio.c
SOURCES += $(STARTUP_DIR)/startup_stm32f10x_hd.s
SOURCES += $(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/CoreSupport/core_cm3.c

INCLUDES  = -I$(INCLUDE_DIR)
INCLUDES += -I$(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/
INCLUDES += -I$(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/CoreSupport/
INCLUDES += -I$(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/inc/
INCLUDES += -I/opt/gcc-arm-none-eabi/arm-none-eabi/include

CFLAGS  = -g -Wall --specs=nosys.specs -march=armv7-m -O0
CFLAGS += -mlittle-endian -mthumb -mcpu=cortex-m3 # -mthumb-interwork
CFLAGS += -mfloat-abi=soft # -mfpu=fpv4-sp-d16 
CFLAGS += -DSTM32F10X_HD -DUSE_STDPERIPH_DRIVER
CFLAGS += -Wl,--gc-sections $(INCLUDES) 
# CFLAGS += $(LIBS)

LDFLAGS = -T$(STARTUP_DIR)/stm32_flash.ld
# compiler, objcopy (should be in PATH)

# path to st-flash (or should be specified in PATH)
ST_FLASH ?= st-flash
# ST_CLI ?= st-link
# specify compiler flags

OBJS = $(SOURCES:.c=.o)

all: $(BUILD_DIR)/$(PROJECT).elf

# compile
$(BUILD_DIR)/$(PROJECT).elf: $(SOURCES)
	@ if [ ! -d $(BUILD_DIR) ]; then mkdir $(BUILD_DIR); fi
	@ $(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@
	$(OBJCOPY) -O ihex $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).hex
	$(OBJCOPY) -O binary $(BUILD_DIR)/$(PROJECT).elf $(BUILD_DIR)/$(PROJECT).bin

# remove binary files
.PHONY: clean flash compile_commands

init_project:
	@mkdir $(SOURCES_DIR); mkdir $(STARTUP_DIR); mkdir $(INCLUDE_DIR); mkdir $(LIB_DIR); mkdir $(3RD_LIB_DIR)
	@cp $(STD_PERIPH_LIBS)/Project/STM32F10x_StdPeriph_Template/*.c $(SOURCES_DIR)
	@cp $(STD_PERIPH_LIBS)/Project/STM32F10x_StdPeriph_Template/*.h $(INCLUDE_DIR)
	@cp $(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/startup/gcc_ride7/*.s $(STARTUP_DIR)
	echo "you should cp the stm32_flash by yourself from $(STD_PERIPH_LIBS)/Project/STM32F10x_StdPeriph_Template/"


clean:
	@ if [ -d $(BUILD_DIR) ]; then rm -rf $(BUILD_DIR)/*.o $(BUILD_DIR)/*.elf $(BUILD_DIR)/*.hex $(BUILD_DIR)/*.bin; fi

# flash
flash:
	# sudo $(ST_FLASH) write $(BUILD_DIR)/$(PROJECT).bin 0x8000000
	/opt/openocd/bin/openocd -f /opt/openocd/openocd/scripts/interface/stlink-v2.cfg -f /opt/openocd/openocd/scripts/target/stm32f1x.cfg -c "program $(BUILD_DIR)/$(PROJECT).bin verify reset exit 0x08000000"

compile_commands:
	bear -- make all
	mv compile_commands.json $(BUILD_DIR)/compile_commands.json
# flash:
# 	$(ST_CLI) -c SWD -P $(PROJECT).bin 0x8000000

# read:
# 	$(ST_CLI) -c SWD -Dump 0x0 0x8000000 $(PROJECT).bin

# erase:
# 	$(ST_CLI) -ME
