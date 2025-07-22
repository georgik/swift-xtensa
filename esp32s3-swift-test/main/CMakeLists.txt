# Register the app as an IDF component with C sources and Swift integration
idf_component_register(
    SRCS "main.c" "atomic_stubs.c"
    PRIV_INCLUDE_DIRS "."
)

idf_build_get_property(target IDF_TARGET)
idf_build_get_property(arch IDF_TARGET_ARCH)

# Set up custom Swift compiler path for Xtensa targets
if("${arch}" STREQUAL "xtensa")
    set(CMAKE_Swift_COMPILER "${CMAKE_CURRENT_SOURCE_DIR}/../../install/bin/swiftc")
    message(STATUS "Using custom Swift Xtensa compiler: ${CMAKE_Swift_COMPILER}")
else()
    message(FATAL_ERROR "This project currently only supports Xtensa ESP32-S3 targets, got: ${target} (${arch})")
endif()

# Check if Swift compiler exists
if(NOT EXISTS "${CMAKE_Swift_COMPILER}")
    message(FATAL_ERROR "Swift compiler not found at: ${CMAKE_Swift_COMPILER}\nPlease run ../../swift-xtensa-build.sh first to build the compiler")
endif()

# Extract the -march flag and remove any vendor-specific extensions (_x*)
string(REGEX MATCH "-march=[^ ]+" march_flag "${CMAKE_C_FLAGS}")
string(REGEX REPLACE "_x[^ ]*" "" march_flag "${march_flag}")

# Extract the -mabi flag or set a default value if not present
string(REGEX MATCH "-mabi=[^ ]+" mabi_flag "${CMAKE_C_FLAGS}")
if("${mabi_flag}" STREQUAL "")
    set(mabi_flag "-mabi=ilp32")
endif()

# Clear the default COMPILE_OPTIONS which include a lot of C/C++ specific compiler flags that the Swift compiler will not accept
get_target_property(var ${COMPONENT_LIB} COMPILE_OPTIONS)
set_target_properties(${COMPONENT_LIB} PROPERTIES COMPILE_OPTIONS "")

# Compute -Xcc flags to set up the C and C++ header search paths for Swift (for bridging header).
set(SWIFT_INCLUDES)
foreach(dir ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-Xcc ")
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-I${dir} ")
endforeach()
foreach(dir ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-Xcc ")
    string(CONCAT SWIFT_INCLUDES ${SWIFT_INCLUDES} "-I${dir} ")
endforeach()

# Swift compiler flags for Xtensa ESP32-S3 (without embedded Swift feature)
target_compile_options(${COMPONENT_LIB} PUBLIC "$<$<COMPILE_LANGUAGE:Swift>:SHELL:
        -target xtensa-esp32s3-none-elf
        -Xfrontend -function-sections -wmo -parse-as-library -Osize
        -Xcc -fno-pic -Xcc -fno-pie
        
        -pch-output-dir /tmp
        -Xfrontend -enable-single-module-llvm-emission
        
        ${SWIFT_INCLUDES}

        -import-bridging-header ${CMAKE_CURRENT_LIST_DIR}/BridgingHeader.h
    >")

# Enable Swift support in CMake, force Whole Module builds (required by Embedded Swift), and use "CMAKE_Swift_COMPILER_WORKS" to
# skip the trial compilations which don't (yet) correctly work when cross-compiling.
set(CMAKE_Swift_COMPILER_WORKS YES)
set(CMAKE_Swift_COMPILATION_MODE_DEFAULT wholemodule)
set(CMAKE_Swift_COMPILATION_MODE wholemodule)
enable_language(Swift)

# List of Swift source files to build.
target_sources(${COMPONENT_LIB}
    PRIVATE
    SwiftMain.swift
)

add_custom_command(
    TARGET ${COMPONENT_LIB}
    POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --remove-section .swift_modhash
            $<TARGET_FILE:${COMPONENT_LIB}> $<TARGET_FILE:${COMPONENT_LIB}>
)

message(STATUS "Swift integration: Using Embedded Swift with bridging header")
message(STATUS "Swift sources: SwiftMain.swift")
message(STATUS "Bridging header: BridgingHeader.h")

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
