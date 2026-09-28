import Foundation
import MarketKit
import RxSwift

/// Resolves Zcash Names (`alice.zcash`, `alice.zec`) into unified addresses through the ZNS indexer (Android
/// `AddressHandlerZns`). The resolved address then goes through the regular Zcash parser, the way an ENS name goes
/// through its chain's parser.
class ZnsAddressParserItem: IAddressParserItem {
    // On-chain name rules (zcashme/ZNS memo.rs): 1 to 62 lowercase ASCII letters and digits
    private static let nameRegex = try! NSRegularExpression(pattern: "\\A[a-z0-9]{1,62}\\z")
    private static let suffixes = [".zcash", ".zec"]

    private let resolver: ZnsResolver
    private let rawAddressParserItem: IAddressParserItem

    init(resolver: ZnsResolver, rawAddressParserItem: IAddressParserItem) {
        self.resolver = resolver
        self.rawAddressParserItem = rawAddressParserItem
    }

    var blockchainType: BlockchainType { rawAddressParserItem.blockchainType }

    /// The on-chain name and the suffix it was typed with, or nil when `input` is not a Zcash Name. The suffix is
    /// required: a bare word is indistinguishable from a partly typed address, and the field validates every keystroke.
    static func normalize(_ input: String) -> (name: String, suffix: String)? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let suffix = suffixes.first(where: { value.hasSuffix($0) }) else {
            return nil
        }

        let name = String(value.dropLast(suffix.count))
        let range = NSRange(name.startIndex..., in: name)
        guard nameRegex.firstMatch(in: name, range: range) != nil else {
            return nil
        }

        return (name, suffix)
    }

    func handle(address: String) -> Single<Address> {
        let invalidAddress = AddressService.AddressError.invalidAddress(blockchainName: "Zcash")

        guard let (name, suffix) = Self.normalize(address) else {
            return .error(invalidAddress)
        }

        let resolver = resolver
        let rawAddressParserItem = rawAddressParserItem

        // No caching: a name can be re-pointed at any time, and a stale address would silently redirect a later send
        let resolved = Single<String>.create { observer in
            let task = Task {
                do {
                    if let unifiedAddress = try await resolver.resolve(name: name) {
                        observer(.success(unifiedAddress))
                    } else {
                        observer(.error(invalidAddress))
                    }
                } catch {
                    observer(.error(invalidAddress))
                }
            }

            return Disposables.create { task.cancel() }
        }

        // only a failed lookup reads as an invalid address; the regular parser's own errors (network, swap filter) pass through
        return resolved.flatMap { unifiedAddress in
            rawAddressParserItem.handle(address: unifiedAddress).map { parsed in
                Address(raw: parsed.raw, domain: "\(name)\(suffix)", blockchainType: parsed.blockchainType)
            }
        }
    }

    func isValid(address: String) -> Single<Bool> {
        .just(Self.normalize(address) != nil)
    }
}
