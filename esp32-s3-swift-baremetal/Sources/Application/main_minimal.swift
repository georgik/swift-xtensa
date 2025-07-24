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

// Main entry point
@_cdecl("app_main")
public func appMain() {
    // Simple GPIO setup for ESP32-S3
    let gpioBase: UInt32 = 0x60004000
    let gpioEnableReg = gpioBase + 0x0020
    let gpioOutReg = gpioBase + 0x0004
    let ledPin: UInt32 = 48
    
    // Enable GPIO 48 as output
    let currentEnable = readReg32(gpioEnableReg)
    writeReg32(gpioEnableReg, currentEnable | (1 << ledPin))
    
    // Main loop
    var counter: UInt32 = 0
    while true {
        // Turn LED on
        let currentOut = readReg32(gpioOutReg)
        writeReg32(gpioOutReg, currentOut | (1 << ledPin))
        
        // Delay
        simpleDelay(1000000)
        
        // Turn LED off
        writeReg32(gpioOutReg, currentOut & ~(1 << ledPin))
        
        // Delay
        simpleDelay(1000000)
        
        counter += 1
    }
}
