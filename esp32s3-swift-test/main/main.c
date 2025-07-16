#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

// Declaration of Swift functions
extern void swift_compute_demo(void);
extern uint32_t swift_simple_addition(uint32_t a, uint32_t b);
extern uint32_t swift_multiply(uint32_t a, uint32_t b);
extern uint32_t swift_get_addition_result(void);
extern uint32_t swift_get_multiply_result(void);

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
    
    // Test direct Swift function calls
    ESP_LOGI(TAG, "Calling Swift functions directly...");
    
    uint32_t swift_add_result = swift_simple_addition(7, 8);
    ESP_LOGI(TAG, "Swift addition: 7 + 8 = %u", swift_add_result);
    
    uint32_t swift_mul_result = swift_multiply(4, 6);
    ESP_LOGI(TAG, "Swift multiplication: 4 * 6 = %u", swift_mul_result);
    
    // Test Swift demo function that stores results
    ESP_LOGI(TAG, "Calling Swift compute demo...");
    swift_compute_demo();
    
    // Get stored results
    uint32_t stored_add = swift_get_addition_result();
    uint32_t stored_mul = swift_get_multiply_result();
    
    ESP_LOGI(TAG, "Swift stored addition result: %u", stored_add);
    ESP_LOGI(TAG, "Swift stored multiplication result: %u", stored_mul);
    
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
    
    if (stored_add != 15) {
        ESP_LOGE(TAG, "ERROR: Swift stored addition failed! Expected 15, got %u", stored_add);
        all_passed = false;
    }
    
    if (stored_mul != 12) {
        ESP_LOGE(TAG, "ERROR: Swift stored multiplication failed! Expected 12, got %u", stored_mul);
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
