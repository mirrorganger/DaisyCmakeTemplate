#  https://ryanwinter.org/embedded-development-with-cmake-and-arm-gcc/

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
# target triplet machine-vendor-operating-system.
set(TARGET_TRIPLET "arm-none-eabi-")


find_program(COMPILER_ON_PATH "${TARGET_TRIPLET}gcc")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)


#---------------------------------------------------------------------------------------
# Set compiler/linker flags
#---------------------------------------------------------------------------------------
set(MCPU_FLAGS "-mthumb -mcpu=cortex-m7")
set(VFP_FLAGS "-mfloat-abi=hard -mfpu=fpv5-d16")
set(CMAKE_WARNINGS "-Wall -Werror -Wno-attributes -Wno-strict-aliasing -Wno-maybe-uninitialized -Wno-missing-attributes -Wno-stringop-overflow")
set(CMAKE_COMMON_FLAGS "-fno-builtin -fno-exceptions -ffunction-sections -fdata-sections -fomit-frame-pointer -finline-functions")

set(CMAKE_C_FLAGS "${MCPU_FLAGS} ${VFP_FLAGS} ${CMAKE_COMMON_FLAGS} -std=gnu11" CACHE INTERNAL "C Compiler options")
set(CMAKE_CXX_FLAGS "${MCPU_FLAGS} ${VFP_FLAGS} ${CMAKE_COMMON_FLAGS} ${CMAKE_WARNINGS} -std=gnu++14" CACHE INTERNAL "C++ Compiler options")
set(CMAKE_ASM_FLAGS "${MCPU_FLAGS} {VFP_FLAGS} -fasm ${CMAKE_COMMON_FLAGS} ${CMAKE_WARNINGS} -x assembler-with-cpp" CACHE INTERNAL "ASM Compiler options")

# Ensure the ar plugin is loaded (needed for LTO)
set(CMAKE_AR ${TARGET_TRIPLET}gcc-ar)
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> qcs <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH   true)
set(CMAKE_CXX_ARCHIVE_CREATE "<CMAKE_AR> qcs <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_CXX_ARCHIVE_FINISH   true)




#---------------------------------------------------------------------------------------
# Preprocessor definitions
#---------------------------------------------------------------------------------------
add_compile_definitions(
        CORE_CM7
        STM32H750xx
        STM32H750IB
        ARM_MATH_CM7
        flash_layout
        HSE_VALUE=16000000
        USE_HAL_DRIVER
        USE_FULL_LL_DRIVER
)

if(NOT ${APP_TYPE} STREQUAL "BOOT_NONE")
        message(STATUS "Adding boot flag")
        add_compile_definitions(
                BOOT_APP
        )       
endif()


#---------------------------------------------------------------------------------------
# Set linker flags
#---------------------------------------------------------------------------------------

# -Wl,--gc-sections     Perform the dead code elimination.
# --specs=nano.specs    Link with newlib-nano.
# --specs=nosys.specs   No syscalls, provide empty implementations for the POSIX system calls.
set(CMAKE_EXE_LINKER_FLAGS "${MCPU_FLAGS} ${VFP_FLAGS} -Wl,--gc-sections --specs=nano.specs --specs=nosys.specs" CACHE INTERNAL "Linker options")

#---------------------------------------------------------------------------------------
# Set compiler debug flags
#---------------------------------------------------------------------------------------
# -Og   Enables optimizations that do not interfere with debugging.
# -g    Produce debugging information in the operating system’s native format.
set(CMAKE_C_FLAGS_DEBUG "-O0 -g" CACHE INTERNAL "C compiler options for debug configuration")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g" CACHE INTERNAL "C++ compiler options for debug configuration")
set(CMAKE_ASM_FLAGS_DEBUG "-g" CACHE INTERNAL "Assembly compiler options for debug configuration")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "")

#---------------------------------------------------------------------------------------
# Set compiler release flags
#---------------------------------------------------------------------------------------
# -Os   Optimize for size. -Os enables all -O2 optimizations.
# -flto Runs the standard link-time optimizer.
set(CMAKE_C_FLAGS_RELEASE "-O3" CACHE INTERNAL "C compiler options for release configuration")
set(CMAKE_CXX_FLAGS_RELEASE "-O3" CACHE INTERNAL "C++ compiler options for release configuration")
set(CMAKE_ASM_FLAGS_RELEASE "-O3" CACHE INTERNAL "Assembly options for release configuration")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "-flto" CACHE INTERNAL "Linker options for release configuration")


#---------------------------------------------------------------------------------------
# Set compilers
#---------------------------------------------------------------------------------------
set(CMAKE_C_COMPILER ${TARGET_TRIPLET}gcc CACHE INTERNAL "C Compiler")
set(CMAKE_CXX_COMPILER ${TARGET_TRIPLET}g++ CACHE INTERNAL "C++ Compiler")
set(CMAKE_ASM_COMPILER ${TARGET_TRIPLET}gcc CACHE INTERNAL "ASM Compiler")
set(CMAKE_LINKER ${TARGET_TRIPLET}gcc)
set(CMAKE_SIZE_UTIL ${TARGET_TRIPLET}size)
set(CMAKE_OBJCOPY ${TARGET_TRIPLET}objcopy)
set(CMAKE_OBJDUMP ${TARGET_TRIPLET}objdump)
set(CMAKE_NM_UTIL ${TARGET_TRIPLET}gcc-nm)
set(CMAKE_AR ${TARGET_TRIPLET}gcc-ar)
set(CMAKE_RANLIB ${TARGET_TRIPLET}gcc-ranlib)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

