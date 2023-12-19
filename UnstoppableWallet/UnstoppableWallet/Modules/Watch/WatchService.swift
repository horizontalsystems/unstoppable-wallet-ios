import Combine
import EvmKit
import Foundation
import HdWalletKit
import HsExtensions
import RxSwift
import TronKit

class WatchService {
    private var disposeBag = DisposeBag()
    private let accountFactory: AccountFactory
    private let addressParserChain: AddressParserChain
    private let uriParser: AddressUriParser

    private(set) var name: String?
    @PostPublished private(set) var state = State.notReady

    private var text: String = ""

    init(accountFactory: AccountFactory, addressParserChain: AddressParserChain, uriParser: AddressUriParser) {
        self.accountFactory = accountFactory
        self.addressParserChain = addressParserChain
        self.uriParser = uriParser
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
            state = .notReady
        }
    }

    private func parseAddress(text: String) {
        disposeBag = DisposeBag()

        addressParserChain
            .handle(address: text)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
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

    private func parseUri(text: String) {
        if let address = try? uriParser.parse(url: text) {
            parseAddress(text: address.address)
        } else {
            parseAddress(text: text)
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
                default: return
                }
            }
            state = .ready(accountType: accountType)
        } catch {
            state = .error(error: error)
        }
    }
}

extension WatchService {
    var defaultAccountName: String {
        accountFactory.nextWatchAccountName
    }

    var resolvedName: String {
        let trimmedName = (name ?? defaultAccountName).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName
    }

    func set(name: String) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.name = nil
        } else {
            self.name = name
        }
    }

    func set(text: String) {
        self.text = text
        guard !text.isEmpty else {
            state = .notReady
            return
        }

        parseUri(text: text)
    }

    func resolve() -> AccountType? {
        switch state {
        case let .ready(accountType): return accountType
        default: return nil
        }
    }
}

extension WatchService {
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
