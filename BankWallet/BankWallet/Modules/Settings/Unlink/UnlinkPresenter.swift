class UnlinkPresenter {
    private let router: IUnlinkRouter
    private let interactor: IUnlinkInteractor
    private let accountId: String

    weak var view: IUnlinkView?

    init(router: IUnlinkRouter, interactor: IUnlinkInteractor, accountId: String) {
        self.router = router
        self.interactor = interactor
        self.accountId = accountId
    }

}

extension UnlinkPresenter: IUnlinkViewDelegate {

    func didTapUnlink() {
        interactor.unlink(accountId: accountId)
    }

}

extension UnlinkPresenter: IUnlinkInteractorDelegate {

    func didUnlink() {
        router.dismiss()
    }

}
