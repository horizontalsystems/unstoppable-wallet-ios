import Foundation

class EditPinPresenter {

    enum Page: Int { case unlock, enter, confirm }

    let interactor: IPinInteractor
    let router: IEditPinRouter
    weak var view: IPinView?

    var enteredPin: String?

    init(interactor: IPinInteractor, router: IEditPinRouter) {
        self.interactor = interactor
        self.router = router
    }

    private func show(page: Page) {
        view?.show(page: page.rawValue)
    }

    private func show(error: String, forPage page: Page) {
        view?.show(error: error, forPage: page.rawValue)
    }

    private func showEnterPage() {
        interactor.set(pin: nil)
        show(page: .enter)
    }

    private func onEnterFromUnlockPage(pin: String) {
        if interactor.unlock(with: pin) {
            show(page: .enter)
        } else {
            view?.showPinWrong(page: Page.unlock.rawValue)
        }
    }

    private func onEnterFromEnterPage(pin: String) {
        interactor.set(pin: pin)
        show(page: .confirm)
    }

    private func onEnterFromConfirmPage(pin: String) {
        if interactor.validate(pin: pin) {
            interactor.save(pin: pin)
        } else {
            showEnterPage()
            show(error: "set_pin_controller.wrong_confirmation", forPage: .enter)
        }
    }

}

extension EditPinPresenter: IPinViewDelegate {

    func viewDidLoad() {
        view?.set(title: "edit_pin_controller.title")
        view?.addPage(withDescription: "edit_pin.unlock_info", showKeyboard: true)
        view?.addPage(withDescription: "edit_pin.new_pin_info", showKeyboard: true)
        view?.addPage(withDescription: "edit_pin.confirm_info", showKeyboard: true)

        view?.showCancel()
    }

    func onEnter(pin: String, forPage index: Int) {
        if let page = Page(rawValue: index) {
            switch page {
            case .unlock:
                onEnterFromUnlockPage(pin: pin)
            case .enter:
                onEnterFromEnterPage(pin: pin)
            case .confirm:
                onEnterFromConfirmPage(pin: pin)
            }
        }
    }

    func onCancel() {
        router.dismiss()
    }

}

extension EditPinPresenter: IPinInteractorDelegate {

    func didSavePin() {
        router.dismiss()
    }

    func didFailToSavePin() {
        showEnterPage()
        view?.show(error: "unlock.cant_save_pin")
    }

}
