import Foundation
import EvmKit

class WalletConnectSignMessageRequestService {
    private let request: WalletConnectSignMessageRequest
    private let signService: IWalletConnectSignService
    private let signer: Signer

    init(request: WalletConnectSignMessageRequest, signService: IWalletConnectSignService, signer: Signer) {
        self.request = request
        self.signService = signService
        self.signer = signer
    }

    private func sign(message: Data) throws -> Data {
        try signer.signed(message: message)
    }

    private func signTypedData(message: Data) throws -> Data {
        try signer.signTypedData(message: message)
    }

}

extension WalletConnectSignMessageRequestService {

    var message: String {
        switch request.payload {
        case let .sign(data, _):
            return String(data: data, encoding: .utf8) ?? data.hs.hexString
        case let .personalSign(data, _):
            return String(data: data, encoding: .utf8) ?? data.hs.hexString
        case let .signTypeData(_, data, _):
            guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let message = object["message"],
                  let prettyData = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
                return ""
            }

            return String(decoding: prettyData, as: UTF8.self)
        }
    }

    var domain: String? {
        if case let .signTypeData(_, data, _) = request.payload {
            let typedData = try? signer.parseTypedData(rawJson: data)
            if let domain = typedData?.domain.objectValue, let domainString = domain["name"]?.stringValue {
                return domainString
            }
        }

        return nil
    }

    var dAppName: String? {
        request.dAppName
    }

    func sign() throws {
        let signedMessage: Data

        switch request.payload {
        case let .sign(data, _):
            signedMessage = try sign(message: data)
        case let .personalSign(data, _):
            signedMessage = try sign(message: data)
        case let .signTypeData(_, data, _):
            signedMessage = try signTypedData(message: data)
        }

        signService.approveRequest(id: request.id, result: signedMessage)
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }

}
