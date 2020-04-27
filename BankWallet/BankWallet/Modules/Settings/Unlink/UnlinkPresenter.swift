class UnlinkPresenter {
    weak var view: IUnlinkView?

    private let router: IUnlinkRouter
    private let interactor: IUnlinkInteractor

    private let account: Account
    private let predefinedAccountType: PredefinedAccountType

    private var viewItems: [UnlinkModule.ViewItem]

    init(account: Account, predefinedAccountType: PredefinedAccountType, router: IUnlinkRouter, interactor: IUnlinkInteractor) {
        self.account = account
        self.predefinedAccountType = predefinedAccountType
        self.router = router
        self.interactor = interactor

        viewItems = [
            UnlinkModule.ViewItem(type: .deleteAccount(accountTypeTitle: predefinedAccountType.title)),
            UnlinkModule.ViewItem(type: .disableCoins(coinCodes: predefinedAccountType.coinCodes)),
            UnlinkModule.ViewItem(type: .loseAccess)
        ]
    }

    private func syncView() {
        view?.set(viewItems: viewItems)
        view?.set(deleteButtonEnabled: viewItems.allSatisfy { $0.checked })
    }

}

extension UnlinkPresenter: IUnlinkViewDelegate {

    func onLoad() {
        view?.set(accountTypeTitle: predefinedAccountType.title)
        syncView()
    }

    func onTapViewItem(index: Int) {
        viewItems[index].checked = !viewItems[index].checked
        syncView()
    }

    func onTapDelete() {
        interactor.delete(account: account)

        view?.showSuccess()
        router.close()
    }

    func onTapClose() {
        router.close()
    }

}
