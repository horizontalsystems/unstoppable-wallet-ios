import Foundation
import RxSwift

class BitcoinAddressParserItem {
    private let adapter: ISendBitcoinAdapter
    var pluginData = [UInt8: IBitcoinPluginData]()

    init(adapter: ISendBitcoinAdapter) {
        self.adapter = adapter
    }

}

extension BitcoinAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        do {
            try adapter.validate(address: address, pluginData: pluginData)
            return Single.just(Address(raw: address, domain: nil))
        } catch {
            return Single.error(AddressService.AddressError.invalidAddress)
        }
    }

    func isValid(address: String) -> Single<Bool> {
        do {
            try adapter.validate(address: address, pluginData: pluginData)
            return Single.just(true)
        } catch {
            return Single.just(false)
        }
    }

}
