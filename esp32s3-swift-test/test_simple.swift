// Simple Swift computation for ESP32-S3
// Minimal Swift code without Foundation to avoid runtime complexity
// Pure functions without global state to minimize runtime dependencies

// Simple addition function
@_cdecl("swift_add")
public func swiftAdd(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a + b
}

// Simple multiplication function
@_cdecl("swift_multiply")
public func swiftMultiply(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a * b
}

// Simple subtraction function
@_cdecl("swift_subtract")
public func swiftSubtract(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a - b
}

// Simple shift function (safer than division)
@_cdecl("swift_shift")
public func swiftShift(_ a: UInt32, _ b: UInt32) -> UInt32 {
    return a >> (b & 31)  // Shift right by b positions (safe)
}

// Combined computation function
@_cdecl("swift_compute")
public func swiftCompute(_ x: UInt32, _ y: UInt32) -> UInt32 {
    let sum = swiftAdd(x, y)
    let product = swiftMultiply(x, y)
    return swiftAdd(sum, product)  // Return sum + product
}
