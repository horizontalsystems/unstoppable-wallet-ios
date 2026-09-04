import EvmKit
import Foundation
import WalletConnectSign

class WCNEvmSignMessageHandler: IWCNSignMessageHandler {
    private let signerProvider: IWCNEvmSignerProvider
    private let responder: WCNResponder

    init(signerProvider: IWCNEvmSignerProvider, responder: WCNResponder) {
        self.signerProvider = signerProvider
        self.responder = responder
    }

    func handles(_ payload: WCNRequestPayload) -> Bool {
        payload is WCNEvmSignMessagePayload
    }

    func sign(request: WCNRequest) async throws {
        guard let payload = request.payload as? WCNEvmSignMessagePayload, let message = payload.message else {
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
            let isLegacy = payload.method == WCNEvmSignMessagePayload.ethSignMethod && message.count == 32
            signature = try signer.signed(message: message, isLegacy: isLegacy)
        }

        try await responder.respond(request: payload, result: AnyCodable(signature.hs.hexString))
    }
}

extension WCNEvmSignMessageHandler {
    enum SignError: Error {
        case invalidPayload
        case noSigner
    }
}
