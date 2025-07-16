#include <stdint.h>
#include <stdbool.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// Atomic operations stubs for Swift on ESP32-S3
// These provide basic atomic operations needed by Swift runtime
// Using unsigned int to match built-in function signatures

unsigned int __atomic_load_4(const volatile void *ptr, int memorder)
{
    // For ESP32-S3, disable interrupts for atomic operation
    portDISABLE_INTERRUPTS();
    unsigned int result = *(const volatile unsigned int *)ptr;
    portENABLE_INTERRUPTS();
    return result;
}

void __atomic_store_4(volatile void *ptr, unsigned int val, int memorder)
{
    portDISABLE_INTERRUPTS();
    *(volatile unsigned int *)ptr = val;
    portENABLE_INTERRUPTS();
}

unsigned int __atomic_fetch_add_4(volatile void *ptr, unsigned int val, int memorder)
{
    portDISABLE_INTERRUPTS();
    unsigned int result = *(volatile unsigned int *)ptr;
    *(volatile unsigned int *)ptr = result + val;
    portENABLE_INTERRUPTS();
    return result;
}

unsigned int __atomic_fetch_sub_4(volatile void *ptr, unsigned int val, int memorder)
{
    portDISABLE_INTERRUPTS();
    unsigned int result = *(volatile unsigned int *)ptr;
    *(volatile unsigned int *)ptr = result - val;
    portENABLE_INTERRUPTS();
    return result;
}

bool __atomic_compare_exchange_4(volatile void *ptr, void *expected, unsigned int desired, bool weak, int success_memorder, int failure_memorder)
{
    portDISABLE_INTERRUPTS();
    unsigned int current = *(volatile unsigned int *)ptr;
    unsigned int expected_val = *(unsigned int *)expected;
    
    if (current == expected_val) {
        *(volatile unsigned int *)ptr = desired;
        portENABLE_INTERRUPTS();
        return true;
    } else {
        *(unsigned int *)expected = current;
        portENABLE_INTERRUPTS();
        return false;
    }
}
