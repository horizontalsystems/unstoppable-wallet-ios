import XCTest
import Cuckoo
@testable import Bank_Dev_T

class SetPinPresenterTests: XCTestCase {

    private var mockView: MockIPinView!
    private var mockInteractor: MockIPinInteractor!
    private var mockRouter: MockISetPinRouter!

    private var presenter: SetPinPresenter!

    private let enterPage = 0
    private let confirmPage = 1

    override func setUp() {
        super.setUp()

        mockView = MockIPinView()
        mockInteractor = MockIPinInteractor()
        mockRouter = MockISetPinRouter()
        presenter = SetPinPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.addPage(withDescription: any())).thenDoNothing()
            when(mock.show(page: any())).thenDoNothing()
            when(mock.show(error: any(), forPage: any())).thenDoNothing()
            when(mock.show(error: any())).thenDoNothing()
            when(mock.showCancel()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.save(pin: any())).thenDoNothing()
            when(mock.set(pin: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.notifyCancelled()).thenDoNothing()
            when(mock.close()).thenDoNothing()
        }
    }

    override func tearDown() {
        mockView = nil
        mockInteractor = nil
        mockRouter = nil
        presenter = nil

        super.tearDown()
    }

    func testShowTitle() {
        presenter.viewDidLoad()
        verify(mockView).set(title: equal(to: "set_pin.title"))
    }

    func testDontShowCancel() {
        presenter.viewDidLoad()
        verify(mockView, never()).set(title: equal(to: "edit_pin.title"))
    }

    func testAddPages() {
        presenter.viewDidLoad()
        verify(mockView).addPage(withDescription: "set_pin.info")
        verify(mockView).addPage(withDescription: "button.confirm")
    }

    func testShowConfirm() {
        let pin = "0000"

        presenter.onEnter(pin: pin, forPage: enterPage)

        verify(mockView).show(page: confirmPage)
        verify(mockInteractor).set(pin: equal(to: pin))
        verify(mockInteractor, never()).save(pin: equal(to: pin))
    }

    func testSavePinAfterConfirm() {
        let pin = "0000"
        stub(mockInteractor) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        presenter.onEnter(pin: pin, forPage: confirmPage)

        verify(mockInteractor).save(pin: equal(to: pin))
    }

    func testDismissAfterSavePin() {
        presenter.didSavePin()

        verify(mockRouter).close()
    }

    func testInvalidConfirmPin() {
        let pin = "1111"
        stub(mockInteractor) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }

        presenter.onEnter(pin: pin, forPage: confirmPage)

        verify(mockView).show(page: enterPage)
        verify(mockView).show(error: "set_pin.wrong_confirmation", forPage: enterPage)
        verify(mockInteractor, never()).save(pin: any())
        verify(mockInteractor).set(pin: equal(to: nil))
    }

    func testFailToSavePin() {
        presenter.didFailToSavePin()

        verify(mockView).show(error: "unlock_pin.cant_save_pin")
        verify(mockView).show(page: enterPage)
        verify(mockInteractor).set(pin: equal(to: nil))
    }

}
