import Foundation

class UnlockPinPresenter {

    enum Page: Int { case unlock }

    weak var view: IPinView?
    private let interactor: IUnlockPinInteractor
    private let router: IUnlockPinRouter

    private let configuration: UnlockPresenterConfiguration

    init(interactor: IUnlockPinInteractor, router: IUnlockPinRouter, configuration: UnlockPresenterConfiguration = .init(cancellable: false)) {
        self.interactor = interactor
        self.router = router
        self.configuration = configuration
    }

}

extension UnlockPinPresenter: IPinViewDelegate {

    func viewDidLoad() {
        view?.addPage(withDescription: "unlock_pin_controller.info", showKeyboard: false)
        interactor.biometricUnlock()

        if configuration.cancellable {
            view?.showCancel()
        }
    }

    func onEnter(pin: String, forPage index: Int) {
        if interactor.unlock(with: pin) {
            router.dismiss()
        } else {
            view?.showPinWrong(page: Page.unlock.rawValue)
        }
    }

    func onCancel() {
        router.dismiss()
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
