import Foundation
import WalletConnectUtils

class WCNEvmEthSignVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        context.payload.chainId.namespace == WCNNamespace.eip155 && context.payload.method == "eth_sign"
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
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
