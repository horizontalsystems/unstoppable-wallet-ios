import BinanceChainKit
import BitcoinCore
import Foundation
import MarketKit
import RxSwift

class BinanceAddressParserItem {
    private let parserType: ParserType

    init(parserType: ParserType) {
        self.parserType = parserType
    }

    private func validate(address: String) -> Single<Address> {
        do {
            switch parserType {
            case let .adapter(adapter):
                try adapter.validate(address: address)
                return Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
            case let .validator(validator):
                try validator.validate(address: address)
                return Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
            }

        } catch {
            return Single.error(error)
        }
    }
}

extension BinanceAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { .binanceChain }

    func handle(address: String) -> Single<Address> {
        validate(address: address)
    }

    func isValid(address: String) -> Single<Bool> {
        validate(address: address)
            .map { _ in true }
            .catchErrorJustReturn(false)
    }
}

extension BinanceAddressParserItem {
    enum ParserType {
        case adapter(ISendBinanceAdapter)
        case validator(BinanceAddressValidator)
    }
}
