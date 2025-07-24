// Minimal bare metal Swift application for ESP32-S3
// No imports, no standard library dependencies

// Basic memory-mapped register access
func writeReg32(_ address: UInt32, _ value: UInt32) {
    UnsafeMutablePointer<UInt32>(bitPattern: address)!.pointee = value
}

func readReg32(_ address: UInt32) -> UInt32 {
    return UnsafePointer<UInt32>(bitPattern: address)!.pointee
}

// Simple delay function
func simpleDelay(_ count: UInt32) {
    var i: UInt32 = 0
    while i < count {
        i += 1
    }
}

// UART output functions
private func putChar(_ char: UInt8) {
    // Wait for UART FIFO to have space
    while (readReg32(UART_STATUS_REG) & 0xFF0000) >= 0x7E0000 {
        // FIFO full, wait
    }
    writeReg32(UART_FIFO_REG, UInt32(char))
}

private func putString(_ string: String) {
    for byte in string.utf8 {
        putChar(byte)
    }
}

private func putLine(_ string: String) {
    putString(string)
    putChar(13) // CR
    putChar(10) // LF
}

// Simple number printing
private func printNumber(_ number: UInt32) {
    if number == 0 {
        putChar(48) // '0'
        return
    }
    
    let digits = "0123456789"
    var temp = number
    var reversed: [UInt8] = []
    
    while temp > 0 {
        let digit = temp % 10
        reversed.append(digits.utf8[digits.utf8.index(digits.utf8.startIndex, offsetBy: Int(digit))])
        temp /= 10
    }
    
    for digit in reversed.reversed() {
        putChar(digit)
    }
}

// Hexadecimal printing
private func printHex32(_ value: UInt32) {
    putString("0x")
    let hexDigits = "0123456789ABCDEF"
    for i in (0..<8).reversed() {
        let nibble = (value >> (i * 4)) & 0xF
        let char = hexDigits.utf8[hexDigits.utf8.index(hexDigits.utf8.startIndex, offsetBy: Int(nibble))]
        putChar(char)
    }
}

// Disable watchdog timers
private func disableWatchdogs() {
    putLine("Disabling watchdog timers...")
    
    // Disable TIMG0 watchdog
    writeReg32(TIMG_WDTCONFIG0_REG, 0)
    
    // Disable TIMG1 watchdog  
    writeReg32(TIMG1_BASE + 0x0048, 0)
    
    putLine("Watchdogs disabled.")
}

// Initialize GPIO for LED
private func initializeLED() {
    putString("Initializing LED on GPIO")
    printNumber(LED_PIN)
    putLine("...")
    
    // Enable GPIO output
    let currentEnable = readReg32(GPIO_ENABLE_REG)
    writeReg32(GPIO_ENABLE_REG, currentEnable | (1 << LED_PIN))
    
    // Set initial state to OFF
    let currentOut = readReg32(GPIO_OUT_REG)
    writeReg32(GPIO_OUT_REG, currentOut & ~(1 << LED_PIN))
    
    putLine("LED initialized.")
}

// Control LED
private func setLED(on: Bool) {
    let currentOut = readReg32(GPIO_OUT_REG)
    if on {
        writeReg32(GPIO_OUT_REG, currentOut | (1 << LED_PIN))
    } else {
        writeReg32(GPIO_OUT_REG, currentOut & ~(1 << LED_PIN))
    }
}

// Simple arithmetic test functions
private func testArithmetic() -> Bool {
    putLine("=== Testing Swift Arithmetic on ESP32-S3 ===")
    
    // Test basic arithmetic
    let a: UInt32 = 15
    let b: UInt32 = 25
    let sum = a + b
    let product = a * b
    
    putString("15 + 25 = ")
    printNumber(sum)
    putLine("")
    
    putString("15 * 25 = ")  
    printNumber(product)
    putLine("")
    
    // Verify results
    if sum != 40 || product != 375 {
        putLine("❌ Arithmetic test FAILED!")
        return false
    }
    
    // Test Fibonacci
    putString("Fibonacci(10) = ")
    let fib10 = fibonacci(10)
    printNumber(fib10)
    putLine("")
    
    if fib10 != 55 {
        putLine("❌ Fibonacci test FAILED!")
        return false
    }
    
    putLine("✅ All arithmetic tests PASSED!")
    return true
}

// Fibonacci function
private func fibonacci(_ n: UInt32) -> UInt32 {
    if n <= 1 { return n }
    
    var a: UInt32 = 0
    var b: UInt32 = 1
    
    for _ in 2...n {
        let temp = a + b
        a = b
        b = temp
    }
    
    return b
}

// Main Swift entry point
@_cdecl("swift_main")
public func swiftMain() {
    // Basic startup message
    putLine("")
    putLine("=== ESP32-S3 Swift Bare Metal Demo ===")
    putLine("Architecture: Xtensa LX7")
    putLine("Compiler: Swift with Xtensa Support")
    putLine("")
    
    // System initialization
    disableWatchdogs()
    initializeLED()
    
    // Run arithmetic tests
    let testsPass = testArithmetic()
    
    if testsPass {
        putLine("")
        putLine("🎉 Swift running successfully on ESP32-S3!")
        putLine("All tests completed. Starting LED blink loop...")
        putLine("")
    }
    
    // Main loop with LED blinking
    var counter: UInt32 = 0
    
    while true {
        putString("Cycle ")
        printNumber(counter)
        putString(" - LED ON")
        putLine("")
        
        setLED(on: true)
        delayMicroseconds(500_000) // 500ms
        
        putString("Cycle ")
        printNumber(counter)
        putString(" - LED OFF")
        putLine("")
        
        setLED(on: false)
        delayMicroseconds(500_000) // 500ms
        
        counter += 1
        
        // Print status every 10 cycles
        if counter % 10 == 0 {
            putLine("--- 10 cycles completed ---")
            putString("GPIO_OUT register: ")
            printHex32(readReg32(GPIO_OUT_REG))
            putLine("")
            putString("GPIO_ENABLE register: ")
            printHex32(readReg32(GPIO_ENABLE_REG))
            putLine("")
        }
    }
}

// Standard library replacements for embedded environment
@_cdecl("posix_memalign")
public func posix_memalign(_ memptr: UnsafeMutablePointer<UnsafeMutableRawPointer?>, _ alignment: Int, _ size: Int) -> Int32 {
    memptr.pointee = nil
    return 12 // ENOMEM
}

@_cdecl("free")
public func free(_ ptr: UnsafeMutableRawPointer?) {
    // No-op for embedded systems
}

@_cdecl("putchar")
public func putchar(_ char: Int32) -> Int32 {
    putChar(UInt8(char))
    return char
}
