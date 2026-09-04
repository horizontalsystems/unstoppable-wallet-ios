import SolanaKit

// A "message" that deserializes as a transaction would authorize it once signed
class WCNSolanaSignMessageVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        context.payload is WCNSolanaSignMessagePayload
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let message = context.payload.message, (try? SolanaKit.Kit.requiredSigners(rawTransaction: message)) != nil else {
            return .pass
        }
        return .block(reason: .solanaMessageIsTransaction)
    }
}
