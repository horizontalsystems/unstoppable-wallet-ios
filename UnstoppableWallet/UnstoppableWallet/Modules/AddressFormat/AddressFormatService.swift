import RxSwift
import RxRelay

class AddressFormatService {
    private let derivationSettingsManager: IDerivationSettingsManager
    private let bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(derivationSettingsManager: IDerivationSettingsManager, bitcoinCashCoinTypeManager: BitcoinCashCoinTypeManager) {
        self.derivationSettingsManager = derivationSettingsManager
        self.bitcoinCashCoinTypeManager = bitcoinCashCoinTypeManager

        syncItems()
    }

    private func syncItems() {
        var items = [Item]()

        for (setting, coinType) in derivationSettingsManager.allActiveSettings {
            items.append(Item(coinType: coinType, type: .derivation(derivations: MnemonicDerivation.allCases, current: setting.derivation)))
        }

        if bitcoinCashCoinTypeManager.hasActiveSetting {
            items.append(Item(coinType: .bitcoinCash, type: .bitcoinCashCoinType(types: BitcoinCashCoinType.allCases, current: bitcoinCashCoinTypeManager.bitcoinCashCoinType)))
        }

        self.items = items
    }

}

extension AddressFormatService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func set(derivation: MnemonicDerivation, coinType: CoinType) {
        let setting = DerivationSetting(coinType: coinType, derivation: derivation)
        derivationSettingsManager.save(setting: setting)

        syncItems()
    }

    func set(bitcoinCashCoinType: BitcoinCashCoinType) {
        bitcoinCashCoinTypeManager.save(bitcoinCashCoinType: bitcoinCashCoinType)

        syncItems()
    }

}

extension AddressFormatService {

    struct Item {
        let coinType: CoinType
        let type: ItemType
    }

    enum ItemType {
        case derivation(derivations: [MnemonicDerivation], current: MnemonicDerivation)
        case bitcoinCashCoinType(types: [BitcoinCashCoinType], current: BitcoinCashCoinType)
    }

}
