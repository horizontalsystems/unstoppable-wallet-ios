import Foundation
import SolanaKit

// A "message" that deserializes as a transaction or as its signable message would authorize it once signed
class WCSolanaSignMessageVerifier: IWCVerifier {
    func handles(_ context: WCVerificationContext) -> Bool {
        context.payload is WCSolanaSignMessagePayload
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        guard let message = context.payload.message else {
            return .pass
        }

        if (try? SolanaKit.Kit.requiredSigners(message: message)) != nil || (try? SolanaKit.Kit.requiredSigners(rawTransaction: message)) != nil {
            return .block(reason: .solanaMessageIsTransaction)
        }

        if String(data: message, encoding: .utf8) == nil {
            return .caution(reason: .solanaMessageUnreadable)
        }

        return .pass
    }
}
