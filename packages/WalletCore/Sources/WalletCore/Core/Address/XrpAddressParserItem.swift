import MarketKit
import RxSwift
import XrpKit

/// Recognizes classic `r...` addresses and X-addresses (`X...` mainnet, `T...` testnet). The
/// address is kept as pasted (Android `AddressHandlerXrp`); the send handler and the adapter
/// resolve an X-address into its classic form and tag when the payment is built.
class XrpAddressParserItem: IAddressParserItem {
    var blockchainType: MarketKit.BlockchainType = .xrp

    func handle(address: String) -> Single<Address> {
        do {
            try XrpKit.Kit.validate(address: address)
            return Single.just(Address(raw: address, blockchainType: blockchainType))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        Single.just(XrpKit.Kit.isValid(address: address))
    }
}
