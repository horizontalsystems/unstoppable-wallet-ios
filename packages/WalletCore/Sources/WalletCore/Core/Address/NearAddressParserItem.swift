import MarketKit
import NearKit
import RxSwift

// Android AddressHandlerNear: a bare single-label name (`alice`) is a valid id but also a plausible word in any field, so it is not claimed
class NearAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .near

    func handle(address: String) -> Single<Address> {
        guard Self.isSupported(address: address) else {
            return Single.error(AccountIdError.invalid(address))
        }

        return Single.just(Address(raw: address, blockchainType: blockchainType))
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
