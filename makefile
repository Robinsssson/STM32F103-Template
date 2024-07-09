# Project configuration
PROJECT ?= template
CC = arm-none-eabi-gcc
LD = arm-none-eabi-gcc
OBJCOPY = arm-none-eabi-objcopy
CC_PATH = /opt/gcc-arm-none-eabi/arm-none-eabi
STD_PERIPH_LIBS ?= ./STM32F10x_StdPeriph_Lib_V3.6.0/

# Directories
SOURCES_DIR = src
BUILD_DIR = build
INCLUDE_DIR = include
STARTUP_DIR = startup
LIB_DIR = lib
3RD_LIB_DIR = 3rdparty

# Source files
SOURCES = \
    $(SOURCES_DIR)/main.c \
    $(SOURCES_DIR)/stm32f10x_it.c \
    $(SOURCES_DIR)/system_stm32f10x.c \
    $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_rcc.c \
    $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_gpio.c \
	$(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/stm32f10x_usart.c \
    $(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/src/misc.c \
    $(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/CoreSupport/core_cm3.c

# Include directories
INCLUDES = \
    -I$(INCLUDE_DIR) \
    -I$(3RD_LIB_DIR) \
    -I$(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x/ \
    -I$(STD_PERIPH_LIBS)/Libraries/CMSIS/CM3/CoreSupport/ \
    -I$(STD_PERIPH_LIBS)/Libraries/STM32F10x_StdPeriph_Driver/inc/ \
    -I$(CC_PATH)/include

# Libraries
LIBS = \
    -lc

# Compiler and linker flags
CFLAGS = \
    -g -Wall --specs=nosys.specs -march=armv7-m -O0 \
    -mlittle-endian -mthumb -mcpu=cortex-m3 \
    -mfloat-abi=soft \
    -DSTM32F10X_HD -DUSE_STDPERIPH_DRIVER \
    $(INCLUDES)

LDFLAGS = \
    -Wl,--gc-sections $(LIBS) -T$(STARTUP_DIR)/stm32_flash.ld

# Startup file
START_FILE = startup_stm32f10x_hd

# st-flash tool
ST_FLASH ?= st-flash

# Object files
OBJECTS = $(SOURCES:$(SOURCES_DIR)/%.c=$(BUILD_DIR)/%.o) \
          $(BUILD_DIR)/startup/$(START_FILE).o

# Quiet mode
QUIET ?= @

# Default target
all: $(BUILD_DIR)/$(PROJECT).elf

# Compile target
$(BUILD_DIR)/$(PROJECT).elf: $(OBJECTS)
	@echo "Linking $@..."
	$(QUIET)mkdir -p $(BUILD_DIR)
	$(QUIET)$(CC) $(OBJECTS) $(CFLAGS) $(LDFLAGS) -o $@
	@echo "Generating HEX and BIN files..."
	$(QUIET)$(OBJCOPY) -O ihex $@ $(BUILD_DIR)/$(PROJECT).hex
	$(QUIET)$(OBJCOPY) -O binary $@ $(BUILD_DIR)/$(PROJECT).bin

# Pattern rule for object files
$(BUILD_DIR)/%.o: $(SOURCES_DIR)/%.c
	@echo "Compiling $<..."
	$(QUIET)mkdir -p $(dir $@)
	$(QUIET)$(CC) $(CFLAGS) -c $< -o $@

# Rule for compiling the startup file
$(BUILD_DIR)/$(STARTUP_DIR)/$(START_FILE).o: $(STARTUP_DIR)/$(START_FILE).s
	@echo "Compiling $<..."
	$(QUIET)mkdir -p $(dir $@)
	$(QUIET)$(CC) $(CFLAGS) -c $< -o $@

# Remove binary files
.PHONY: clean flash compile_commands

clean:
	@echo "Cleaning project..."
	$(QUIET)rm -rf $(BUILD_DIR)

# Flash target
flash:
	@echo "Flashing the device..."
	$(QUIET)/opt/openocd/bin/openocd -f /opt/openocd/openocd/scripts/interface/stlink.cfg \
	-f /opt/openocd/openocd/scripts/target/stm32f1x.cfg \
	-c "program $(BUILD_DIR)/$(PROJECT).bin verify reset exit 0x08000000"

# Generate compile_commands.json for clangd
compile_commands:
	@echo "Generating compile_commands.json..."
	$(QUIET)bear -- make all -j2
	$(QUIET)mv -f compile_commands.json $(BUILD_DIR)/compile_commands.json
