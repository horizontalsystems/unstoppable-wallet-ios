import EvmKit
import Foundation
import WalletConnectSign

class WCEvmSignMessageHandler: IWCSignMessageHandler {
    private let signerProvider: IWCEvmSignerProvider
    private let responder: WCResponder

    init(signerProvider: IWCEvmSignerProvider, responder: WCResponder) {
        self.signerProvider = signerProvider
        self.responder = responder
    }

    func handles(_ payload: WCRequestPayload) -> Bool {
        payload is WCEvmSignMessagePayload
    }

    func sign(request: WCRequest) async throws {
        guard !request.isBlocked else { throw SignError.blocked }
        guard let payload = request.payload as? WCEvmSignMessagePayload, let message = payload.message else {
            throw SignError.invalidPayload
        }
        guard let chainId = Int(payload.chainId.reference), let signer = signerProvider.signer(chainId: chainId) else {
            throw SignError.noSigner
        }

        let signature: Data
        if let typedData = payload.typedData {
            signature = try signer.sign(eip712TypedData: typedData)
        } else {
            // legacy eth_sign passes an already prefixed keccak hash: sign it as is
            let isLegacy = payload.method == WCEvmSignMessagePayload.ethSignMethod && message.count == 32
            signature = try signer.signed(message: message, isLegacy: isLegacy)
        }

        try await responder.respond(request: payload, result: AnyCodable(signature.hs.hexString))
    }
}

extension WCEvmSignMessageHandler {
    enum SignError: Error {
        case blocked
        case invalidPayload
        case noSigner
    }
}
