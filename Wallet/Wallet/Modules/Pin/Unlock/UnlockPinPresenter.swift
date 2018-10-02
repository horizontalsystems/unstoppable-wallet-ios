import Foundation

class UnlockPinPresenter {

    enum Page: Int { case unlock }

    weak var view: IPinView?
    private let interactor: IUnlockPinInteractor
    private let router: IUnlockPinRouter

    init(interactor: IUnlockPinInteractor, router: IUnlockPinRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension UnlockPinPresenter: IPinViewDelegate {

    func viewDidLoad() {
        view?.addPage(withDescription: "unlock_pin_controller.info", showKeyboard: false)
        interactor.biometricUnlock()
    }

    func onEnter(pin: String, forPage index: Int) {
        if interactor.unlock(with: pin) {
            router.dismiss()
        } else {
            view?.showPinWrong(page: Page.unlock.rawValue)
        }
    }

    func onCancel() {
    }

}

extension UnlockPinPresenter: IUnlockPinInteractorDelegate {

    func didBiometricUnlock() {
        router.dismiss()
    }

    func didFailBiometricUnlock() {
        view?.showKeyboard(for: Page.unlock.rawValue)
    }

}
