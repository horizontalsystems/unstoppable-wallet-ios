import Foundation

class GuestPresenter {

    private let interactor: IGuestInteractor
    private let router: IGuestRouter

    init(interactor: IGuestInteractor, router: IGuestRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension GuestPresenter: IGuestInteractorDelegate {

    func willAppear() {
        interactor.willAppear()
    }

    func willDisappear() {
        interactor.willDisAppear()
    }

    func didCreateWallet() {
        router.navigateToBackupRoutingToMain()
    }

    func didFailToCreateWallet(withError error: Error) {
        print("Login Error: \(error)")
        // TODO: show error in GUI
    }

}

extension GuestPresenter: IGuestViewDelegate {

    func createWalletDidClick() {
        interactor.createWallet()
    }

    func restoreWalletDidClick() {
        router.navigateToRestore()
    }

}
