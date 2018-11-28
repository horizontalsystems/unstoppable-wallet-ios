import Foundation

class ManagePinPresenter {

    enum Page { case unlock, enter, confirm }

    let interactor: IPinInteractor
    weak var view: IPinView?

    let pages: [Page]

    init(interactor: IPinInteractor, pages: [Page]) {
        self.interactor = interactor
        self.pages = pages
    }

    private func show(page: Page) {
        if let index = pages.firstIndex(of: page) {
            view?.show(page: index)
        }
    }

    private func show(error: String, forPage page: Page) {
        if let index = pages.firstIndex(of: page) {
            view?.show(error: error, forPage: index)
        }
    }

    private func showEnterPage() {
        interactor.set(pin: nil)
        show(page: .enter)
    }

    private func onEnterFromUnlockPage(pin: String) {
        if interactor.unlock(with: pin) {
            show(page: .enter)
        } else if let index = pages.firstIndex(of: .unlock) {
            view?.showPinWrong(page: index)
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
            show(error: "set_pin.wrong_confirmation", forPage: .enter)
        }
    }

}

extension ManagePinPresenter: IPinViewDelegate {

    @objc func viewDidLoad() {
    }

    func onEnter(pin: String, forPage index: Int) {
        switch pages[index] {
        case .unlock:
            onEnterFromUnlockPage(pin: pin)
        case .enter:
            onEnterFromEnterPage(pin: pin)
        case .confirm:
            onEnterFromConfirmPage(pin: pin)
        }
    }

    @objc func onCancel() {
    }

}

extension ManagePinPresenter: IPinInteractorDelegate {

    @objc func didSavePin() {
    }

    func didFailToSavePin() {
        showEnterPage()
        view?.show(error: "unlock_pin.cant_save_pin")
    }

}
