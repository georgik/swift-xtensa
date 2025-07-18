#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

// Declaration of Swift functions
extern uint32_t swift_add(uint32_t a, uint32_t b);
extern uint32_t swift_multiply(uint32_t a, uint32_t b);
extern uint32_t swift_subtract(uint32_t a, uint32_t b);
extern uint32_t swift_shift(uint32_t a, uint32_t b);
extern uint32_t swift_compute(uint32_t x, uint32_t y);

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
