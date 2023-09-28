import Foundation
import RxSwift

class ZcashAddressParserItem {
    private let parserType: ParserType

    init(parserType: ParserType) {
        self.parserType = parserType
    }

    private func validate(address: String, checkSendToSelf: Bool) -> Single<Address> {
        do {
            switch parserType {
            case .adapter(let adapter):
                _ = try adapter.validate(address: address, checkSendToSelf: checkSendToSelf)
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

extension ZcashAddressParserItem: IAddressParserItem {

    func handle(address: String) -> Single<Address> {
        validate(address: address, checkSendToSelf: true)
    }

    func isValid(address: String) -> Single<Bool> {
        validate(address: address, checkSendToSelf: false)
                .map { _ in true }
    }

}

extension ZcashAddressParserItem {

    enum ParserType {
        case adapter(ISendZcashAdapter)
        case validator(ZcashAddressValidator)
    }

}
