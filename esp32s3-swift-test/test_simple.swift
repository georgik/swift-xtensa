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

// Power function using repeated multiplication (safe for embedded)
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

// Fibonacci function (iterative, safe for embedded)
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

// Simple character manipulation function that returns first character of name
@_cdecl("swift_char_test")
public func swiftCharTest(_ name: UnsafePointer<CChar>) -> CChar {
    // Return the first character of the name
    return name[0]
}

// Simple string length function (manual implementation)
@_cdecl("swift_string_length")
public func swiftStringLength(_ name: UnsafePointer<CChar>) -> UInt32 {
    var len: UInt32 = 0
    while name[Int(len)] != 0 {
        len = len + 1
    }
    return len
}
