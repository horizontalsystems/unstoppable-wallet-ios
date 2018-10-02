import XCTest
import Cuckoo
@testable import Bank

class EditPinPresenterTests: XCTestCase {

    private var mockView: MockIPinView!
    private var mockInteractor: MockIPinInteractor!
    private var mockRouter: MockIEditPinRouter!

    private var presenter: EditPinPresenter!

    override func setUp() {
        super.setUp()

        mockView = MockIPinView()
        mockInteractor = MockIPinInteractor()
        mockRouter = MockIEditPinRouter()
        presenter = EditPinPresenter(interactor: mockInteractor, router: mockRouter)
        presenter.view = mockView

        stub(mockView) { mock in
            when(mock.set(title: any())).thenDoNothing()
            when(mock.addPage(withDescription: any(), showKeyboard: any())).thenDoNothing()
            when(mock.show(page: any())).thenDoNothing()
            when(mock.show(error: any(), forPage: any())).thenDoNothing()
            when(mock.show(error: any())).thenDoNothing()
            when(mock.showPinWrong(page: any())).thenDoNothing()
            when(mock.showCancel()).thenDoNothing()
        }
        stub(mockInteractor) { mock in
            when(mock.save(pin: any())).thenDoNothing()
            when(mock.set(pin: any())).thenDoNothing()
        }
        stub(mockRouter) { mock in
            when(mock.dismiss()).thenDoNothing()
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
        verify(mockView).set(title: equal(to: "edit_pin_controller.title"))
    }

    func testShowCancel() {
        presenter.viewDidLoad()

        verify(mockView).showCancel()
    }

    func testAddPages() {
        presenter.viewDidLoad()
        verify(mockView).addPage(withDescription: "edit_pin.unlock_info", showKeyboard: true)
        verify(mockView).addPage(withDescription: "edit_pin.new_pin_info", showKeyboard: true)
        verify(mockView).addPage(withDescription: "edit_pin.confirm_info", showKeyboard: true)
    }

    func testShowEnterOnUnlock() {
        let pin = "0000"

        stub(mockInteractor) { mock in
            when(mock.unlock(with: equal(to: pin))).thenReturn(true)
        }

        presenter.onEnter(pin: pin, forPage: EditPinPresenter.Page.unlock.rawValue)

        verify(mockView).show(page: EditPinPresenter.Page.enter.rawValue)
    }

    func testFailUnlock() {
        let pin = "0000"

        stub(mockInteractor) { mock in
            when(mock.unlock(with: equal(to: pin))).thenReturn(false)
        }

        presenter.onEnter(pin: pin, forPage: EditPinPresenter.Page.unlock.rawValue)

        verify(mockView, never()).show(page: EditPinPresenter.Page.enter.rawValue)
        verify(mockView).showPinWrong(page: EditPinPresenter.Page.unlock.rawValue)
    }

    func testShowConfirm() {
        let pin = "0000"

        presenter.onEnter(pin: pin, forPage: EditPinPresenter.Page.enter.rawValue)

        verify(mockView).show(page: EditPinPresenter.Page.confirm.rawValue)
        verify(mockInteractor).set(pin: equal(to: pin))
        verify(mockInteractor, never()).save(pin: equal(to: pin))
    }

    func testSavePinAfterConfirm() {
        let pin = "0000"
        stub(mockInteractor) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(true)
        }

        presenter.onEnter(pin: pin, forPage: EditPinPresenter.Page.confirm.rawValue)

        verify(mockInteractor).save(pin: equal(to: pin))
    }

    func testDismissAfterSavePin() {
        presenter.didSavePin()

        verify(mockRouter).dismiss()
    }

    func testInvalidConfirmPin() {
        let pin = "1111"
        stub(mockInteractor) { mock in
            when(mock.validate(pin: equal(to: pin))).thenReturn(false)
        }

        presenter.onEnter(pin: pin, forPage: EditPinPresenter.Page.confirm.rawValue)

        verify(mockView).show(page: EditPinPresenter.Page.enter.rawValue)
        verify(mockView).show(error: "set_pin_controller.wrong_confirmation", forPage: EditPinPresenter.Page.enter.rawValue)
        verify(mockInteractor, never()).save(pin: any())
        verify(mockInteractor).set(pin: equal(to: nil))
    }

    func testFailToSavePin() {
        presenter.didFailToSavePin()

        verify(mockView).show(error: "unlock.cant_save_pin")
        verify(mockView).show(page: EditPinPresenter.Page.enter.rawValue)
        verify(mockInteractor).set(pin: equal(to: nil))
    }

    func testCloseOnCancel() {
        presenter.onCancel()

        verify(mockRouter).dismiss()
    }
}
