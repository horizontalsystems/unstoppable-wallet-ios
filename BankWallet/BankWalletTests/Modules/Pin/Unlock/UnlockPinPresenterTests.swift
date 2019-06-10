import XCTest
import Cuckoo
@testable import Bank_Dev_T

class UnlockPinPresenterTests: XCTestCase {

    private var mockView: MockIPinView!
    private var mockInteractor: MockIUnlockPinInteractor!
    private var mockRouter: MockIUnlockPinRouter!
    private var mockConfiguration: MockUnlockPresenterConfiguration!

    private var presenter: UnlockPinPresenter!

    private let unlockPage = 0

    override func setUp() {
        super.setUp()

        mockView = MockIPinView()
        mockInteractor = MockIUnlockPinInteractor()
        mockRouter = MockIUnlockPinRouter()
        mockConfiguration = MockUnlockPresenterConfiguration(cancellable: false, enableBiometry: true)
        presenter = UnlockPinPresenter(interactor: mockInteractor, router: mockRouter, configuration: mockConfiguration)
        presenter.view = mockView

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.addPage(withDescription: any())).thenDoNothing()
            when(mock.showPinWrong(page: any())).thenDoNothing()
            when(mock.showCancel()).thenDoNothing()
            when(mock.showLockView(till: any())).thenDoNothing()
            when(mock.show(attemptsLeft: any(), forPage: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.dismiss(didUnlock: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.biometricUnlock()).thenDoNothing()
            when(mock.updateLockoutState()).thenDoNothing()
            when(mock.failedAttempts.get).thenReturn(0)
        }
        stub(mockConfiguration) { mock in
            when(mock.cancellable.get).thenReturn(false)
            when(mock.enableBiometry.get).thenReturn(true)
        }
    }

    override func tearDown() {
        mockView = nil
        mockInteractor = nil
        mockRouter = nil
        presenter = nil

        super.tearDown()
    }

    func testDontShowCancel() {
        presenter.viewDidLoad()
        verify(mockView, never()).showCancel()
    }

    func testBiometryUnlockShow() {
        stub(mockConfiguration) { mock in
            when(mock.cancellable.get).thenReturn(false)
            when(mock.enableBiometry.get).thenReturn(true)
        }

        presenter.viewDidLoad()

        verify(mockInteractor).biometricUnlock()
    }

    func testBiometryUnlockDontShow() {
        stub(mockConfiguration) { mock in
            when(mock.cancellable.get).thenReturn(false)
            when(mock.enableBiometry.get).thenReturn(false)
        }

        presenter.viewDidLoad()

        verify(mockInteractor, never()).biometricUnlock()
    }

    func testShowCancel() {
        stub(mockConfiguration) { mock in
            when(mock.cancellable.get).thenReturn(true)
        }

        presenter.viewDidLoad()

        verify(mockView).showCancel()
    }

    func testCloseOnCancel() {
        presenter.onCancel()

        verify(mockRouter).dismiss(didUnlock: false)
    }

    func testAddPages() {
        presenter.viewDidLoad()
        verify(mockView).addPage(withDescription: "unlock_pin.info")
    }

    func testDismissAfterSuccessUnlock() {
        let pin = "0000"
        stub(mockInteractor) { mock in
            when(mock.unlock(with: equal(to: pin))).thenReturn(true)
        }

        presenter.onEnter(pin: pin, forPage: unlockPage)

        verify(mockRouter).dismiss(didUnlock: true)
    }

    func testDismissAfterFailUnlock() {
        let pin = "0000"
        stub(mockInteractor) { mock in
            when(mock.unlock(with: equal(to: pin))).thenReturn(false)
        }

        presenter.onEnter(pin: pin, forPage: unlockPage)

        verify(mockRouter, never()).dismiss(didUnlock: any())
        verify(mockView).showPinWrong(page: unlockPage)
    }

    func testBiometricUnlockOnLoad() {
        presenter.viewDidLoad()
        verify(mockInteractor).biometricUnlock()
    }

    func testNoBiometrics_failedAttempts() {
        stub(mockInteractor) { mock in
            when(mock.failedAttempts.get).thenReturn(1)
        }

        presenter.viewDidLoad()

        verify(mockInteractor, never()).biometricUnlock()
    }

    func testDismissOnSuccessBiometricUnlock() {
        presenter.didBiometricUnlock()
        verify(mockRouter).dismiss(didUnlock: true)
    }

    func testUpdateLockoutState_DidLoad() {
        presenter.viewDidLoad()
        verify(mockInteractor).updateLockoutState()
    }

    func testUpdateLockoutState_Unlocked() {
        let lockoutStateUnlocked = LockoutState.unlocked(attemptsLeft: nil)
        presenter.update(lockoutState: lockoutStateUnlocked)

        verify(mockView).show(attemptsLeft: equal(to: nil), forPage: equal(to: unlockPage))
        verify(mockView, never()).showLockView(till: any())
    }

    func testLockoutStateUnlocked_FewAttempts() {
        let lockoutStateUnlocked = LockoutState.unlocked(attemptsLeft: 3)
        presenter.update(lockoutState: lockoutStateUnlocked)

        verify(mockView).show(attemptsLeft: equal(to: 3), forPage: equal(to: unlockPage))
        verify(mockView, never()).showLockView(till: any())
    }

    func testLockoutStateLocked() {
        let unlockDate = Date().addingTimeInterval(1)
        let lockoutStateLocked = LockoutState.locked(till: unlockDate)
        presenter.update(lockoutState: lockoutStateLocked)
        verify(mockView).showLockView(till: equal(to: unlockDate))
    }

}
