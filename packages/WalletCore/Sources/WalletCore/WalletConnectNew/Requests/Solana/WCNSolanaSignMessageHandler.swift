import HsCryptoKit
import SolanaKit
import WalletConnectSign

class WCNSolanaSignMessageHandler: IWCNSignMessageHandler {
    private let signerProvider: IWCNSolanaSignerProvider
    private let responder: WCNResponder

    init(signerProvider: IWCNSolanaSignerProvider, responder: WCNResponder) {
        self.signerProvider = signerProvider
        self.responder = responder
    }

    func handles(_ payload: WCNRequestPayload) -> Bool {
        payload is WCNSolanaSignMessagePayload
    }

    func sign(request: WCNRequest) async throws {
        guard let payload = request.payload as? WCNSolanaSignMessagePayload, let message = payload.message else {
            throw SignError.invalidPayload
        }
        guard let signer = signerProvider.signer else {
            throw SignError.noSigner
        }

        let signature = try signer.sign(data: message)
        try await responder.respond(request: payload, result: AnyCodable(any: ["signature": HsCryptoKit.Base58.encode(signature)]))
    }
}

extension WCNSolanaSignMessageHandler {
    enum SignError: Error {
        case invalidPayload
        case noSigner
    }
}
