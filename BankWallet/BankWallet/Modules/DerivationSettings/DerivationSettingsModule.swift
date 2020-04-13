protocol IDerivationSettingsView: class {
    func set(viewItems: [DerivationSettingSectionViewItem])
    func showChangeAlert(setting: DerivationSetting, coinTitle: String)
}

protocol IDerivationSettingsInteractor: class {
    var allActiveSettings: [(setting: DerivationSetting, wallets: [Wallet])] { get }
    var wallets: [Wallet] { get }

    func save(setting: DerivationSetting)
}

protocol IDerivationSettingsViewDelegate {
    func onLoad()
    func onSelect(chainIndex: Int, settingIndex: Int)
    func proceedChange(setting: DerivationSetting)
}

protocol IDerivationSettingsRouter {
}

struct DerivationSettingsItem {
    let firstCoin: Coin
    let setting: DerivationSetting
}
