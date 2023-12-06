import Foundation
import MarketKit
import RxSwift

class DashAddressParserItem {
    private let adapter: ISendDashAdapter

    init(adapter: ISendDashAdapter) {
        self.adapter = adapter
    }
}

extension DashAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { .dash }

    func handle(address: String) -> Single<Address> {
        do {
            try adapter.validate(address: address)
            return Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
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
