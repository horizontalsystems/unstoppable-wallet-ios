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
        view?.addPage(withDescription: "unlock_pin.info")
        interactor.biometricUnlock()

        if configuration.cancellable {
            view?.showCancel()
        }

        interactor.updateLockoutState()
    }

    func onEnter(pin: String, forPage index: Int) {
        if interactor.unlock(with: pin) {
            router.dismiss(didUnlock: true)
        } else {
            view?.showPinWrong(page: Page.unlock.rawValue)
        }
    }

    func onCancel() {
        router.dismiss(didUnlock: false)
    }

}

extension UnlockPinPresenter: IUnlockPinInteractorDelegate {

    func didBiometricUnlock() {
        router.dismiss(didUnlock: true)
    }

    func didFailBiometricUnlock() {
    }

    func update(lockoutState: LockoutState) {
        switch lockoutState {
        case .unlocked(let attemptsLeft):
            view?.show(attemptsLeft: attemptsLeft, forPage: Page.unlock.rawValue)
        case .locked(let dueDate):
            view?.showLockView(till: dueDate)
        }
    }

}
