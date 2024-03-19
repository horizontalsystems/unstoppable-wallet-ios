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
                return Single.just(Address(raw: address, domain: nil, blockchainType: blockchainType))
            case let .converter(converter):
                let btcAddress = try converter.convert(address: address)
                guard let tokenType = tokenType(scriptType: btcAddress.scriptType) else {
                    throw ParseError.couldNotInfereDerivation
                }
                return Single.just(BitcoinAddress(raw: address, domain: nil, blockchainType: blockchainType, tokenType: tokenType))
            }
        } catch {
            return Single.error(error)
        }
    }

    private func tokenType(scriptType: ScriptType) -> TokenType? {
        switch blockchainType {
        case .dash:
            return .native

        case .bitcoinCash, .ecash:
            return .addressType(type: .type145)

        case .bitcoin, .litecoin:
            switch scriptType {
            case .p2pkh: return .derived(derivation: .bip44)
            case .p2sh, .p2wpkhSh: return .derived(derivation: .bip49)
            case .p2wsh, .p2wpkh: return .derived(derivation: .bip84)
            case .p2tr: return .derived(derivation: .bip86)
            default: return nil
            }
        default: return nil
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

    enum ParseError: Error {
        case couldNotInfereDerivation
    }
}
