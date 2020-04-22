class NoAccountPresenter {
    weak var view: INoAccountView?

    private let interactor: INoAccountInteractor
    private let router: INoAccountRouter

    private let coin: Coin
    private let predefinedAccountType: PredefinedAccountType

    init(coin: Coin, interactor: INoAccountInteractor, router: INoAccountRouter) {
        self.coin = coin
        self.interactor = interactor
        self.router = router

        predefinedAccountType = coin.type.predefinedAccountType
    }

}

extension NoAccountPresenter: INoAccountViewDelegate {

    func onLoad() {
        let viewItem = NoAccountModule.ViewItem(
                coinTitle: coin.title,
                coinCode: coin.code,
                accountTypeTitle: predefinedAccountType.title,
                coinCodes: predefinedAccountType.coinCodes,
                createEnabled: predefinedAccountType.createSupported
        )

        view?.set(viewItem: viewItem)
    }

    func onTapCreate() {
        do {
            let account = try interactor.createAccount(predefinedAccountType: predefinedAccountType)
            interactor.save(account: account)

            view?.showSuccess()
            router.close()
        } catch {
            view?.show(error: error)
        }
    }

    func onTapRestore() {
        router.closeAndShowRestore(predefinedAccountType: predefinedAccountType)
    }

    func onTapClose() {
        router.close()
    }

}
