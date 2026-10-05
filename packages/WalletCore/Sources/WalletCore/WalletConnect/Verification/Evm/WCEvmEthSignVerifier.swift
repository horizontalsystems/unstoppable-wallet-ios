import Foundation
import WalletConnectUtils

class WCEvmEthSignVerifier: IWCVerifier {
    func handles(_ context: WCVerificationContext) -> Bool {
        context.payload.chainId.namespace == WCNamespace.eip155 && context.payload.method == "eth_sign"
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        guard let message = context.payload.message else {
            return .pass
        }

        if message.count == 32 {
            return .block(reason: .ethSignBlindHash)
        }

        if String(data: message, encoding: .utf8) == nil {
            return .caution(reason: .ethSignUnreadable)
        }

        return .pass
    }
}
