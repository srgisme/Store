import XCTest
@testable import Store

final class StoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Store().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
