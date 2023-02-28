import Foundation
import RxSwift
import BitcoinCore
import BinanceChainKit

class BinanceAddressParserItem {
    private let parserType: ParserType

    init(parserType: ParserType) {
        self.parserType = parserType
    }

    private func validate(address: String) -> Single<Address> {
        do {
            switch parserType {
            case .adapter(let adapter):
                try adapter.validate(address: address)
                return Single.just(Address(raw: address, domain: nil))
            case .validator(let validator):
                try validator.validate(address: address)
                return Single.just(Address(raw: address, domain: nil))
            }

        } catch {
            return Single.error(error)
        }
    }

}

extension BinanceAddressParserItem: IAddressParserItem {

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
