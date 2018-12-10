import XCTest
import Cuckoo
@testable import Bank_Dev_T

class LockoutManagerTests: XCTestCase {
    private var mockLockoutDelegate: MockILockoutManagerDelegate!
    private var mockSecureStorage: MockISecureStorage!
    private var mockUptimeProvider: MockIUptimeProvider!
    private var mockTimer: MockIPeriodicTimer!
    private var mockLockoutTimeFrameFactory: MockILockoutTimeFrameFactory!

    private var manager: LockoutManager!

    private var defaultUptime: TimeInterval = 1

    override func setUp() {
        super.setUp()

        mockLockoutDelegate = MockILockoutManagerDelegate()
        mockSecureStorage = MockISecureStorage()
        mockUptimeProvider = MockIUptimeProvider()
        mockTimer = MockIPeriodicTimer()
        mockLockoutTimeFrameFactory = MockILockoutTimeFrameFactory()

        stub(mockSecureStorage) { mock in
            when(mock.lockoutTimestamp.get).thenReturn(1)
            when(mock.set(unlockAttempts: any())).thenDoNothing()
            when(mock.set(lockoutTimestamp: any())).thenDoNothing()
        }
        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(defaultUptime)
        }
        stub(mockLockoutDelegate) { mock in
            when(mock.lockout(timeFrame: any())).thenDoNothing()
            when(mock.finishLockout()).thenDoNothing()
        }
        stub(mockTimer) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
            when(mock.schedule()).thenDoNothing()
        }
        stub(mockLockoutTimeFrameFactory) { mock in
            when(mock.lockoutTimeFrame(failedAttempts: any(), lockoutTimestamp: any(), uptime: any())).thenReturn(1)
        }

        manager = LockoutManager(secureStorage: mockSecureStorage, uptimeProvider: mockUptimeProvider, delegate: mockLockoutDelegate, timer: mockTimer, lockoutTimeFrameFactory: mockLockoutTimeFrameFactory)
    }

    override func tearDown() {
        mockLockoutDelegate = nil
        mockSecureStorage = nil
        mockUptimeProvider = nil
        mockTimer = nil
        mockLockoutTimeFrameFactory = nil

        manager = nil

        super.tearDown()
    }

    func testIsLockedTrue() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
        }
        XCTAssertTrue(manager.isLockedOut)
    }

    func testIsLockedFalse() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
            when(mock.lockoutTimestamp.get).thenReturn(1)
        }
        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(500)
        }
        stub(mockLockoutTimeFrameFactory) { mock in
            when(mock.lockoutTimeFrame(failedAttempts: 5, lockoutTimestamp: 1, uptime: 500)).thenReturn(0)
        }

        XCTAssertFalse(manager.isLockedOut)
    }

    func testWriteFailTimes() {
        manager.failedTimes = 3
        verify(mockSecureStorage).set(unlockAttempts: equal(to: 3))
    }

    func testGetFailTimes() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(2)
        }
        XCTAssertEqual(manager.failedTimes, 2)
    }

    func testLockoutDelegate() {
        let unlockAttempts = 5

        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(unlockAttempts)
        }

        manager.failedTimes = unlockAttempts
        verify(mockLockoutDelegate).lockout(timeFrame: any())
    }

    func testUnlockDelegate() {
        stub(mockLockoutTimeFrameFactory) { mock in
            when(mock.lockoutTimeFrame(failedAttempts: any(), lockoutTimestamp: any(), uptime: any())).thenReturn(0)
        }
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
        }

        manager.onFire()
        verify(mockLockoutDelegate).finishLockout()
    }

    func testResetUptime_LockoutTimeFrame_Reboot() {
        let newUptimeAfterReboot: TimeInterval = 1

        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(newUptimeAfterReboot)
        }
        stub(mockSecureStorage) { mock in
            when(mock.lockoutTimestamp.get).thenReturn(2)
            when(mock.unlockAttempts.get).thenReturn(5)
        }

        _ = manager.lockoutTimeFrame

        verify(mockSecureStorage).set(lockoutTimestamp: equal(to: newUptimeAfterReboot))
    }

    func testResetUptime_FireTimer_Reboot() {
        let newUptimeAfterReboot: TimeInterval = 1

        stub(mockUptimeProvider) { mock in
            when(mock.uptime.get).thenReturn(newUptimeAfterReboot)
        }
        stub(mockSecureStorage) { mock in
            when(mock.lockoutTimestamp.get).thenReturn(2)
            when(mock.unlockAttempts.get).thenReturn(5)
        }

        manager.onFire()

        verify(mockSecureStorage).set(lockoutTimestamp: equal(to: newUptimeAfterReboot))
    }

    func testSetLockoutTimestamp() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
        }

        manager.failedTimes = 5
        verify(mockSecureStorage).set(lockoutTimestamp: equal(to: defaultUptime))
    }

    func testDropLockoutTimestamp() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(5)
        }

        manager.failedTimes = nil
        verify(mockSecureStorage).set(lockoutTimestamp: equal(to: nil))
    }

    func testInitialAttemptsLeft() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(nil)
        }
        XCTAssertEqual(manager.attemptsLeft, 5)
    }

    func test3AttemptsLeft() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(2)
        }
        XCTAssertEqual(manager.attemptsLeft, 3)
    }

    func testLastAttemptLeft() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(8)
        }
        XCTAssertEqual(manager.attemptsLeft, 1)
    }

}
