import XCTest
import Cuckoo
@testable import Bank_Dev_T

class UnlockPinInteractorTests: XCTestCase {
    private var mockDelegate: MockIUnlockPinInteractorDelegate!
    private var mockPinManager: MockIPinManager!
    private var mockBiometricManager: MockIBiometricManager!
    private var mockLockoutManager: MockILockoutManager!
    private var mockTimer: MockIOneTimeTimer!
    private var mockSecureStorage: MockISecureStorage!
    private var interactor: UnlockPinInteractor!

    override func setUp() {
        super.setUp()

        mockDelegate = MockIUnlockPinInteractorDelegate()
        mockPinManager = MockIPinManager()
        mockBiometricManager = MockIBiometricManager()
        mockLockoutManager = MockILockoutManager()
        mockTimer = MockIOneTimeTimer()
        mockSecureStorage = MockISecureStorage()

        stub(mockDelegate) { mock in
            when(mock.didBiometricUnlock()).thenDoNothing()
            when(mock.didFailBiometricUnlock()).thenDoNothing()
            when(mock.update(lockoutState: any())).thenDoNothing()
        }
        stub(mockPinManager) { mock in
            when(mock.store(pin: any())).thenDoNothing()
        }
        stub(mockBiometricManager) { mock in
            when(mock.validate(reason: any())).thenDoNothing()
        }
        stub(mockLockoutManager) { mock in
            when(mock.didFailUnlock()).thenDoNothing()
            when(mock.currentState.get).thenReturn(LockoutState.unlocked(attemptsLeft: nil))
            when(mock.dropFailedAttempts()).thenDoNothing()
        }
        stub(mockTimer) { mock in
            when(mock.delegate.set(any())).thenDoNothing()
            when(mock.schedule(date: any())).thenDoNothing()
        }

        interactor = UnlockPinInteractor(pinManager: mockPinManager, biometricManager: mockBiometricManager, lockoutManager: mockLockoutManager, timer: mockTimer, secureStorage: mockSecureStorage)
        interactor.delegate = mockDelegate
    }

    override func tearDown() {
        mockDelegate = nil
        mockPinManager = nil
        mockBiometricManager = nil
        mockLockoutManager = nil
        mockTimer = nil
        mockSecureStorage = nil
        interactor = nil

        super.tearDown()
    }

    func testUnlockSuccess() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertTrue(isValid)
    }

    func testUnlockFailure() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }

        let isValid = interactor.unlock(with: pin)

        XCTAssertFalse(isValid)
    }

    func testBiometricUnlockWhenEnabled() {
        stub(mockPinManager) { mock in
            when(mock.biometryEnabled.get).thenReturn(true)
        }

        interactor.biometricUnlock()

        verify(mockBiometricManager).validate(reason: "biometric_usage_reason")
    }

    func testBiometricUnlockWhenDisabled() {
        stub(mockPinManager) { mock in
            when(mock.biometryEnabled.get).thenReturn(false)
        }

        interactor.biometricUnlock()

        verify(mockDelegate).didFailBiometricUnlock()
        verify(mockBiometricManager, never()).validate(reason: any())
    }

    func testDidBiometricValidate() {
        interactor.didValidate()
        verify(mockDelegate).didBiometricUnlock()
    }

    func testDidFailBiometricValidate() {
        interactor.didFailToValidate()
        verify(mockDelegate).didFailBiometricUnlock()
    }

    func testUpdateFailAttempt() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }
        _ = interactor.unlock(with: pin)

        verify(mockLockoutManager).didFailUnlock()
    }

    func testUpdateLockoutState_FailAttempt() {
        let pin = "0000"
        let state = LockoutState.unlocked(attemptsLeft: 4)
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }
        stub(mockLockoutManager) { mock in
            when(mock.currentState.get).thenReturn(state)
        }

        _ = interactor.unlock(with: pin)

        verify(mockDelegate).update(lockoutState: equal(to: state))
    }

    func testStartLockoutTimer_WrongPin() {
        let date = Date()
        let pin = "0000"
        let lockedState = LockoutState.locked(till: date)

        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }
        stub(mockLockoutManager) { mock in
            when(mock.currentState.get).thenReturn(lockedState)
        }

        _ = interactor.unlock(with: pin)

        verify(mockTimer).schedule(date: equal(to: date))
    }

    func testUpdateState_OnFire() {
        let unlockedState = LockoutState.unlocked(attemptsLeft: 1)
        stub(mockLockoutManager) { mock in
            when(mock.currentState.get).thenReturn(unlockedState)
        }

        interactor.onFire()
        verify(mockDelegate).update(lockoutState: equal(to: unlockedState))
    }

    func testStartLockoutTimer_LockedState() {
        let date = Date()
        let lockedState = LockoutState.locked(till: date)

        stub(mockLockoutManager) { mock in
            when(mock.currentState.get).thenReturn(lockedState)
        }

        interactor.updateLockoutState()

        verify(mockTimer).schedule(date: equal(to: date))
    }

    func testUpdateLockoutState() {
        let lockedState = LockoutState.locked(till: Date())

        stub(mockLockoutManager) { mock in
            when(mock.currentState.get).thenReturn(lockedState)
        }

        interactor.updateLockoutState()

        verify(mockDelegate).update(lockoutState: equal(to: lockedState))
    }

    func testDropFailedAttempts() {
        let pin = "0000"
        stub(mockPinManager) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        _ = interactor.unlock(with: pin)

        verify(mockLockoutManager).dropFailedAttempts()
    }

    func testFailedAttempts() {
        stub(mockSecureStorage) { mock in
            when(mock.unlockAttempts.get).thenReturn(1)
        }

        XCTAssertEqual(1, interactor.failedAttempts)
    }

}
