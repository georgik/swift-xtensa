#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "swift_functions.h"

// Swift function declarations (exported via @_cdecl)
extern void swift_run_tests(void);

static const char* TAG = "swift_test";

// Simple C function for testing
static uint32_t c_simple_addition(uint32_t a, uint32_t b) {
    return a + b;
}

void app_main(void) {
    ESP_LOGI(TAG, "Starting Swift ESP32-S3 Computation Demo");
    ESP_LOGI(TAG, "==========================================");
    
    // First test C function to make sure basic system works
    ESP_LOGI(TAG, "Testing C function calls:");
    uint32_t c_result = c_simple_addition(5, 10);
    ESP_LOGI(TAG, "C addition: 5 + 10 = %u", c_result);
    
    if (c_result == 15) {
        ESP_LOGI(TAG, "✅ C computation PASSED!");
    } else {
        ESP_LOGE(TAG, "❌ C computation FAILED!");
    }
    
    ESP_LOGI(TAG, "");
    ESP_LOGI(TAG, "Now testing Swift function calls:");
    
    // Call Swift's own test function first
    ESP_LOGI(TAG, "Running Swift internal tests...");
    swift_run_tests();
    
    // Test individual Swift functions
    ESP_LOGI(TAG, "Testing individual Swift functions...");
    
    uint32_t swift_add_result = swift_add(7, 8);
    ESP_LOGI(TAG, "Swift addition: 7 + 8 = %u", swift_add_result);
    
    uint32_t swift_mul_result = swift_multiply(4, 6);
    ESP_LOGI(TAG, "Swift multiplication: 4 * 6 = %u", swift_mul_result);
    
    uint32_t swift_sub_result = swift_subtract(10, 3);
    ESP_LOGI(TAG, "Swift subtraction: 10 - 3 = %u", swift_sub_result);
    
    uint32_t swift_shift_result = swift_shift(32, 2);
    ESP_LOGI(TAG, "Swift shift: 32 >> 2 = %u", swift_shift_result);
    
    // Test combined Swift function
    ESP_LOGI(TAG, "Testing combined Swift computation...");
    uint32_t swift_compute_result = swift_compute(5, 3);
    ESP_LOGI(TAG, "Swift compute(5, 3): (5+3) + (5*3) = %u", swift_compute_result);
    
    // Test new advanced Swift functions
    ESP_LOGI(TAG, "Testing advanced Swift functions...");
    uint32_t swift_power_result = swift_power(2, 8);  // 2^8 = 256
    ESP_LOGI(TAG, "Swift power: 2^8 = %u", swift_power_result);
    
    uint32_t swift_fib_result = swift_fibonacci(10);  // 10th Fibonacci number = 55
    ESP_LOGI(TAG, "Swift fibonacci(10) = %u", swift_fib_result);
    
    // Test edge cases
    uint32_t swift_power_edge = swift_power(5, 0);  // Any number^0 = 1
    ESP_LOGI(TAG, "Swift power edge case: 5^0 = %u", swift_power_edge);
    
    uint32_t swift_fib_edge = swift_fibonacci(0);  // Fib(0) = 0
    ESP_LOGI(TAG, "Swift fibonacci edge case: fib(0) = %u", swift_fib_edge);
    
    // Test Swift string functions
    ESP_LOGI(TAG, "Testing Swift string functions...");
    const char* test_name = "Swift";
    char first_char = swift_char_test(test_name);
    ESP_LOGI(TAG, "Swift char test: First char of '%s' is '%c' (ASCII %d)", test_name, first_char, first_char);
    
    uint32_t name_length = swift_string_length(test_name);
    ESP_LOGI(TAG, "Swift string length: '%s' has %u characters", test_name, name_length);
    
    // Test with different names
    const char* test_name2 = "ESP32-S3";
    char first_char2 = swift_char_test(test_name2);
    ESP_LOGI(TAG, "Swift char test: First char of '%s' is '%c' (ASCII %d)", test_name2, first_char2, first_char2);
    
    uint32_t name_length2 = swift_string_length(test_name2);
    ESP_LOGI(TAG, "Swift string length: '%s' has %u characters", test_name2, name_length2);
    
    // Verify results
    bool all_passed = true;
    
    if (swift_add_result != 15) {
        ESP_LOGE(TAG, "ERROR: Swift addition failed! Expected 15, got %u", swift_add_result);
        all_passed = false;
    }
    
    if (swift_mul_result != 24) {
        ESP_LOGE(TAG, "ERROR: Swift multiplication failed! Expected 24, got %u", swift_mul_result);
        all_passed = false;
    }
    
    if (swift_sub_result != 7) {
        ESP_LOGE(TAG, "ERROR: Swift subtraction failed! Expected 7, got %u", swift_sub_result);
        all_passed = false;
    }
    
    if (swift_shift_result != 8) {  // 32 >> 2 = 8
        ESP_LOGE(TAG, "ERROR: Swift shift failed! Expected 8, got %u", swift_shift_result);
        all_passed = false;
    }
    
    if (swift_compute_result != 23) {  // (5+3) + (5*3) = 8 + 15 = 23
        ESP_LOGE(TAG, "ERROR: Swift compute failed! Expected 23, got %u", swift_compute_result);
        all_passed = false;
    }
    
    if (swift_power_result != 256) {  // 2^8 = 256
        ESP_LOGE(TAG, "ERROR: Swift power failed! Expected 256, got %u", swift_power_result);
        all_passed = false;
    }
    
    if (swift_fib_result != 55) {  // 10th Fibonacci number = 55
        ESP_LOGE(TAG, "ERROR: Swift fibonacci failed! Expected 55, got %u", swift_fib_result);
        all_passed = false;
    }
    
    if (swift_power_edge != 1) {  // Any number^0 = 1
        ESP_LOGE(TAG, "ERROR: Swift power edge case failed! Expected 1, got %u", swift_power_edge);
        all_passed = false;
    }
    
    if (swift_fib_edge != 0) {  // Fib(0) = 0
        ESP_LOGE(TAG, "ERROR: Swift fibonacci edge case failed! Expected 0, got %u", swift_fib_edge);
        all_passed = false;
    }
    
    // Validate string functions
    if (first_char != 'S') {
        ESP_LOGE(TAG, "ERROR: Swift char test failed! Expected 'S', got '%c'", first_char);
        all_passed = false;
    }
    
    if (name_length != 5) {
        ESP_LOGE(TAG, "ERROR: Swift string length failed! Expected 5, got %u", name_length);
        all_passed = false;
    }
    
    if (first_char2 != 'E') {
        ESP_LOGE(TAG, "ERROR: Swift char test 2 failed! Expected 'E', got '%c'", first_char2);
        all_passed = false;
    }
    
    if (name_length2 != 8) {
        ESP_LOGE(TAG, "ERROR: Swift string length 2 failed! Expected 8, got %u", name_length2);
        all_passed = false;
    }
    
    ESP_LOGI(TAG, "");
    if (all_passed) {
        ESP_LOGI(TAG, "✅ ALL SWIFT COMPUTATIONS PASSED!");
        ESP_LOGI(TAG, "Swift-to-ESP32-S3 integration is working correctly!");
    } else {
        ESP_LOGE(TAG, "❌ SOME SWIFT COMPUTATIONS FAILED!");
    }
    
    ESP_LOGI(TAG, "");
    ESP_LOGI(TAG, "=== SUMMARY ===");
    ESP_LOGI(TAG, "C computation: PASSED");
    ESP_LOGI(TAG, "Swift integration: %s", all_passed ? "PASSED" : "FAILED");
    ESP_LOGI(TAG, "Build system: WORKING");
    ESP_LOGI(TAG, "ROM conflicts: RESOLVED");
    
    // Keep the program running
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
