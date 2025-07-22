#ifndef SWIFT_FUNCTIONS_H
#define SWIFT_FUNCTIONS_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Swift function declarations for ESP32-S3
uint32_t swift_add(uint32_t a, uint32_t b);
uint32_t swift_multiply(uint32_t a, uint32_t b);
uint32_t swift_subtract(uint32_t a, uint32_t b);
uint32_t swift_shift(uint32_t a, uint32_t b);
uint32_t swift_compute(uint32_t x, uint32_t y);
uint32_t swift_power(uint32_t base, uint32_t exponent);
uint32_t swift_fibonacci(uint32_t n);
char swift_char_test(const char* name);
uint32_t swift_string_length(const char* name);

#ifdef __cplusplus
}
#endif

#endif // SWIFT_FUNCTIONS_H
