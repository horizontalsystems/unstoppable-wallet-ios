import Foundation
import RxSwift

class BinanceAddressParserItem {
    private let adapter: ISendBinanceAdapter

    init(adapter: ISendBinanceAdapter) {
        self.adapter = adapter
    }

}

extension BinanceAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        do {
            try adapter.validate(address: address)
            return Single.just(Address(raw: address, domain: nil))
        } catch {
            return Single.error(AddressService.AddressError.invalidAddress)
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
