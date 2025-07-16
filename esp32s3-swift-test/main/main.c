#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"

// Declaration of our Swift functions
extern void swift_simple_loop(void);
extern void swift_counter_loop(void);

static const char* TAG = "swift_test";

void app_main(void)
{
    ESP_LOGI(TAG, "Starting Swift ESP32-S3 simple test");
    
    ESP_LOGI(TAG, "About to call Swift simple loop function");
    
    // Call our Swift function - this should loop forever
    swift_simple_loop();
    
    // This line should never be reached
    ESP_LOGI(TAG, "Swift function returned (this should not happen)");
}
