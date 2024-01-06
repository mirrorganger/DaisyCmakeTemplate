# This assumes libdaisy and daisy exists both as submodules in the top directory.

include(${CMAKE_CURRENT_LIST_DIR}/helper-functions.cmake)

############## SETTINGS ##########################
set(LIBDAISY_DIR ${CMAKE_SOURCE_DIR}/libDaisy)
set(DAISYSP_DIR  ${CMAKE_SOURCE_DIR}/DaisySP)
set(DAISYSP_LIB DaisySP)
set(OCD_DIR /usr/local/share/openocd/scripts) # @todo : make this configurable 
set(PGM_DEVICE interface/stlink.cfg)
set(CHIPSET stm32h7x)
set(BOOT_FILES_FILTER_MASK *.bin)
find_files_matching_patterns(DAISY_BOOTLOADER ${LIBDAISY_DIR}/core ${BOOT_FILES_FILTER_MASK})

############## MEMORY AND BOOTLOADER  #############################
# Taken from Memory sections defined in the linker script
set(FLASH_ADDRESS 0x08000000)
set(QSPI_ADDRESS 0x90040000)

if(${APP_TYPE} STREQUAL "BOOT_QSPI")
    message(STATUS "${APP_TYPE} selected")
    message(STATUS "Daisy bootloader : ${DAISY_BOOTLOADER}")
    set(LINKER_SCRIPT ${LIBDAISY_DIR}/core/STM32H750IB_qspi.lds)
    set(LOAD_ADDRESS ${QSPI_ADDRESS})
    set(BOOTLOADER_ADDRESS ${FLASH_ADDRESS})
elseif(${APP_TYPE} STREQUAL "BOOT_SRAM")
    message(STATUS "${APP_TYPE} selected")
    message(STATUS "Daisy bootloader : ${DAISY_BOOTLOADER}")
    set(LINKER_SCRIPT ${LIBDAISY_DIR}/core/STM32H750IB_sram.lds)
    set(LOAD_ADDRESS ${QSPI_ADDRESS})
    set(BOOTLOADER_ADDRESS ${FLASH_ADDRESS})
else()
    message(STATUS "${APP_TYPE} selected")
    set(LINKER_SCRIPT ${LIBDAISY_DIR}/core/STM32H750IB_flash.lds)
    set(LOAD_ADDRESS ${FLASH_ADDRESS})
endif()


FUNCTION(add_daisy_library)
	set(options UNIT_TEST)
	set(oneValueArgs NAME PATH COMPONENT)
	set(multiValueArgs DEPENDS EXTERNAL_DEPENDS)
	
	cmake_parse_arguments(LIBRARY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

	if (NOT "${LIBRARY_PATH}" STREQUAL "")
		set(LIBRARY_PATH "${LIBRARY_PATH}/")
	endif()

	set(HEADER_FILES_FILTER_MASK *.h *.hpp)
	set(SOURCE_FILES_FILTER_MASK *.cpp *.cc)

	find_files_matching_patterns(publicIncludes ${LIBRARY_PATH}include "${HEADER_FILES_FILTER_MASK}")
	find_files_matching_patterns(privateIncludes ${LIBRARY_PATH}src "${HEADER_FILES_FILTER_MASK}")
	find_files_matching_patterns(src ${LIBRARY_PATH}src "${SOURCE_FILES_FILTER_MASK}")
	
	add_library(${LIBRARY_NAME} ${publicIncludes} ${src} ${privateIncludes})

    target_link_libraries(${LIBRARY_NAME}
        PRIVATE
        daisy
        ${DAISYSP_LIB}
        c
        m
        nosys
    )

	if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${LIBRARY_PATH}include")
		message(STATUS "${LIBRARY_PATH}")
		target_include_directories(${LIBRARY_NAME} PUBLIC ${LIBRARY_PATH}include)
	endif()
	if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${LIBRARY_PATH}src")
		target_include_directories(${LIBRARY_NAME} PRIVATE ${LIBRARY_PATH}src)
	endif()

	__add_dependencies(${LIBRARY_NAME} "${LIBRARY_DEPENDS}" "${LIBRARY_EXTERNAL_DEPENDS}")
	# add_dependencies(ALL_COMPILE ${LIBRARY_NAME})
ENDFUNCTION()


FUNCTION(add_daisy_firmware)
	set(options)
	set(oneValueArgs NAME)
	set(multiValueArgs DEPENDS EXTERNAL_DEPENDS)
	cmake_parse_arguments(FIRMWARE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
	
	set(SOURCE_FILES_FILTER_MASK *.cpp *.cc *.h *.hpp)

	find_files_matching_patterns(FIRMWARE_SOURCES src "${SOURCE_FILES_FILTER_MASK}")

	add_executable(${FIRMWARE_NAME} "${FIRMWARE_SOURCES}")
	set_property(TARGET ${EXECUTABLE_NAME} PROPERTY FOLDER ${EXECUTABLE_NAME})
	
    target_link_libraries(${FIRMWARE_NAME}
        PRIVATE
        daisy
        ${DAISYSP_LIB}
        c
        m
        nosys
    )
	__add_dependencies(${FIRMWARE_NAME} "${FIRMWARE_DEPENDS}" "${FIRMWARE_EXTERNAL_DEPENDS}")

    set_target_properties(${FIRMWARE_NAME} PROPERTIES
        CXX_STANDARD 14
        CXX_STANDARD_REQUIRED YES
        SUFFIX ".elf"
    )

   
    target_link_options(${FIRMWARE_NAME} PUBLIC
        -T ${LINKER_SCRIPT}
        -Wl,-Map=${FIRMWARE_NAME}.map,--cref
        -Wl,--check-sections
        -Wl,--unresolved-symbols=report-all
        -Wl,--warn-common
        -Wl,--warn-section-align
        -Wl,--print-memory-usage
    )

	install(TARGETS ${FIRMWARE_NAME} DESTINATION ${CMAKE_SOURCE_DIR}/products)

    add_custom_command(TARGET ${FIRMWARE_NAME} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY}
        ARGS -O ihex
        -S ${FIRMWARE_NAME}.elf
        ${FIRMWARE_NAME}.hex
        BYPRODUCTS
        ${FIRMWARE_NAME}.hex
        COMMENT "Generating ${FIRMWARE_NAME} HEX image"
        VERBATIM)

    add_custom_command(TARGET ${FIRMWARE_NAME} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY}
        ARGS -O binary
        -S ${FIRMWARE_NAME}.elf
        ${FIRMWARE_NAME}.bin
        BYPRODUCTS
        ${FIRMWARE_NAME}.bin
        COMMENT "Generating ${FIRMWARE_NAME} binary image"
    VERBATIM)

    add_custom_command(
        TARGET ${FIRMWARE_NAME}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND}
        ARGS -E copy ${FIRMWARE_NAME}.bin ${FIRMWARE_NAME}.elf ${CMAKE_SOURCE_DIR}/products
        COMMENT "Copying ${FIRMWARE_NAME} binary products to ${CMAKE_SOURCE_DIR}/products folder"
    )

    add_custom_target(upload-dfu-${FIRMWARE_NAME} DEPENDS ${FIRMWARE_NAME}
        COMMAND dfu-util -a 0 -s ${LOAD_ADDRESS}:leave -D ${FIRMWARE_NAME}.bin -d ,0483:df11
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/products
        COMMENT "Uploading ${FIRMWARE_NAME} to board...")

    add_custom_target(upload-openocd-${FIRMWARE_NAME} DEPENDS ${FIRMWARE_NAME}
        COMMAND openocd -s "${OCD_DIR}" -f "${PGM_DEVICE}" -f "target/${CHIPSET}.cfg" -c "program ${FIRMWARE_NAME}.elf verify reset exit"
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/products
        COMMENT "Uploading ${FIRMWARE_NAME} to board...")

    add_custom_target(upload-bootloader-${FIRMWARE_NAME} DEPENDS ${FIRMWARE_NAME}
        COMMAND dfu-util -a 0 -s ${BOOTLOADER_ADDRESS}:leave -D ${DAISY_BOOTLOADER} -d ,0483:df11
        WORKING_DIRECTORY ${LIBDAISY_DIR}/core
        COMMENT "Uploading daisy-booloader to board...")
ENDFUNCTION()
