import Foundation
import MarketKit
import NearKit
import RxSwift

// Android AddressHandlerNear + NearAddressValidator: a bare single-label name (`alice`) is a valid id
// but also a plausible word in any field, so it is not claimed. A named account has to exist, or the
// transfer fails on chain; an implicit (64-hex) one is created by the first transfer, so it is not
// asked about. Only a definite "no" refuses a name: a node that did not answer must not reject a
// well-formed id (the kit asks again before a NEAR transfer).
class NearAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .near

    private let rpcUrls: [URL]

    init(rpcUrls: [URL]) {
        self.rpcUrls = rpcUrls
    }

    func handle(address: String) -> Single<Address> {
        guard Self.isSupported(address: address) else {
            return Single.error(AccountIdError.invalid(address))
        }

        let resolved = Address(raw: address, blockchainType: blockchainType)

        guard !NearKit.Kit.isImplicit(accountId: address) else {
            return Single.just(resolved)
        }

        let rpcUrls = rpcUrls

        return Single.create { observer in
            let task = Task {
                let exists = try? await NearKit.Kit.doesAccountExist(accountId: address, rpcUrls: rpcUrls)

                if exists == false {
                    observer(.error(AddressService.AddressError.invalidAddress(blockchainName: "NEAR")))
                } else {
                    observer(.success(resolved))
                }
            }

            return Disposables.create { task.cancel() }
        }
    }

    func isValid(address: String) -> Single<Bool> {
        Single.just(Self.isSupported(address: address))
    }

    private static func isSupported(address: String) -> Bool {
        switch NearKit.Kit.accountIdKind(address) {
        case .nearImplicit, .ethImplicit: return true
        case .named: return address.contains(".")
        case .deterministic, .none: return false
        }
    }
}
