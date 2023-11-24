import MarketKit
import RxSwift

class TonAddressParserItem: IAddressParserItem {
    private let adapter: ISendTonAdapter

    init(adapter: ISendTonAdapter) {
        self.adapter = adapter
    }

    var blockchainType: BlockchainType { .ton }

    func handle(address: String) -> Single<Address> {
        do {
            try adapter.validate(address: address)
            return Single.just(Address(raw: address))
        } catch {
            return Single.error(error)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            try adapter.validate(address: address)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }
}
