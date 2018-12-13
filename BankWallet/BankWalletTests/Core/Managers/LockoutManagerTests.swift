import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LockoutManagerTests: XCTestCase {
    private var mockSecureStorage: MockISecureStorage!
    private var mockUptimeProvider: MockIUptimeProvider!
    private var mockLockoutUntilDateFactory: MockILockoutUntilDateFactory!

    private var manager: LockoutManagerNew!

    private var defaultUptime: TimeInterval = 1

    override func setUp() {
        super.setUp()

        mockSecureStorage = MockISecureStorage()
        mockUptimeProvider = MockIUptimeProvider()
        mockLockoutUntilDateFactory = MockILockoutUntilDateFactory()

        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(nil)
            when(mock.lockoutTimestamp.get).thenReturn(nil)
            when(mock.set(unlockAttempts: any())).thenDoNothing()
            when(mock.set(lockoutTimestamp: any())).thenDoNothing()
        }
        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(defaultUptime)
        }
        stub(mockLockoutUntilDateFactory) { mock in
            when(mock.lockoutUntilDate(failedAttempts: any(), lockoutTimestamp: any(), uptime: any())).thenReturn(Date())
        }

        manager = LockoutManagerNew(secureStorage: mockSecureStorage, uptimeProvider: mockUptimeProvider, lockoutTimeFrameFactory: mockLockoutUntilDateFactory)
    }

    override func tearDown() {
        mockSecureStorage = nil
        mockUptimeProvider = nil
        mockLockoutUntilDateFactory = nil

        manager = nil

        super.tearDown()
    }

    func testDidFailUnlockFirst() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(nil)
        }

        manager.didFailUnlock()
        verify(mockSecureStorage).set(unlockAttempts: equal(to: 1))
    }

    func testDidFailUnlockSecond() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(1)
        }

        manager.didFailUnlock()
        verify(mockSecureStorage).set(unlockAttempts: equal(to: 2))
    }

    func testCurrentStateUnlocked() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(nil)
        }

        XCTAssertEqual(manager.currentState, LockoutStateNew.unlocked(attemptsLeft: nil))
    }

    func testCurrentStateUnlocked_TwoAttempts() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(3)
        }

        XCTAssertEqual(manager.currentState, LockoutStateNew.unlocked(attemptsLeft: 2))
    }

    func testCurrentStateUnlocked_NotLessOne() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(7)
        }

        XCTAssertEqual(manager.currentState, LockoutStateNew.unlocked(attemptsLeft: 1))
    }

    func testUpdateLockoutTimestamp() {
        let uptime: TimeInterval = 1
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(4)
        }
        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(uptime)
        }

        manager.didFailUnlock()

        verify(mockSecureStorage).set(lockoutTimestamp: equal(to: uptime))
    }

    func testCurrentStateLocked() {
        let unlockDate = Date().addingTimeInterval(5)
        let lockedState = LockoutStateNew.locked(till: unlockDate)

        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
            when(mock.lockoutTimestamp.get).thenReturn(1)
        }
        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(1)
        }
        stub(mockLockoutUntilDateFactory) { mock in
            when(mock.lockoutUntilDate(failedAttempts: equal(to: 5), lockoutTimestamp: equal(to: 1), uptime: equal(to: 1))).thenReturn(unlockDate)
        }

        XCTAssertEqual(manager.currentState, lockedState)
    }

    func testDropFailedAttempts() {
        manager.dropFailedAttempts()
        verify(mockSecureStorage).set(unlockAttempts: equal(to: nil))
    }

}
