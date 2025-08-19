import Combine
import EvmKit
import Foundation
import HdWalletKit
import MarketKit
import RxSwift
import TronKit

class WatchViewModel: ObservableObject {
    private let accountManager = Core.shared.accountManager
    private let walletManager = Core.shared.walletManager
    private let evmBlockchainManager = Core.shared.evmBlockchainManager
    private let marketKit = Core.shared.marketKit
    private let accountFactory = Core.shared.accountFactory
    private let uriParser = AddressParserFactory.parser(blockchainType: nil, tokenType: nil)
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

    @Published var text = "" {
        didSet {
            textCaution = .none

            guard !text.isEmpty else {
                state = .notReady
                return
            }

            parse(text: text)
        }
    }

    @Published var textCaution: CautionState = .none

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
        )
    }

    private func parse(text: String) {
        if let address = try? uriParser.parse(url: text) {
            parseAddress(text: address.address)
        } else {
            parseAddress(text: text)
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
                    self?.sync(address: address)
                },
                onError: { [weak self] _ in
                    self?.parseExtendedKey(text: text)
                }
            )
            .disposed(by: disposeBag)
    }

    private func parseExtendedKey(text: String) {
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

    private func sync(address: Address) {
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
                default: return
                }
            }
            state = .ready(accountType: accountType)
        } catch {
            state = .error(error: error)
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
}

extension WatchViewModel {
    func onProceed() {
        guard case let .ready(accountType) = state else {
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
        enableWallets(account: account, items: items, enabledUids: enabledUids)

        stat(page: .watchWallet, event: .watchWallet(walletType: accountType.statDescription))

        successSubject.send()
    }
}

extension WatchViewModel {
    enum State {
        case ready(accountType: AccountType)
        case notReady
        case error(error: Error)

        var watchEnabled: Bool {
            switch self {
            case .ready: return true
            case .notReady, .error: return false
            }
        }
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
