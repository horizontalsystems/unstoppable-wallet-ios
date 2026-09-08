import EvmKit
import Foundation
import WalletConnectSign

class WCNEvmSignMessagePayload: WCNRequestPayload, IWCNTypedDataRequest {
    static let ethSignMethod = "eth_sign"
    static let personalSignMethod = "personal_sign"
    static let typedDataMethods = ["eth_signTypedData", "eth_signTypedData_v3", "eth_signTypedData_v4"]

    private let messageData: Data
    let typedData: EIP712TypedData?

    init(request: Request, address: EvmKit.Address, message: Data, typedData: EIP712TypedData?) {
        messageData = message
        self.typedData = typedData
        super.init(request: request, kind: .signMessage, from: address.eip55)
    }

    override var message: Data? { messageData }

    var typedDataDomain: WCNTypedDataDomain? {
        guard let domain = typedData?.domain.objectValue else {
            return nil
        }
        return WCNTypedDataDomain(chainId: Self.chainId(json: domain["chainId"]), verifyingContract: domain["verifyingContract"]?.stringValue)
    }

    // what the user is asked to sign, rendered for the confirmation screen
    var readableMessage: String {
        if let typedData {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return (try? encoder.encode(typedData.sanitizedMessage)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }
        return String(data: messageData, encoding: .utf8) ?? messageData.hs.hexString
    }

    private static func chainId(json: JSON?) -> Int? {
        if let number = json?.doubleValue {
            return Int(exactly: number)
        }
        guard let string = json?.stringValue else {
            return nil
        }
        return string.hasPrefix("0x") ? Int(string.dropFirst(2), radix: 16) : Int(string)
    }
}
