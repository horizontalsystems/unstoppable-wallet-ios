protocol IRestoreCoinsView: class {
    func setCancelButton(visible: Bool)
    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem])
    func setProceedButton(enabled: Bool)
}

protocol IRestoreCoinsViewDelegate {
    func onLoad()
    func onEnable(viewItem: CoinToggleViewItem)
    func onDisable(viewItem: CoinToggleViewItem)
    func onTapNextButton()
    func onTapCancelButton()
}

protocol IRestoreCoinsInteractor {
    var coins: [Coin] { get }
    var featuredCoins: [Coin] { get }

    func account(accountType: AccountType) -> Account

    func create(account: Account)
    func save(wallets: [Wallet])

    func coinSettingsToRequest(coin: Coin, accountOrigin: AccountOrigin) -> CoinSettings
    func coinSettingsToSave(coin: Coin, accountOrigin: AccountOrigin, requestedCoinSettings: CoinSettings) -> CoinSettings
}

protocol IRestoreCoinsRouter {
    func showCoinSettings(coin: Coin, coinSettings: CoinSettings, delegate: ICoinSettingsDelegate)
    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: IRestoreAccountTypeDelegate)
    func showMain()
    func close()
}

struct RestoreCoinsEnabledCoin {
    let coin: Coin
    let coinSettings: [CoinSetting: Any]
}

class RestoreCoinsModule {

    enum PresentationMode {
        case initial
        case inApp
    }

}
