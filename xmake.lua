-- 定义项目
set_project("template")

-- 设置交叉编译工具链为 arm-none-eabi
toolchain("arm-none-eabi")
    set_kind("standalone")
    set_sdkdir("/opt/gcc-arm-none-eabi")
toolchain_end()

-- 设置目标
target("template")
    -- 设置目标类型为二进制文件
    set_kind("binary")
    -- 设置工具链为 arm-none-eabi
    set_toolchains("arm-none-eabi")
    -- 设置平台为交叉编译
    set_plat("cross")
    -- 设置架构为 Cortex-M3
    set_arch("armv7-m")

    -- 添加宏定义
    add_defines("STM32F10X_HD", "USE_STDPERIPH_DRIVER")

    -- 添加源文件
    add_files("src/*.c")
    add_files("./STM32F10x_StdPeriph_Lib_V3.6.0/Libraries/STM32F10x_StdPeriph_Driver/src/*.c")
    add_files("startup/startup_stm32f10x_hd.s")
    -- add_files("./STM32F10x_StdPeriph_Lib_V3.6.0/Libraries/CMSIS/CM3/CoreSupport/core_cm3.c")

    -- 添加包含目录
    add_includedirs("include")
    add_includedirs("./STM32F10x_StdPeriph_Lib_V3.6.0/Libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x")
    add_includedirs("./STM32F10x_StdPeriph_Lib_V3.6.0/Libraries/CMSIS/CM3/CoreSupport")
    add_includedirs("./STM32F10x_StdPeriph_Lib_V3.6.0/Libraries/STM32F10x_StdPeriph_Driver/inc")
    add_includedirs("/opt/gcc-arm-none-eabi/arm-none-eabi/include")

    -- 添加编译选项
    add_cflags("-g", "-Wall", "-march=armv7-m", "-O0", "-mlittle-endian", "-mthumb", "-mfloat-abi=soft", {force = true})

    -- 添加链接选项
    add_ldflags("-Wl,--gc-sections", "-lc", "-T$(projectdir)/startup/stm32_flash.ld", {force = true})

    -- 设置生成的目标文件名
    set_filename("template.elf")

    -- 定义构建完成后的操作
    after_build(function(target)
        -- 打印编译完成消息
        print("Compile finished!!!")
        -- 生成 HEX 和 BIN 文件
        os.exec("arm-none-eabi-objcopy -O ihex ".. target:targetfile().. " ".. path.join(target:targetdir(), target:name().. ".hex"))
        os.exec("arm-none-eabi-objcopy -O binary ".. target:targetfile().. " ".. path.join(target:targetdir(), target:name().. ".bin"))
        -- 打印生成完成消息
        print("Generate hex and bin files ok!!!")
        -- 打印存储空间占用情况
        print("********************存储空间占用情况*****************************")
        os.exec("arm-none-eabi-size -Ax ".. target:targetfile())
        os.exec("arm-none-eabi-size -Bx ".. target:targetfile())
        os.exec("arm-none-eabi-size -Bd ".. target:targetfile())
    end)

-- 定义任务

task("flash")
    -- 定义任务执行函数
    on_run(function ()
        -- 执行烧写命令
        os.exec("/opt/openocd/bin/openocd -f /opt/openocd/openocd/scripts/interface/stlink.cfg \
            -f /opt/openocd/openocd/scripts/target/stm32f1x.cfg \
            -c 'program ".."build/cross/armv7-m/release/template.bin".. " verify reset exit 0x08000000'")
    end)

    set_menu {
        usage = "xmake flash [options]",
        description = "flash elf to MCU",
        options = {
            {}
        }
    }
