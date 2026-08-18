import Foundation
import MarketKit
import RxSwift

/// Resolves Zano address aliases (e.g. "@zano" or "zano") into addresses through the current
/// node's daemon RPC, the way ENS domains resolve for EVM chains.
class ZanoAliasAddressParserItem: IAddressParserItem {
    // On-chain alias rules (zano currency_config.h): lowercase a-z, digits, '-' and '.',
    // up to 255 characters.
    private static let aliasRegex = try! NSRegularExpression(pattern: "^[a-z0-9.-]{1,255}$")

    private let resolver: ZanoAliasResolver
    private let cacheLock = NSLock()
    private var cache = [String: String]()

    init(resolver: ZanoAliasResolver) {
        self.resolver = resolver
    }

    var blockchainType: BlockchainType { .zano }

    static func normalize(_ input: String) -> String? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Never treat something that already is a valid address as an alias. Checked against
        // the original casing: addresses are mixed-case base58, so validating the lowercased
        // form would never match and every pasted address would fire an alias lookup.
        guard !ZanoAdapter.isValidAddress(trimmed) else { return nil }

        var value = trimmed.lowercased()

        let hadPrefix = value.hasPrefix("@")
        if hadPrefix {
            value = String(value.dropFirst())
        }

        // A bare word needs 2+ characters so a lookup is not fired on the first keystroke
        guard value.count >= (hadPrefix ? 1 : 2) else { return nil }

        let range = NSRange(value.startIndex..., in: value)
        guard Self.aliasRegex.firstMatch(in: value, range: range) != nil else { return nil }

        return value
    }

    func handle(address: String) -> Single<Address> {
        guard let alias = Self.normalize(address) else {
            return .error(AddressService.AddressError.invalidAddress(blockchainName: "Zano"))
        }

        cacheLock.lock()
        let cached = cache[alias]
        cacheLock.unlock()

        if let cached {
            return .just(Address(raw: cached, domain: address, blockchainType: .zano))
        }

        let resolver = resolver

        return Single.create { [weak self] observer in
            let task = Task {
                do {
                    if let resolved = try await resolver.resolve(alias: alias), ZanoAdapter.isValidAddress(resolved) {
                        if let self {
                            self.cacheLock.lock()
                            self.cache[alias] = resolved
                            self.cacheLock.unlock()
                        }

                        observer(.success(Address(raw: resolved, domain: address, blockchainType: .zano)))
                    } else {
                        observer(.error(AddressService.AddressError.invalidAddress(blockchainName: "Zano")))
                    }
                } catch {
                    observer(.error(error))
                }
            }

            return Disposables.create { task.cancel() }
        }
    }

    func isValid(address: String) -> Single<Bool> {
        .just(Self.normalize(address) != nil)
    }
}
