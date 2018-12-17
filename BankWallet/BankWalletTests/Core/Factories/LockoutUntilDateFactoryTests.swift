import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LockoutUntilDateFactoryTests: XCTestCase {
    private var mockCurrentDateProvider: MockICurrentDateProvider!

    private var factory: LockoutUntilDateFactory!

    private let currentDate = Date()

    override func setUp() {
        super.setUp()

        mockCurrentDateProvider = MockICurrentDateProvider()
        stub(mockCurrentDateProvider) { mock in
            when(mock.currentDate.get).thenReturn(currentDate)
        }

        factory = LockoutUntilDateFactory(currentDateProvider: mockCurrentDateProvider)
    }

    override func tearDown() {
        mockCurrentDateProvider = nil
        factory = nil

        super.tearDown()
    }

    func testUnlockTime0Min() {
        let zeroMinutes = currentDate
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 5, lockoutTimestamp: 1, uptime: 400), zeroMinutes)
    }

    func testUnlockTime5Min() {
        let fiveMinutes = currentDate.addingTimeInterval(60 * 5)
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 5, lockoutTimestamp: 1, uptime: 1), fiveMinutes)
    }

    func testUnlockTime10Min() {
        let tenMinutes = currentDate.addingTimeInterval(60 * 10)
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 6, lockoutTimestamp: 1, uptime: 1), tenMinutes)
    }

    func testUnlockTime15Min() {
        let fifteenMinutes = currentDate.addingTimeInterval(60 * 15)
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 7, lockoutTimestamp: 1, uptime: 1), fifteenMinutes)
    }

    func testUnlockTime30Min() {
        let thirtyMinutes = currentDate.addingTimeInterval(60 * 30)
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 8, lockoutTimestamp: 1, uptime: 1), thirtyMinutes)
    }

    func testUnlockTimeNotMore30Min() {
        let thirtyMinutes = currentDate.addingTimeInterval(60 * 30)
        XCTAssertEqual(factory.lockoutUntilDate(failedAttempts: 9, lockoutTimestamp: 1, uptime: 1), thirtyMinutes)
    }

}
