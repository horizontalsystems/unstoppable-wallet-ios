import BitcoinCashKit
import BitcoinKit
import Combine
import DashKit
import Foundation
import HdWalletKit
import LitecoinKit

class ExtendedKeyViewModel: ObservableObject {
    let mode: Mode
    private let accountType: AccountType

    private var derivation: MnemonicDerivation = .bip44
    private var blockchain: Blockchain = .bitcoin
    private var account: Int = 0

    private(set) var item: Item = .empty

    @Published private(set) var viewItem: ViewItem = .empty
    @Published private(set) var keyHidden = false

    init(mode: Mode, accountType: AccountType) {
        self.mode = mode
        self.accountType = accountType

        syncDerivation()
        syncItem()
        sync()
    }

    private func syncDerivation() {
        switch accountType {
        case let .hdExtendedKey(key):
            let derivations = key.purposes.map(\.mnemonicDerivation)
            if !derivations.contains(derivation) {
                derivation = derivations[0]
            }
        default: ()
        }

        syncBlockchain()
    }

    private func syncBlockchain() {
        if !supportedBlockchains.contains(blockchain) {
            blockchain = supportedBlockchains[0]
        }
    }

    private var derivationSwitchable: Bool {
        switch accountType {
        case .mnemonic: return true
        default: return false
        }
    }

    private var blockchainSwitchable: Bool {
        supportedBlockchains.count > 1
    }

    private var resolvedBlockchain: Blockchain? {
        switch mode {
        case .bip32RootKey:
            return nil
        case .accountExtendedPrivateKey, .accountExtendedPublicKey:
            switch accountType {
            case .mnemonic:
                return blockchain
            case let .hdExtendedKey(extendedKey):
                switch extendedKey.derivedType {
                case .master: return blockchain
                default: return nil
                }
            default:
                return nil
            }
        }
    }

    private var resolvedAccount: Int? {
        switch mode {
        case .bip32RootKey: return nil
        case .accountExtendedPrivateKey, .accountExtendedPublicKey:
            switch accountType {
            case .mnemonic:
                return account
            case let .hdExtendedKey(extendedKey):
                switch extendedKey.derivedType {
                case .master: return account
                default: return nil
                }
            default:
                return nil
            }
        }
    }

    private var resolvedKey: String? {
        switch accountType {
        case .mnemonic:
            guard let rootKey = rootKey(seed: accountType.mnemonicSeed) else {
                return nil
            }

            return key(rootKey: rootKey)
        case let .hdExtendedKey(extendedKey):
            switch extendedKey {
            case let .private(privateKey):
                switch extendedKey.derivedType {
                case .master:
                    return key(rootKey: privateKey)
                case .account:
                    switch mode {
                    case .accountExtendedPrivateKey: return privateKey.extended()
                    case .accountExtendedPublicKey: return privateKey.publicKey().extended()
                    default: return nil
                    }
                default: return nil
                }
            case let .public(publicKey):
                switch extendedKey.derivedType {
                case .account:
                    switch mode {
                    case .accountExtendedPublicKey: return publicKey.extended()
                    default: return nil
                    }
                default: return nil
                }
            }
        default:
            return nil
        }
    }

    private var keyIsPrivate: Bool {
        switch mode {
        case .bip32RootKey, .accountExtendedPrivateKey: return true
        case .accountExtendedPublicKey: return false
        }
    }

    private func syncItem() {
        item = Item(
            derivation: derivation,
            derivationSwitchable: derivationSwitchable,
            blockchain: resolvedBlockchain,
            blockchainSwitchable: blockchainSwitchable,
            account: resolvedAccount,
            key: resolvedKey,
            keyIsPrivate: keyIsPrivate
        )
    }

    private func key(rootKey: HDPrivateKey) -> String? {
        let keychain = HDKeychain(privateKey: rootKey)

        switch mode {
        case .bip32RootKey:
            return rootKey.extended()
        case .accountExtendedPrivateKey:
            let version = try? HDExtendedKeyVersion(purpose: derivation.purpose, coinType: blockchain.extendedKeyCoinType, isPrivate: true)
            return try? keychain.derivedKey(path: "m/\(derivation.purpose.rawValue)'/\(blockchain.coinType)'/\(account)'").extended(customVersion: version)
        case .accountExtendedPublicKey:
            let version = try? HDExtendedKeyVersion(purpose: derivation.purpose, coinType: blockchain.extendedKeyCoinType, isPrivate: false)
            return try? keychain.derivedKey(path: "m/\(derivation.purpose.rawValue)'/\(blockchain.coinType)'/\(account)'").publicKey().extended(customVersion: version)
        }
    }

    private func rootKey(seed: Data?) -> HDPrivateKey? {
        guard let seed else {
            return nil
        }

        guard let version = try? HDExtendedKeyVersion(purpose: derivation.purpose, coinType: blockchain.extendedKeyCoinType) else {
            return nil
        }

        return HDPrivateKey(seed: seed, xPrivKey: version.rawValue)
    }

    private func sync() {
        viewItem = ViewItem(
            derivation: item.derivation.rawValue.uppercased(),
            derivationSwitchable: item.derivationSwitchable,
            blockchain: item.blockchain.map(\.title),
            blockchainSwitchable: item.blockchainSwitchable,
            account: item.account.map { "\($0)" },
            key: item.key ?? "",
            keyIsPrivate: item.keyIsPrivate
        )
        keyHidden = item.keyIsPrivate
    }

    private func set(derivation: MnemonicDerivation) {
        self.derivation = derivation
        syncDerivation()
        syncItem()
        sync()
    }

    private func set(blockchain: Blockchain) {
        self.blockchain = blockchain
        syncBlockchain()
        syncItem()
        sync()
    }

    private func set(account: Int) {
        self.account = account
        syncItem()
        sync()
    }
}

extension ExtendedKeyViewModel {
    var supportedBlockchains: [Blockchain] {
        var coinTypesDerivableFromKey = [HDExtendedKeyVersion.ExtendedKeyCoinType]()
        if case let .hdExtendedKey(key) = accountType {
            coinTypesDerivableFromKey.append(contentsOf: key.coinTypes)
        }

        switch derivation {
        case .bip44:
            if coinTypesDerivableFromKey.count == 1, coinTypesDerivableFromKey[0] == .litecoin {
                return [.litecoin]
            } else {
                return [.bitcoin, .bitcoinCash, .litecoin, .dash]
            }
        default:
            if coinTypesDerivableFromKey.count == 1, coinTypesDerivableFromKey[0] == .litecoin {
                return [.litecoin]
            } else {
                return [.bitcoin, .litecoin]
            }
        }
    }

    var title: String {
        switch mode {
        case .bip32RootKey: return "extended_key.bip32_root_key".localized
        case .accountExtendedPrivateKey: return "extended_key.account_extended_private_key".localized
        case .accountExtendedPublicKey: return "extended_key.account_extended_public_key".localized
        }
    }

    var derivationViewItems: [AlertViewItem] {
        MnemonicDerivation.allCases.map { derivation in
            AlertViewItem(
                text: derivation.rawValue.uppercased(),
                selected: item.derivation == derivation
            )
        }
    }

    var blockchainViewItems: [AlertViewItem] {
        supportedBlockchains.map { blockchain in
            AlertViewItem(
                text: blockchain.title,
                selected: item.blockchain == blockchain
            )
        }
    }

    var accountViewItems: [AlertViewItem] {
        Range<Int>(0 ... 5).map { account in
            AlertViewItem(
                text: "\(account)",
                selected: item.account == account
            )
        }
    }

    var statPage: StatPage {
        switch mode {
        case .bip32RootKey: return .bip32RootKey
        case .accountExtendedPrivateKey: return .accountExtendedPrivateKey
        case .accountExtendedPublicKey: return .accountExtendedPublicKey
        }
    }

    func onSelectDerivation(index: Int) {
        set(derivation: MnemonicDerivation.allCases[index])
        stat(page: statPage, event: .select(entity: .derivation))
    }

    func onSelectBlockchain(index: Int) {
        set(blockchain: supportedBlockchains[index])
        stat(page: statPage, event: .select(entity: .blockchain))
    }

    func onSelectAccount(index: Int) {
        set(account: index)
        stat(page: statPage, event: .select(entity: .account))
    }

    func toggleKeyHidden() {
        keyHidden.toggle()
        stat(page: statPage, event: .toggleHidden)
    }

    func copy() {
        let statPage = statPage

        if viewItem.keyIsPrivate {
            Coordinator.shared.presentCopyConfirmation(value: viewItem.key) {
                stat(page: statPage, event: .copy(entity: .key))
            }
        } else {
            CopyHelper.copyAndNotify(value: viewItem.key)
            stat(page: statPage, event: .copy(entity: .key))
        }
    }
}

extension ExtendedKeyViewModel {
    enum Mode {
        case bip32RootKey
        case accountExtendedPrivateKey
        case accountExtendedPublicKey
    }

    struct Item {
        let derivation: MnemonicDerivation
        let derivationSwitchable: Bool
        let blockchain: Blockchain?
        let blockchainSwitchable: Bool
        let account: Int?
        let key: String?
        let keyIsPrivate: Bool

        static var empty: Item {
            Item(derivation: .bip44, derivationSwitchable: false, blockchain: nil, blockchainSwitchable: false, account: nil, key: nil, keyIsPrivate: false)
        }
    }

    enum Blockchain {
        case bitcoin
        case bitcoinCash
        case litecoin
        case dash

        var title: String {
            switch self {
            case .bitcoin: return "Bitcoin"
            case .bitcoinCash: return "Bitcoin Cash"
            case .litecoin: return "Litecoin"
            case .dash: return "Dash"
            }
        }

        var extendedKeyCoinType: HDExtendedKeyVersion.ExtendedKeyCoinType {
            switch self {
            case .bitcoin, .bitcoinCash, .dash: return .bitcoin
            case .litecoin: return .litecoin
            }
        }

        var coinType: UInt32 {
            switch self {
            case .bitcoin: return BitcoinKit.MainNet().coinType
            case .bitcoinCash: return BitcoinCashKit.MainNet().coinType
            case .litecoin: return LitecoinKit.MainNet().coinType
            case .dash: return DashKit.MainNet().coinType
            }
        }
    }

    struct ViewItem {
        let derivation: String
        let derivationSwitchable: Bool
        let blockchain: String?
        let blockchainSwitchable: Bool
        let account: String?
        let key: String
        let keyIsPrivate: Bool

        static var empty: ViewItem {
            ViewItem(derivation: "", derivationSwitchable: false, blockchain: nil, blockchainSwitchable: false, account: nil, key: "", keyIsPrivate: false)
        }
    }
}
