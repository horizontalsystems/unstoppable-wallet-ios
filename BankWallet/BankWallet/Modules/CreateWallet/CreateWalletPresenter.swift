class CreateWalletPresenter {
    weak var view: ICreateWalletView?

    private let interactor: ICreateWalletInteractor
    private let router: ICreateWalletRouter

    init(interactor: ICreateWalletInteractor, router: ICreateWalletRouter) {
        self.interactor = interactor
        self.router = router
    }

}

extension CreateWalletPresenter: ICreateWalletViewDelegate {
}
