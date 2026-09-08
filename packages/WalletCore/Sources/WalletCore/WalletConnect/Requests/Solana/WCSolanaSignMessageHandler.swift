import HsCryptoKit
import SolanaKit
import WalletConnectSign

class WCSolanaSignMessageHandler: IWCSignMessageHandler {
    private let signerProvider: IWCSolanaSignerProvider
    private let responder: WCResponder

    init(signerProvider: IWCSolanaSignerProvider, responder: WCResponder) {
        self.signerProvider = signerProvider
        self.responder = responder
    }

    func handles(_ payload: WCRequestPayload) -> Bool {
        payload is WCSolanaSignMessagePayload
    }

    func sign(request: WCRequest) async throws {
        guard !request.isBlocked else { throw SignError.blocked }
        guard let payload = request.payload as? WCSolanaSignMessagePayload, let message = payload.message else {
            throw SignError.invalidPayload
        }
        guard let signer = signerProvider.signer else {
            throw SignError.noSigner
        }

        let signature = try signer.sign(data: message)
        try await responder.respond(request: payload, result: AnyCodable(any: ["signature": HsCryptoKit.Base58.encode(signature)]))
    }
}

extension WCSolanaSignMessageHandler {
    enum SignError: Error {
        case blocked
        case invalidPayload
        case noSigner
    }
}
