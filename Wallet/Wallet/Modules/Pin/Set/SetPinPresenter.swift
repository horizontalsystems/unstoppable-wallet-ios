import Foundation

class SetPinPresenter {

    enum Page: Int { case enter, confirm }

    weak var view: IPinView?
    private let interactor: IPinInteractor
    private let router: ISetPinRouter

    init(interactor: IPinInteractor, router: ISetPinRouter) {
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

extension SetPinPresenter: IPinViewDelegate {

    func viewDidLoad() {
        view?.set(title: "set_pin_controller.title")
        view?.addPage(withDescription: "set_pin_controller.info", showKeyboard: true)
        view?.addPage(withDescription: "confirm_pin_controller.info", showKeyboard: true)
    }

    func onEnter(pin: String, forPage index: Int) {
        if index == Page.enter.rawValue {
            onEnterFromEnterPage(pin: pin)
        } else {
            onEnterFromConfirmPage(pin: pin)
        }
    }

    func onCancel() {

    }

}

extension SetPinPresenter: IPinInteractorDelegate {

    func didSavePin() {
        router.dismiss()
    }

    func didFailToSavePin() {
        showEnterPage()
        view?.show(error: "unlock.cant_save_pin")
    }

}
