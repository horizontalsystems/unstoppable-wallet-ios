class DerivationSettingsInteractor {
    private let derivationSettingsManager: IDerivationSettingsManager
    private let walletManager: IWalletManager

    init(derivationSettingsManager: IDerivationSettingsManager, walletManager: IWalletManager) {
        self.derivationSettingsManager = derivationSettingsManager
        self.walletManager = walletManager
    }

}

extension DerivationSettingsInteractor: IDerivationSettingsInteractor {

    var allActiveSettings: [(setting: DerivationSetting, wallets: [Wallet])] {
        derivationSettingsManager.allActiveSettings
    }

    var wallets: [Wallet] {
        walletManager.wallets
    }

    func save(setting: DerivationSetting) {
        derivationSettingsManager.save(setting: setting)
    }

}
