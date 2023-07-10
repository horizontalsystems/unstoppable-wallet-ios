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

    private func sign(message: Data, isLegacy: Bool = false) throws -> Data {
        try signer.signed(message: message, isLegacy: isLegacy)
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
            do {
                let eip712TypedData = try EIP712TypedData.parseFrom(rawJson: data)
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(eip712TypedData.sanitizedMessage)

                return String(decoding: data, as: UTF8.self)
            } catch {
                return ""
            }
        }
    }

    var domain: String? {
        switch request.payload {
        case .signTypeData(_, let data, _):
            if let eip712TypedData = try? EIP712TypedData.parseFrom(rawJson: data), let domain = eip712TypedData.domain.objectValue, let domainString = domain["name"]?.stringValue {
                return domainString
            }
        default: ()
        }

        return nil
    }

    var dAppName: String? {
        request.dAppName
    }

    var chain: WalletConnectRequest.Chain {
        request.chain
    }

    func sign() throws {
        let signedMessage: Data

        switch request.payload {
        case let .sign(data, _):    // legacy sync use already prefixed data hashed by Kessak-256 with length 32 bytes
            let isLegacy = data.count == 32 && (String(data: data, encoding: .utf8) != nil)
            signedMessage = try sign(message: data, isLegacy: isLegacy)
        case let .personalSign(data, _):
            signedMessage = try sign(message: data)
        case let .signTypeData(_, data, _):
            let eip712TypedData = try EIP712TypedData.parseFrom(rawJson: data)
            signedMessage = try signer.sign(eip712TypedData: eip712TypedData)
        }

        signService.approveRequest(id: request.id, result: signedMessage)
    }

    func reject() {
        signService.rejectRequest(id: request.id)
    }

}
