@_silgen_name("swift_simple_loop")
public func swift_simple_loop() {
    // Simple infinite loop - no complex Swift features
    while true {
        // Just keep looping
    }
}

@_silgen_name("swift_counter_loop") 
public func swift_counter_loop() {
    var counter: UInt32 = 0
    while true {
        counter = counter &+ 1
        // Simple arithmetic to test basic operations
        if counter > 1000000 {
            counter = 0
        }
    }
}
