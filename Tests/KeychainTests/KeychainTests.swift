    import XCTest
    @testable import Keychain

    final class KeychainTests: XCTestCase {
        let client = KeychainClient()
        
        func testInsertAndFetch() throws {
            Thread.sleep(until: .now + 0.5)
            let key = "myValue"
            let value = UUID()
            try client.insert(value, forKey: key)
            let fetchedValue : UUID? = try client.value(forKey: key)
            XCTAssertEqual(value, fetchedValue)
        }
    }
