idf_component_register(SRCS "main.c" "atomic_stubs.c"
                    INCLUDE_DIRS "."
                    PRIV_REQUIRES "esp_hw_support")

# Add the Swift object file
target_link_libraries(${COMPONENT_LIB} INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/../test_simple.o")

# Add linker script fragment for Swift sections
target_link_options(${COMPONENT_LIB} INTERFACE "-T" "${CMAKE_CURRENT_SOURCE_DIR}/swift_sections.ld")

# Force linker to include atomic stub functions
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_load_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_store_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_fetch_add_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_fetch_sub_4")
target_link_options(${COMPONENT_LIB} INTERFACE "-Wl,-u,__atomic_compare_exchange_4")
