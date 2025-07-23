//===----------------------------------------------------------------------===//
//
// Swift ESP32-S3 Mathematical Functions Implementation
//
// This file provides Swift implementations of mathematical functions
// that can be called from C code via @_cdecl exports
//
//===----------------------------------------------------------------------===//

// Basic arithmetic functions
@_cdecl("swift_add")
public func swiftAdd(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a + b
}

@_cdecl("swift_multiply") 
public func swiftMultiply(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a * b
}

@_cdecl("swift_subtract")
public func swiftSubtract(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a - b
}

@_cdecl("swift_shift")
public func swiftShift(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a >> (b & 31)  // Safe shift with mask
}

@_cdecl("swift_compute")
public func swiftCompute(_ x: UInt32, _ y: UInt32) -> UInt32 {
    let sum = swiftAdd(x, y)
    let product = swiftMultiply(x, y)
    return swiftAdd(sum, product)  // Return sum + product
}

// Power function using repeated multiplication
@_cdecl("swift_power")
public func swiftPower(_ base: UInt32, _ exponent: UInt32) -> UInt32 {
    if exponent == 0 {
        return 1
    }
    
    var result: UInt32 = 1
    var exp = exponent
    var b = base
    
    // Use binary exponentiation for efficiency
    while exp > 0 {
        if (exp & 1) == 1 {
            result = swiftMultiply(result, b)
        }
        b = swiftMultiply(b, b)
        exp = swiftShift(exp, 1)  // exp >>= 1
    }
    
    return result
}

// Fibonacci function (iterative)
@_cdecl("swift_fibonacci") 
public func swiftFibonacci(_ n: UInt32) -> UInt32 {
    if n <= 1 {
        return n
    }
    
    var a: UInt32 = 0
    var b: UInt32 = 1
    var i: UInt32 = 2
    
    while i <= n {
        let temp = swiftAdd(a, b)
        a = b
        b = temp
        i = swiftAdd(i, 1)
    }
    
    return b
}

// String functions for testing C interoperability
@_cdecl("swift_char_test")
public func swiftCharTest(_ name: UnsafePointer<CChar>) -> CChar {
    return name[0]
}

@_cdecl("swift_string_length")
public func swiftStringLength(_ name: UnsafePointer<CChar>) -> UInt32 {
    var len: UInt32 = 0
    while name[Int(len)] != 0 {
        len = len + 1
    }
    return len
}

// Swift test runner called from C
@_cdecl("swift_run_tests")
public func swiftRunTests() {
    // Get ESP logging tag
    let tag = "swift_embedded".withCString { $0 }
    
    // Test basic math
    let addResult = swiftAdd(7, 8)
    let mulResult = swiftMultiply(4, 6)
    let fibResult = swiftFibonacci(10)
    
    // Use ESP-IDF logging (these call the C functions via bridging header)
    esp_log_write(ESP_LOG_INFO, tag, "Swift embedded test starting")
    esp_log_write(ESP_LOG_INFO, tag, "Add test: 7 + 8 = %d", addResult)
    esp_log_write(ESP_LOG_INFO, tag, "Multiply test: 4 * 6 = %d", mulResult) 
    esp_log_write(ESP_LOG_INFO, tag, "Fibonacci test: fib(10) = %d", fibResult)
    esp_log_write(ESP_LOG_INFO, tag, "Swift embedded test completed")
}
