import XCTest
import Cuckoo
@testable import Bank

class UnlockPinPresenterTests: XCTestCase {

    private var mockView: MockIPinView!
    private var mockInteractor: MockIUnlockPinInteractor!
    private var mockRouter: MockIUnlockPinRouter!

    private var presenter: UnlockPinPresenter!

    override func setUp() {
        super.setUp()

        mockView = MockIPinView()
        mockInteractor = MockIUnlockPinInteractor()
        mockRouter = MockIUnlockPinRouter()
        presenter = UnlockPinPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.addPage(withDescription: any(), showKeyboard: any())).thenDoNothing()
            when(mock.showPinWrong(page: any())).thenDoNothing()
            when(mock.showKeyboard(for: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.dismiss()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.biometricUnlock()).thenDoNothing()
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
        verify(mockView, never()).set(title: equal(to: "edit_pin_controller.title"))
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

        presenter.onEnter(pin: pin, forPage: UnlockPinPresenter.Page.unlock.rawValue)

        verify(mockRouter).dismiss()
    }

    func testDismissAfterFailUnlock() {
        let pin = "0000"
        stub(mockInteractor) { mock in
            when(mock.unlock(with: equal(to: pin))).thenReturn(false)
        }

        presenter.onEnter(pin: pin, forPage: UnlockPinPresenter.Page.unlock.rawValue)

        verify(mockRouter, never()).dismiss()
        verify(mockView).showPinWrong(page: EditPinPresenter.Page.unlock.rawValue)
    }

    func testBiometricUnlockOnLoad() {
        presenter.viewDidLoad()
        verify(mockInteractor).biometricUnlock()
    }

    func testDismissOnSuccessBiometricUnlock() {
        presenter.didBiometricUnlock()
        verify(mockRouter).dismiss()
    }

    func testShowKeyboardOnFailedBiometricUnlock() {
        presenter.didFailBiometricUnlock()
        verify(mockView).showKeyboard(for: UnlockPinPresenter.Page.unlock.rawValue)
    }

    func testNeverDismiss() {
        presenter.onCancel()

        verify(mockRouter, never()).dismiss()
    }

}
