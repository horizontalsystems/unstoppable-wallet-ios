class UnlinkPresenter {
    private let router: IUnlinkRouter
    private let interactor: IUnlinkInteractor
    private let account: Account

    weak var view: IUnlinkView?

    init(router: IUnlinkRouter, interactor: IUnlinkInteractor, account: Account) {
        self.router = router
        self.interactor = interactor
        self.account = account
    }

}

extension UnlinkPresenter: IUnlinkViewDelegate {

    func didTapUnlink() {
        interactor.unlink(account: account)
    }

}

extension UnlinkPresenter: IUnlinkInteractorDelegate {

    func didUnlink() {
        router.dismiss()
    }

}
