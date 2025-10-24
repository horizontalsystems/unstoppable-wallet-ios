import Combine
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import RxSwift
import TronKit
import UIKit

class WatchViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let marketKit = Core.shared.marketKit
    private let accountFactory = Core.shared.accountFactory
    private let restoreSettingsManager = Core.shared.restoreSettingsManager
    private let moneroParser = MoneroWatchWalletParser()
    private let addressUriParser = AddressParserFactory.parser(blockchainType: nil, tokenType: nil)
    private let addressParserChain = AddressParserChain()
    private var disposeBag = DisposeBag()

    let defaultAccountName: String

    @Published var state = State.notReady {
        didSet {
            switch state {
            case let .error(error):
                textCaution = .caution(Caution(
                    text: (error as? LocalizedError)?.errorDescription ?? "watch_address.error.not_supported".localized,
                    type: .error
                ))
            default: ()
            }
        }
    }

    @Published var name: String
    @Published var text = AppConfig.defaultWatchAddress ?? "" {
        didSet {
            guard !syncingTextWithAddress, text != oldValue else {
                return
            }

            textCaution = .none

            guard !text.isEmpty else {
                state = .notReady
                return
            }

            parse(text: text)
        }
    }

    @Published var textCaution: CautionState = .none

    @Published var requiredFields: [RequiredField] = []
    @Published var viewKey = "" {
        didSet {
            guard oldValue != viewKey else {
                return
            }

            guard let address else {
                return
            }

            sync(address: address)
        }
    }

    @Published var viewKeyCaution: CautionState = .none
    @Published var height = "" {
        didSet {
            guard oldValue != height else {
                return
            }

            guard let address else {
                return
            }

            sync(address: address)
        }
    }

    @Published var heightCaution: CautionState = .none

    private var syncingTextWithAddress: Bool = false
    private var address: Address? {
        didSet {
            syncingTextWithAddress = true
            if let address {
                if let domain = address.domain {
                    name = domain
                    text = domain
                } else {
                    text = address.raw
                }
            }
            syncingTextWithAddress = false
        }
    }

    let itemsSubject = PassthroughSubject<Items, Never>()
    let successSubject = PassthroughSubject<Void, Never>()

    init() {
        defaultAccountName = accountFactory.nextWatchAccountName
        name = defaultAccountName

        addressParserChain.append(handlers:
            AddressParserFactory.parserChainHandlers(blockchainType: .ethereum, withEns: true)
                + BtcBlockchainManager.blockchainTypes.flatMap {
                    AddressParserFactory.parserChainHandlers(blockchainType: $0, withEns: false)
                }
                + AddressParserFactory.parserChainHandlers(blockchainType: .tron)
                + AddressParserFactory.parserChainHandlers(blockchainType: .ton)
                + AddressParserFactory.parserChainHandlers(blockchainType: .stellar)
                + AddressParserFactory.parserChainHandlers(blockchainType: .monero)
        )
    }

    private func parse(text: String) {
        if let addressUri = try? addressUriParser.parse(url: text, customSchemeHandling: true) {
            parseAddressUri(addressUri: addressUri)
        } else {
            parseAddress(text: text)
        }
    }

    private func parseAddressUri(addressUri: AddressUri) {
        if let (address, viewKey, height) = moneroParser.parse(uri: addressUri) {
            self.address = address
            self.viewKey = viewKey
            self.height = height
        } else {
            parseAddress(text: addressUri.address)
        }
    }

    private func parseAddress(text: String) {
        disposeBag = DisposeBag()

        addressParserChain
            .handle(address: text)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] in
                    guard let address = $0 else {
                        self?.parseExtendedKey(text: text)
                        return
                    }
                    self?.address = address
                    self?.sync(address: address)
                },
                onError: { [weak self] _ in
                    self?.parseExtendedKey(text: text)
                }
            )
            .disposed(by: disposeBag)
    }

    private func parseExtendedKey(text: String) {
        address = nil
        clearRequiredFields()

        do {
            let extendedKey = try HDExtendedKey(extendedKey: text)

            guard case .public = extendedKey else {
                state = .error(error: PublicKeyResolveError.nonPublicKey)
                return
            }

            switch extendedKey.derivedType {
            case .account:
                state = .ready(accountType: .hdExtendedKey(key: extendedKey))
            default:
                state = .error(error: PublicKeyResolveError.notSupportedDerivedType)
            }
        } catch {
            state = .error(error: ResolveError.notSupported)
        }
    }

    private func sync(address: Address, forceRequiredFields: Bool = false) {
        if address.blockchainType == .monero {
            requiredFields = [.viewKey, .height]
        } else {
            clearRequiredFields()
        }

        do {
            let accountType: AccountType
            if let bitcoinAddress = address as? BitcoinAddress, let blockchainType = bitcoinAddress.blockchainType {
                accountType = .btcAddress(address: bitcoinAddress.raw, blockchainType: blockchainType, tokenType: bitcoinAddress.tokenType)
            } else {
                switch address.blockchainType {
                case let evmAddress where EvmBlockchainManager.blockchainTypes.contains(where: { $0 == evmAddress }):
                    accountType = try .evmAddress(address: EvmKit.Address(hex: address.raw))
                case .tron:
                    accountType = try .tronAddress(address: TronKit.Address(address: address.raw))
                case .ton:
                    accountType = .tonAddress(address: address.raw)
                case .stellar:
                    accountType = .stellarAccount(accountId: address.raw)
                case .monero:
                    (state, viewKeyCaution, heightCaution) = moneroParser.parseAndValidate(
                        address: address, viewKey: viewKey, height: height, forceRequiredFields: forceRequiredFields
                    )
                    return
                default: return
                }
            }
            state = .ready(accountType: accountType)
        } catch {
            state = .error(error: error)
        }
    }

    private func validateAndGetAccount() -> AccountType? {
        switch state {
        case let .ready(accountType):
            return accountType

        case .incomplete:
            if let address {
                sync(address: address, forceRequiredFields: true)
            }

            return nil

        case .notReady:
            textCaution = .caution(Caution(text: "watch_address.error.address_required".localized, type: .error))
            return nil

        case .error:
            return nil
        }
    }

    private func resolveItems(accountType: AccountType) -> Items? {
        let tokenQueries: [TokenQuery]

        switch accountType {
        case .mnemonic, .evmPrivateKey, .stellarSecretKey:
            return nil

        case .evmAddress:
            let blockchains = evmBlockchainManager.allBlockchains
                .sorted(by: { $0.type.order < $1.type.order })

            return .blockchains(blockchains: blockchains)

        case .tronAddress:
            tokenQueries = BlockchainType.tron.nativeTokenQueries

        case .tonAddress:
            tokenQueries = BlockchainType.ton.nativeTokenQueries

        case .stellarAccount:
            tokenQueries = BlockchainType.stellar.nativeTokenQueries

        case let .hdExtendedKey(key):
            guard case .public = key else {
                return nil
            }

            tokenQueries = BtcBlockchainManager.blockchainTypes.map(\.nativeTokenQueries).flatMap { $0 }

        case let .btcAddress(_, blockchainType, tokenType):
            tokenQueries = [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .moneroWatchAccount:
            tokenQueries = [TokenQuery(blockchainType: .monero, tokenType: .native)]
        }

        guard let tokens = try? marketKit.tokens(queries: tokenQueries) else {
            return nil
        }

        return .coins(tokens: tokens.filter { accountType.supports(token: $0) })
    }

    private func enableWallets(account: Account, items: Items, enabledUids: [String]) {
        var wallets = [Wallet]()

        switch items {
        case let .coins(tokens):
            for token in tokens {
                if enabledUids.contains(token.tokenQuery.id) {
                    wallets.append(Wallet(token: token, account: account))
                }
            }

        case let .blockchains(blockchains):
            var tokenQueries = [TokenQuery]()
            for blockchain in blockchains {
                if enabledUids.contains(blockchain.uid) {
                    tokenQueries.append(blockchain.type.defaultTokenQuery)
                }
            }

            do {
                let blockchainNativeTokenWallets = try marketKit.tokens(queries: tokenQueries).map { token in
                    Wallet(token: token, account: account)
                }
                wallets.append(contentsOf: blockchainNativeTokenWallets)
            } catch {}
        }

        walletManager.save(wallets: wallets)
    }

    private func clearRequiredFields() {
        requiredFields = []
        viewKey = ""
        viewKeyCaution = .none
        height = ""
        heightCaution = .none
    }
}

extension WatchViewModel {
    func onProceed() {
        guard let accountType = validateAndGetAccount() else {
            return
        }

        let items = resolveItems(accountType: accountType) ?? .coins(tokens: [])

        if case let .coins(tokens) = items, tokens.count <= 1 {
            watch(items: items, enabledUids: tokens.map(\.tokenQuery.id))
        } else {
            itemsSubject.send(items)
        }
    }

    func watch(items: Items, enabledUids: [String]) {
        guard case let .ready(accountType) = state else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountName = trimmedName.isEmpty ? defaultAccountName : trimmedName
        let account = accountFactory.watchAccount(type: accountType, name: accountName)

        accountManager.save(account: account)

        if case let .moneroWatchAccount(_, _, restoreHeight) = accountType {
            restoreSettingsManager.save(settings: [.birthdayHeight: String(restoreHeight)], account: account, blockchainType: .monero)
        }

        enableWallets(account: account, items: items, enabledUids: enabledUids)

        stat(page: .watchWallet, event: .watchWallet(walletType: accountType.statDescription))

        successSubject.send()
    }
}

extension WatchViewModel {
    enum State {
        case ready(accountType: AccountType)
        case incomplete
        case notReady
        case error(error: Error)
    }

    enum RequiredField {
        case viewKey
        case height
    }

    enum Items: Hashable {
        case coins(tokens: [Token])
        case blockchains(blockchains: [Blockchain])

        var title: String {
            switch self {
            case .blockchains: return "watch_address.choose_blockchain".localized
            case .coins: return "watch_address.choose_coin".localized
            }
        }
    }

    enum ResolveError: Error {
        case notSupported
    }

    enum PublicKeyResolveError: Error, LocalizedError {
        case notSupportedDerivedType
        case nonPublicKey

        var errorDescription: String? {
            switch self {
            case .notSupportedDerivedType: return "watch_address.error.not_supported_derived_type".localized
            case .nonPublicKey: return "watch_address.error.non_public_key".localized
            }
        }
    }
}
