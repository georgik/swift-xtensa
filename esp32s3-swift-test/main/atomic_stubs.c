#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
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

// Swift runtime stubs for ESP32-S3
// These provide minimal implementations of Swift runtime functions

void swift_beginAccess(void *pointer, void *buffer, unsigned flags, void *pc)
{
    // Minimal implementation - just return for now
    // In full Swift runtime, this would handle exclusive access
}

void swift_endAccess(void *buffer)
{
    // Minimal implementation - just return for now
    // In full Swift runtime, this would end exclusive access
}

// String function stubs to avoid ROM conflicts
// These provide RAM-based implementations instead of ROM functions
// Using strong symbols to override any ROM versions

// Strong symbol implementations that will override ROM functions
size_t __attribute__((used)) strlen(const char *s)
{
    size_t len = 0;
    while (s[len]) {
        len++;
    }
    return len;
}

char * __attribute__((used)) strcpy(char *dest, const char *src)
{
    char *d = dest;
    while ((*d++ = *src++));
    return dest;
}

int __attribute__((used)) strcmp(const char *s1, const char *s2)
{
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

char * __attribute__((used)) strncpy(char *dest, const char *src, size_t n)
{
    if (n == 0) return dest;
    size_t i;
    
    for (i = 0; i < n && src[i] != '\0'; i++) {
        dest[i] = src[i];
    }
    for (; i < n; i++) {
        dest[i] = '\0';
    }
    return dest;
}

// Additional string functions that might be called
char * __attribute__((used)) strcat(char *dest, const char *src)
{
    char *d = dest;
    while (*d) d++;  // Find end of dest
    while ((*d++ = *src++));
    return dest;
}

int __attribute__((used)) strncmp(const char *s1, const char *s2, size_t n)
{
    if (n == 0) return 0;
    while (n-- && *s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return n ? *(unsigned char*)s1 - *(unsigned char*)s2 : 0;
}

// Wrapper functions for --wrap linker flags
// These redirect calls to our implementations

size_t __wrap_strlen(const char *s)
{
    return strlen(s);
}

char *__wrap_strcpy(char *dest, const char *src)
{
    return strcpy(dest, src);
}

int __wrap_strcmp(const char *s1, const char *s2)
{
    return strcmp(s1, s2);
}

char *__wrap_strncpy(char *dest, const char *src, size_t n)
{
    return strncpy(dest, src, n);
}

char *__wrap_strcat(char *dest, const char *src)
{
    return strcat(dest, src);
}

int __wrap_strncmp(const char *s1, const char *s2, size_t n)
{
    return strncmp(s1, s2, n);
}
