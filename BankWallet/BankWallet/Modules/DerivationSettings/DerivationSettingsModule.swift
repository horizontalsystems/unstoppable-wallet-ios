protocol IDerivationSettingsView: class {
    func set(viewItems: [DerivationSettingSectionViewItem])
}

protocol IDerivationSettingsInteractor: class {
    var allActiveSettings: [(setting: DerivationSetting, wallets: [Wallet])] { get }
    var wallets: [Wallet] { get }

    func save(setting: DerivationSetting)
}

protocol IDerivationSettingsViewDelegate {
    func onLoad()
    func onSelect(chainIndex: Int, settingIndex: Int)
}

protocol IDerivationSettingsRouter {
    func showChangeConfirmation(coinTitle: String, setting: DerivationSetting, delegate: IDerivationSettingConfirmationDelegate)
}

struct DerivationSettingsItem {
    let firstCoin: Coin
    let setting: DerivationSetting
}
