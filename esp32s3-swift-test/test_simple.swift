// Simple Swift computation for ESP32-S3
// Minimal Swift code without Foundation to avoid runtime complexity

// Global variables to store computation results
var additionResult: UInt32 = 0
var multiplyResult: UInt32 = 0

// Simple addition function that matches our C implementation
@_cdecl("swift_simple_addition")
public func swiftSimpleAddition(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a &+ b  // Use overflow-safe addition
}

// Simple multiplication function
@_cdecl("swift_multiply")
public func swiftMultiply(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a &* b  // Use overflow-safe multiplication
}

// Main computation demo function
@_cdecl("swift_compute_demo")
public func swiftComputeDemo() {
    // Perform basic computations and store results
    additionResult = swiftSimpleAddition(5, 10)
    multiplyResult = swiftMultiply(3, 4)
}

// Getter functions for C to access results
@_cdecl("swift_get_addition_result")
public func swiftGetAdditionResult() -> UInt32 {
    return additionResult
}

@_cdecl("swift_get_multiply_result")
public func swiftGetMultiplyResult() -> UInt32 {
    return multiplyResult
}
