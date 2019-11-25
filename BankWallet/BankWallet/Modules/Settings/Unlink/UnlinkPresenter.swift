class UnlinkPresenter {
    private let router: IUnlinkRouter
    private let interactor: IUnlinkInteractor
    private let account: Account
    private let predefinedAccountType: PredefinedAccountType

    weak var view: IUnlinkView?

    init(router: IUnlinkRouter, interactor: IUnlinkInteractor, account: Account, predefinedAccountType: PredefinedAccountType) {
        self.router = router
        self.interactor = interactor
        self.account = account
        self.predefinedAccountType = predefinedAccountType
    }

}

extension UnlinkPresenter: IUnlinkViewDelegate {

    var title: String {
        return predefinedAccountType.title
    }

    var coinCodes: String {
        return predefinedAccountType.coinCodes
    }

    func didTapUnlink() {
        interactor.unlink(account: account)

        view?.showSuccess()
        router.dismiss()
    }

}

extension UnlinkPresenter: IUnlinkInteractorDelegate {
}
