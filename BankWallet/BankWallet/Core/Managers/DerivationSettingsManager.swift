import RxSwift

class DerivationSettingsManager {
    private let supportedCoinTypes: [(coinType: CoinType, defaultDerivation: MnemonicDerivation)] = [
        (.bitcoin, .bip49),
        (.litecoin, .bip49)
    ]

    private let walletManager: IWalletManager
    private let storage: IBlockchainSettingsStorage

    private let subject = PublishSubject<CoinType>()

    init (walletManager: IWalletManager, storage: IBlockchainSettingsStorage) {
        self.walletManager = walletManager
        self.storage = storage
    }

    private func defaultSetting(coinType: CoinType) -> DerivationSetting? {
        guard let derivation = supportedCoinTypes.first(where: { $0.coinType == coinType })?.defaultDerivation else {
            return nil
        }

        return DerivationSetting(coinType: coinType, derivation: derivation)
    }

}

extension DerivationSettingsManager: IDerivationSettingsManager {

    var allActiveSettings: [(setting: DerivationSetting, wallets: [Wallet])] {
        let wallets = walletManager.wallets

        return supportedCoinTypes.compactMap { (coinType, _) in
            let coinTypeWallets = wallets.filter { $0.coin.type == coinType }

            guard !coinTypeWallets.isEmpty else {
                return nil
            }

            guard let setting = setting(coinType: coinType) else {
                return nil
            }

            return (setting: setting, wallets: coinTypeWallets)
        }
    }

    var derivationUpdatedObservable: Observable<CoinType> {
        subject.asObservable()
    }

    func setting(coinType: CoinType) -> DerivationSetting? {
        let storedSetting = storage.derivationSetting(coinType: coinType)
        return storedSetting ?? defaultSetting(coinType: coinType)
    }

    func save(setting: DerivationSetting) {
        storage.save(derivationSettings: [setting])
        subject.onNext(setting.coinType)
    }

    func reset() {
        storage.deleteDerivationSettings()
    }

}
