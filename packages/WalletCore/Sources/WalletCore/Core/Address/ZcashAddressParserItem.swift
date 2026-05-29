import Foundation
import MarketKit
import RxSwift

class ZcashAddressParserItem {
    private let parserType: ParserType
    private let addressType: ZcashAdapter.AddressType?

    init(parserType: ParserType, addressType: ZcashAdapter.AddressType?) {
        self.parserType = parserType
        self.addressType = addressType
    }

    private func validate(address: String, checkSendToSelf: Bool) -> Single<Address> {
        do {
            switch parserType {
            case let .adapter(adapter):
                let parsedType = try adapter.validate(address: address, checkSendToSelf: checkSendToSelf)
                if let addressType, parsedType != addressType {
                    return Single.error(addressType == .transparent ? ParseError.onlyTransparent : ParseError.onlyShielded)
                }
                return Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
            case let .validator(validator):
                let recipient = try validator.validate(address: address)
                if let addressType {
                    switch addressType {
                    case .shielded:
                        if recipient.isTransparent {
                            return Single.error(ParseError.onlyShielded)
                        }
                    case .transparent:
                        if !recipient.isTransparent {
                            return Single.error(ParseError.onlyTransparent)
                        }
                    }
                }
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

    enum ParseError: Error {
        case onlyTransparent
        case onlyShielded
    }
}
