import Foundation
import RxSwift

class ZcashAddressParserItem {
    private let adapter: ISendZcashAdapter

    init(adapter: ISendZcashAdapter) {
        self.adapter = adapter
    }

    func validate(address: String) throws -> ZcashAdapter.AddressType {
        try adapter.validate(address: address)
    }

}

extension ZcashAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        do {
            _ = try validate(address: address)
            return Single.just(Address(raw: address, domain: nil))
        } catch {
            return Single.error(AddressService.AddressError.invalidAddress)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            _ = try adapter.validate(address: address)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }

}
