import EvmKit
import Foundation
import WalletConnectSign

class WCNEvmSignMessageParser: IWCNParser {
    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.chainId.namespace == WCNNamespace.eip155 else {
            return nil
        }

        switch request.method {
        case WCNEvmSignMessagePayload.ethSignMethod, WCNEvmSignMessagePayload.personalSignMethod:
            let (address, message) = try Self.addressAndMessage(params: request.params)
            return WCNEvmSignMessagePayload(request: request, address: address, message: message, typedData: nil)

        case let method where WCNEvmSignMessagePayload.typedDataMethods.contains(method):
            let (address, json) = try Self.addressAndTypedData(params: request.params)
            guard let typedData = try? EIP712TypedData.parseFrom(rawJson: json) else {
                throw ParsingError.malformedParams
            }
            return WCNEvmSignMessagePayload(request: request, address: address, message: json, typedData: typedData)

        default:
            return nil
        }
    }

    // eth_sign is [address, message], personal_sign is [message, address]; dApps mix them up, so
    // the address is whichever element parses as one
    private static func addressAndMessage(params: AnyCodable) throws -> (EvmKit.Address, Data) {
        guard let strings = try? params.get([String].self), strings.count >= 2 else {
            throw ParsingError.malformedParams
        }

        if let address = try? EvmKit.Address(hex: strings[1]) {
            return (address, message(string: strings[0]))
        }
        if let address = try? EvmKit.Address(hex: strings[0]) {
            return (address, message(string: strings[1]))
        }
        throw ParsingError.missingAddress
    }

    private static func addressAndTypedData(params: AnyCodable) throws -> (EvmKit.Address, Data) {
        guard let items = try? params.get([AnyCodable].self), items.count >= 2,
              let addressString = try? items[0].get(String.self),
              let address = try? EvmKit.Address(hex: addressString)
        else {
            throw ParsingError.missingAddress
        }

        if let json = try? items[1].get(String.self) {
            return (address, Data(json.utf8))
        }
        return (address, try JSONEncoder().encode(items[1]))
    }

    private static func message(string: String) -> Data {
        string.hs.hexData ?? Data(string.utf8)
    }
}

extension WCNEvmSignMessageParser {
    enum ParsingError: Error, Equatable {
        case malformedParams
        case missingAddress
    }
}
