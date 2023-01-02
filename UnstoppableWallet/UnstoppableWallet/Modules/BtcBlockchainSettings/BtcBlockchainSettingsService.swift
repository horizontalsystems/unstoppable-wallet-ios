import RxSwift
import RxRelay
import MarketKit

class BtcBlockchainSettingsService {
    private let config: BtcBlockchainSettingsModule.Config
    private let walletManager: WalletManager
    private let disposeBag = DisposeBag()

    private let itemRelay = PublishRelay<Item>()
    private(set) var item: Item = Item(addressFormat: .none, restoreSource: .default, applyEnabled: false) {
        didSet {
            itemRelay.accept(item)
        }
    }

    private let addressFormatMode: AddressFormatMode
    private var derivationItems = [DerivationItem]()
    private var bitcoinCashCoinTypeItems = [BitcoinCashCoinTypeItem]()

    private var initialDerivations = [MnemonicDerivation]()
    private var initialBitcoinCashCoinTypes = [BitcoinCashCoinType]()

    private let restoreSourceEnabled: Bool
    private(set) var restoreSource: RestoreSource = .default

    private var initialRestoreSource: RestoreSource?

    init(config: BtcBlockchainSettingsModule.Config, walletManager: WalletManager) {
        self.config = config
        self.walletManager = walletManager

        let coinSettingTypes = config.blockchain.type.coinSettingTypes(accountOrigin: config.accountOrigin)

        if coinSettingTypes.contains(.derivation) {
            addressFormatMode = .derivation
            let derivations = config.coinSettingsArray.compactMap { $0.derivation }
            derivationItems = config.accountType.supportedDerivations.map { derivation in
                DerivationItem(derivation: derivation, selected: derivations.contains(derivation))
            }
            initialDerivations = derivations
        } else if coinSettingTypes.contains(.bitcoinCashCoinType) {
            addressFormatMode = .bitcoinCashCoinType
            let bitcoinCashCoinTypes = config.coinSettingsArray.compactMap { $0.bitcoinCashCoinType }
            bitcoinCashCoinTypeItems = BitcoinCashCoinType.allCases.map { bitcoinCashCoinType in
                BitcoinCashCoinTypeItem(bitcoinCashCoinType: bitcoinCashCoinType, selected: bitcoinCashCoinTypes.contains(bitcoinCashCoinType))
            }
            initialBitcoinCashCoinTypes = bitcoinCashCoinTypes
        } else {
            addressFormatMode = .none
        }

        if coinSettingTypes.contains(.restoreSource) {
            restoreSourceEnabled = true
            restoreSource = config.coinSettingsArray.first.flatMap { $0.restoreSource } ?? .default
            initialRestoreSource = restoreSource
        } else {
            restoreSourceEnabled = false
        }

        syncItem()
    }

    private func syncItem() {
        let addressFormat: AddressFormat

        switch addressFormatMode {
        case .derivation: addressFormat = .derivation(items: derivationItems)
        case .bitcoinCashCoinType: addressFormat = .bitcoinCashCoinType(items: bitcoinCashCoinTypeItems)
        case .none: addressFormat = .none
        }

        item = Item(
                addressFormat: addressFormat,
                restoreSource: restoreSourceEnabled ? restoreSource : nil,
                applyEnabled: config.mode.initial ? addressFormat.hasCurrent : (hasAddressFormatChanges || hasRestoreSourceChanges)
        )
    }

    private var hasAddressFormatChanges: Bool {
        let initial = MnemonicDerivation.allCases.filter { initialDerivations.contains($0) }
        let current = MnemonicDerivation.allCases.filter { derivation in
            derivationItems.contains { $0.derivation == derivation && $0.selected }
        }

        return initial != current
    }

    private var hasRestoreSourceChanges: Bool {
        restoreSourceEnabled && initialRestoreSource != restoreSource
    }

}

extension BtcBlockchainSettingsService {

    var itemObservable: Observable<Item> {
        itemRelay.asObservable()
    }

    var approveApplyRequired: Bool {
        config.mode.approveApplyRequired && hasRestoreSourceChanges
    }

    var addressFormatHidden: Bool {
        config.mode.addressFormatHidden
    }

    var autoSave: Bool {
        config.mode.autoSave
    }

    var blockchain: Blockchain {
        config.blockchain
    }

    func toggleAddressFormat(index: Int, selected: Bool) {
        switch addressFormatMode {
        case .derivation: derivationItems[index].selected = selected
        case .bitcoinCashCoinType: bitcoinCashCoinTypeItems[index].selected = selected
        case .none: ()
        }

        syncItem()
    }

    func set(restoreSource: RestoreSource) {
        self.restoreSource = restoreSource
        syncItem()
    }

    func resolveCoinSettingsArray() -> [CoinSettings] {
        switch addressFormatMode {
        case .derivation:
            return derivationItems.compactMap { item in
                guard item.selected else {
                    return nil
                }

                var coinSettings: CoinSettings = [.derivation: item.derivation.rawValue]

                if restoreSourceEnabled {
                    coinSettings[.restoreSource] = restoreSource.rawValue
                }

                return coinSettings
            }
        case .bitcoinCashCoinType:
            return bitcoinCashCoinTypeItems.compactMap { item in
                guard item.selected else {
                    return nil
                }

                var coinSettings: CoinSettings = [.bitcoinCashCoinType: item.bitcoinCashCoinType.rawValue]

                if restoreSourceEnabled {
                    coinSettings[.restoreSource] = restoreSource.rawValue
                }

                return coinSettings
            }
        case .none:
            return [[.restoreSource: restoreSource.rawValue]]
        }
    }

    func saveSettings() {
        guard case .changeSource(let wallet) = config.mode else {
            return
        }

        let coinSettingsArray = resolveCoinSettingsArray()

        let oldWallets = walletManager.activeWallets.filter { $0.token.blockchainType == wallet.token.blockchainType }
        let newWallets = coinSettingsArray.map { Wallet(configuredToken: ConfiguredToken(token: wallet.token, coinSettings: $0), account: wallet.account) }

        walletManager.handle(newWallets: newWallets, deletedWallets: oldWallets)
    }

}

extension BtcBlockchainSettingsService {

    enum AddressFormatMode {
        case derivation
        case bitcoinCashCoinType
        case none
    }

    struct Item {
        let addressFormat: AddressFormat
        let restoreSource: RestoreSource?
        let applyEnabled: Bool
    }

    struct DerivationItem {
        let derivation: MnemonicDerivation
        var selected: Bool
    }

    struct BitcoinCashCoinTypeItem {
        let bitcoinCashCoinType: BitcoinCashCoinType
        var selected: Bool
    }

    enum AddressFormat {
        case derivation(items: [DerivationItem])
        case bitcoinCashCoinType(items: [BitcoinCashCoinTypeItem])
        case none

        var hasCurrent: Bool {
            switch self {
            case let .derivation(items): return items.contains { $0.selected }
            case let .bitcoinCashCoinType(items): return items.contains { $0.selected }
            case .none: return true
            }
        }
    }

}
