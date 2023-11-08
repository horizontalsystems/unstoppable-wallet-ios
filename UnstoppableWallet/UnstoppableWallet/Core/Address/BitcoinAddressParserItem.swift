import BitcoinCore
import Foundation
import MarketKit
import RxRelay
import RxSwift

class BitcoinAddressParserItem {
    let blockchainType: BlockchainType
    private let parserType: ParserType

    init(blockchainType: BlockchainType, parserType: ParserType) {
        self.blockchainType = blockchainType
        self.parserType = parserType
    }

    private func validate(address: String) -> Single<Address> {
        // avoid plugin data to validate all addresses
        do {
            switch parserType {
            case let .adapter(adapter):
                try adapter.validate(address: address, pluginData: [:]) // validate
                return Single.just(Address(raw: address, domain: nil))
            case let .converter(converter):
                let _ = try converter.convert(address: address)
                return Single.just(Address(raw: address, domain: nil))
            }
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

extension BitcoinAddressParserItem {
    enum ParserType {
        case adapter(ISendBitcoinAdapter)
        case converter(IAddressConverter)
    }
}
