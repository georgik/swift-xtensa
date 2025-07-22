# Register the component with C sources and Swift integration
idf_component_register(
    SRCS "main.c" "atomic_stubs.c" "swift_wrapper.c"
    INCLUDE_DIRS "."
    PRIV_REQUIRES "esp_hw_support"
)

idf_build_get_property(target IDF_TARGET)
idf_build_get_property(arch IDF_TARGET_ARCH)

# Validate target architecture
if(NOT "${arch}" STREQUAL "xtensa")
    message(FATAL_ERROR "This project currently only supports Xtensa ESP32-S3 targets, got: ${target} (${arch})")
endif()

# Set up custom Swift compiler path for Xtensa targets
set(SWIFT_COMPILER "${CMAKE_CURRENT_SOURCE_DIR}/../../install/bin/swift-frontend")
message(STATUS "Using custom Swift Xtensa compiler: ${SWIFT_COMPILER}")

# Check if Swift compiler exists
if(NOT EXISTS "${SWIFT_COMPILER}")
    message(FATAL_ERROR "Swift compiler not found at: ${SWIFT_COMPILER}\nPlease run ../swift-xtensa-build.sh first to build the compiler")
endif()

# Check if ESP-IDF environment is set up
if(NOT DEFINED ENV{IDF_PATH})
    message(FATAL_ERROR "ESP-IDF environment not set up. Please run: source ~/esp-idf/export.sh")
endif()

# Swift source files
set(SWIFT_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/../test_simple.swift"
)

# TODO: Add actual Swift compilation when standard library issues are resolved
# For now, swift_wrapper.c provides the Swift function implementations
# The following custom command is a placeholder for future Swift-to-LLVM IR compilation:
#
# add_custom_command(
#     OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.o"
#     COMMAND "${SWIFT_COMPILER}" -frontend
#             -emit-irgen
#             -target xtensa-esp32s3-none-elf
#             -parse-as-library
#             -nostdimport
#             -enable-builtin-module
#             -primary-file "${SWIFT_SOURCES}"
#             -o "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.ll"
#     COMMAND xtensa-esp32s3-elf-gcc -c
#             -mlongcalls
#             -ffunction-sections
#             -fdata-sections
#             -Os
#             -o "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.o"
#             "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.ll"
#     DEPENDS ${SWIFT_SOURCES}
#     COMMENT "Compiling Swift sources to Xtensa object files"
#     VERBATIM
# )
# 
# add_custom_target(swift_compilation DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.o")
# add_dependencies(${COMPONENT_LIB} swift_compilation)
# target_link_libraries(${COMPONENT_LIB} INTERFACE "${CMAKE_CURRENT_BINARY_DIR}/swift_functions.o")

message(STATUS "Swift integration: Using C wrapper implementation (swift_wrapper.c)")
message(STATUS "Swift sources: ${SWIFT_SOURCES}")
message(STATUS "TODO: Enable direct Swift compilation when standard library support is available")

# Add linker script fragment for Swift sections
target_link_options(${COMPONENT_LIB} INTERFACE "-T" "${CMAKE_CURRENT_SOURCE_DIR}/swift_sections.ld")

# Force linker to include atomic stub functions
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_load_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_store_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_fetch_add_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_fetch_sub_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_compare_exchange_4")

# Force linker to use our string functions instead of ROM versions
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strlen")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strcpy")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strcmp")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strncpy")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strcat")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,strncmp")

# Override ROM functions with our implementations
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strlen")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strcpy")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strcmp")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strncpy")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strcat")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,--wrap=strncmp")

# Add stronger symbol overrides to avoid ROM conflicts
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-defsym=__real_strlen=strlen")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-defsym=__real_strcpy=strcpy")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-defsym=__real_strcmp=strcmp")
