import Foundation
import MarketKit
import RxSwift

class ZcashAddressParserItem {
    private let parserType: ParserType

    init(parserType: ParserType) {
        self.parserType = parserType
    }

    private func validate(address: String, checkSendToSelf: Bool) -> Single<Address> {
        do {
            switch parserType {
            case let .adapter(adapter):
                _ = try adapter.validate(address: address, checkSendToSelf: checkSendToSelf)
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

extension ZcashAddressParserItem: IAddressParserItem {
    var blockchainType: BlockchainType { .zcash }

    func handle(address: String) -> Single<Address> {
        validate(address: address, checkSendToSelf: true)
    }

    func isValid(address: String) -> Single<Bool> {
        validate(address: address, checkSendToSelf: false)
            .map { _ in true }
            .catchErrorJustReturn(false)
    }
}

extension ZcashAddressParserItem {
    enum ParserType {
        case adapter(ISendZcashAdapter)
        case validator(ZcashAddressValidator)
    }
}
