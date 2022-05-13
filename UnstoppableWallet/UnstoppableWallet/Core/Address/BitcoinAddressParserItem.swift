import Foundation
import RxSwift
import RxRelay

class BitcoinAddressParserItem {
    private let adapter: ISendBitcoinAdapter

    init(adapter: ISendBitcoinAdapter) {
        self.adapter = adapter
    }

    private func validate(address: String) -> Single<Address> {
        // avoid plugin data to validate all addresses
        do {
            try adapter.validate(address: address, pluginData: [:]) // validate
            return Single.just(Address(raw: address, domain: nil))
        } catch {
            return Single.error(error)
        }
    }

}

extension BitcoinAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        validate(address: address)
    }

    func isValid(address: String) -> Single<Bool> {
        validate(address: address)
                .map { _ in true }
                .catchErrorJustReturn(false)
    }

}
