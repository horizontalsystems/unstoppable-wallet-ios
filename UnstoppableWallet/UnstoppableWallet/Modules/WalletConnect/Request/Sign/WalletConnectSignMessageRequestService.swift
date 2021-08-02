import EthereumKit

class WalletConnectSignMessageRequestService {
    private let request: WalletConnectSignMessageRequest
    private let baseService: WalletConnectService
    private let evmKit: EthereumKit.Kit

    init(request: WalletConnectSignMessageRequest, baseService: WalletConnectService, evmKit: EthereumKit.Kit) {
        self.request = request
        self.baseService = baseService
        self.evmKit = evmKit
    }

    private func sign(message: Data) throws -> Data {
        try evmKit.signed(message: message)
    }

    private func signTypedData(message: Data) throws -> Data {
        try evmKit.signTypedData(message: message)
    }

}

extension WalletConnectSignMessageRequestService {

    var message: String {
        switch request.payload {
        case let .sign(data, _):
            return String(decoding: data, as: UTF8.self)
        case let .personalSign(data, _):
            return String(decoding: data, as: UTF8.self)
        case let .signTypeData(_, data, _):
            guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let prettyData = try? JSONSerialization.data(withJSONObject: object, options: .prettyPrinted) else {
                return ""
            }

            return String(decoding: prettyData, as: UTF8.self)
        }
    }

    var domain: String? {
        if case let .signTypeData(_, data, _) = request.payload {
            let typeData = try? evmKit.parseTypedData(rawJson: data)
            if case let .object(json) = typeData?.domain, let domainJson = json["name"], case let .string(domainString) = domainJson {
                return domainString
            }
        }

        return nil
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

        baseService.approveRequest(id: request.id, result: signedMessage)
    }

    func reject() {
        baseService.rejectRequest(id: request.id)
    }

}
