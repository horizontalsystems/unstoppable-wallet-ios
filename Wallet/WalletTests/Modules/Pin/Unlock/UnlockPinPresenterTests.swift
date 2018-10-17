import XCTest
import Cuckoo
@testable import Bank

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
        mockConfiguration = MockUnlockPresenterConfiguration(cancellable: false)
        presenter = UnlockPinPresenter(interactor: mockInteractor, router: mockRouter, configuration: mockConfiguration)
        presenter.view = mockView

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.addPage(withDescription: any(), showKeyboard: any())).thenDoNothing()
            when(mock.showPinWrong(page: any())).thenDoNothing()
            when(mock.showKeyboard(for: any())).thenDoNothing()
            when(mock.showCancel()).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.dismiss(didUnlock: any())).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.biometricUnlock()).thenDoNothing()
        }
        stub(mockConfiguration) { mock in
            when(mock.cancellable.get).thenReturn(false)
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
        verify(mockView).addPage(withDescription: "unlock_pin_controller.info", showKeyboard: false)
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

    func testDismissOnSuccessBiometricUnlock() {
        presenter.didBiometricUnlock()
        verify(mockRouter).dismiss(didUnlock: true)
    }

    func testShowKeyboardOnFailedBiometricUnlock() {
        presenter.didFailBiometricUnlock()
        verify(mockView).showKeyboard(for: unlockPage)
    }

}
