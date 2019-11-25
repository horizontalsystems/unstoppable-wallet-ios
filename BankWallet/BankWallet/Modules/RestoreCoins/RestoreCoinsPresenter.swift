class RestoreCoinsPresenter {
    weak var view: IRestoreCoinsView?

    private let presentationMode: RestoreCoinsModule.PresentationMode
    private let predefinedAccountType: PredefinedAccountType
    private let interactor: IRestoreCoinsInteractor
    private let router: IRestoreCoinsRouter

    private var enabledCoins = [Coin: CoinSettings]()

    init(presentationMode: RestoreCoinsModule.PresentationMode, predefinedAccountType: PredefinedAccountType, interactor: IRestoreCoinsInteractor, router: IRestoreCoinsRouter) {
        self.presentationMode = presentationMode
        self.predefinedAccountType = predefinedAccountType
        self.interactor = interactor
        self.router = router
    }

    private func filteredCoins(coins: [Coin]) -> [Coin] {
        coins.filter { $0.type.predefinedAccountType == predefinedAccountType }
    }

    private func viewItem(coin: Coin) -> CoinToggleViewItem {
        let enabled = enabledCoins[coin] != nil
        return CoinToggleViewItem(coin: coin, state: .toggleVisible(enabled: enabled))
    }

    private func syncViewItems() {
        let featuredCoins = filteredCoins(coins: interactor.featuredCoins)
        let coins = filteredCoins(coins: interactor.coins).filter { !featuredCoins.contains($0) }

        let featuredViewItems = featuredCoins.map { viewItem(coin: $0) }
        let viewItems = coins.map { viewItem(coin: $0) }

        view?.set(featuredViewItems: featuredViewItems, viewItems: viewItems)
    }

    private func syncProceedButton() {
        view?.setProceedButton(enabled: !enabledCoins.isEmpty)
    }

    private func enable(coin: Coin, requestedCoinSettings: CoinSettings) {
        enabledCoins[coin] = interactor.coinSettingsToSave(coin: coin, accountOrigin: .restored, requestedCoinSettings: requestedCoinSettings)
        syncProceedButton()
    }

}

extension RestoreCoinsPresenter: IRestoreCoinsViewDelegate {

    func onLoad() {
        view?.set(predefinedAccountType: predefinedAccountType)
        view?.setCancelButton(visible: presentationMode == .inApp)

        syncViewItems()
        syncProceedButton()
    }

    func onEnable(viewItem: CoinToggleViewItem) {
        let coin = viewItem.coin

        let coinSettingsToRequest = interactor.coinSettingsToRequest(coin: coin, accountOrigin: .restored)

        if coinSettingsToRequest.isEmpty {
            enable(coin: coin, requestedCoinSettings: [:])
        } else {
            router.showCoinSettings(coin: coin, coinSettings: coinSettingsToRequest, delegate: self)
        }
    }

    func onDisable(viewItem: CoinToggleViewItem) {
        enabledCoins.removeValue(forKey: viewItem.coin)
        syncProceedButton()
    }

    func onTapProceedButton() {
        guard !enabledCoins.isEmpty else {
            return
        }

        router.showRestore(predefinedAccountType: predefinedAccountType, delegate: self)
    }

    func onTapCancelButton() {
        router.close()
    }

}

extension RestoreCoinsPresenter: ICoinSettingsDelegate {

    func onSelect(coinSettings: CoinSettings, coin: Coin) {
        enable(coin: coin, requestedCoinSettings: coinSettings)
    }

    func onCancelSelectingCoinSettings() {
        syncViewItems()
    }

}

extension RestoreCoinsPresenter: IRestoreAccountTypeDelegate {

    func didRestore(accountType: AccountType) {
        let account = interactor.account(accountType: accountType)
        interactor.create(account: account)

        let wallets = enabledCoins.map { (coin, coinSettings) in
            Wallet(coin: coin, account: account, coinSettings: coinSettings)
        }

        interactor.save(wallets: wallets)

        switch presentationMode {
        case .initial:
            router.showMain()
        case .inApp:
            router.close()
        }
    }

}
