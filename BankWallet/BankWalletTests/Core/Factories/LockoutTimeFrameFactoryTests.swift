import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LockoutTimeFrameFactoryTests: XCTestCase {
    private var factory: LockoutTimeFrameFactory!

    override func setUp() {
        super.setUp()

        factory = LockoutTimeFrameFactory()
    }

    override func tearDown() {
        factory = nil

        super.tearDown()
    }

    func testUnlockTime0Min() {
        let zeroMinutes: TimeInterval = 0
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 5, lockoutTimestamp: 1, uptime: 400), zeroMinutes)
    }

    func testUnlockTime5Min() {
        let fiveMinutes: TimeInterval = 60 * 5
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 5, lockoutTimestamp: 1, uptime: 1), fiveMinutes)
    }

    func testUnlockTime10Min() {
        let tenMinutes: TimeInterval = 60 * 10
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 6, lockoutTimestamp: 1, uptime: 1), tenMinutes)
    }

    func testUnlockTime15Min() {
        let fifteenMinutes: TimeInterval = 60 * 15
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 7, lockoutTimestamp: 1, uptime: 1), fifteenMinutes)
    }

    func testUnlockTime30Min() {
        let thirtyMinutes: TimeInterval = 60 * 30
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 8, lockoutTimestamp: 1, uptime: 1), thirtyMinutes)
    }

    func testUnlockTimeNotMore30Min() {
        let thirtyMinutes: TimeInterval = 60 * 30
        XCTAssertEqual(factory.lockoutTimeFrame(failedAttempts: 9, lockoutTimestamp: 1, uptime: 1), thirtyMinutes)
    }

}
