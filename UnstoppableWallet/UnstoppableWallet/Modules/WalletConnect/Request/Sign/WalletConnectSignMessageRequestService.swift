import EthereumKit

class WalletConnectSignMessageRequestService {
    private let request: WalletConnectSignMessageRequest
    private let baseService: WalletConnectService

    init(request: WalletConnectSignMessageRequest, baseService: WalletConnectService) {
        self.request = request
        self.baseService = baseService
    }

    private func sign(message: Data) throws -> Data? {
        try baseService.evmKit?.signed(message: message)
    }

    private func signTypedData(message: Data) throws -> Data? {
        try baseService.evmKit?.signTypedData(message: message)
    }

    private var evmKit: EthereumKit.Kit? {
        baseService.evmKit
    }

}

extension WalletConnectSignMessageRequestService {

    var message: String {
        switch request.message {
        case let .sign(data, raw):
            return String(decoding: data, as:UTF8.self)
        case let .personalSign(data, raw):
            return String(decoding: data, as:UTF8.self)
        case let .signTypeData(_, data, raw):
            guard let object = try? JSONSerialization.jsonObject(with: data, options: []),
            let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: .utf8) else {
                return ""
            }

            return prettyPrintedString
        }
    }

    var domain: String? {
        if case let .signTypeData(_, data, raw) = request.message {
            let typeData = try? evmKit?.parseTypedData(rawJson: data)
            var domain: String?
            if case let .object(json) = typeData?.domain, let domainJson = json["name"], case let .string(domainString) = domainJson {
                return domainString
            }
        }

        return nil
    }

    func sign() throws {
        let signedMessage: Data?

        switch request.message {
        case let .sign(data, raw):
            signedMessage = try sign(message: data)
        case let .personalSign(data, raw):
            signedMessage = try sign(message: data)
        case let .signTypeData(_, data, raw):
            signedMessage = try signTypedData(message: data)
        }

        baseService.approveRequest(id: request.id, result: signedMessage ?? Data())
    }

    func reject() {
        baseService.rejectRequest(id: request.id)
    }

}
