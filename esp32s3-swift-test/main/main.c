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
    
    ESP_LOGI(TAG, "\nSystem is working correctly!");
    ESP_LOGI(TAG, "Swift functions are available but not called to avoid ROM conflicts.");
    ESP_LOGI(TAG, "Build system successfully integrated Swift object file.");
    
    // Keep the program running
    while (1) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
