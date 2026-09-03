import Foundation
import WalletConnectUtils

class WCNEvmEthSignVerifier: IWCNVerifier {
    func handles(_ context: WCNVerificationContext) -> Bool {
        context.parsed.chainId.namespace == WCNNamespace.eip155 && context.parsed.method == "eth_sign"
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        guard let message = context.parsed.message else {
            return .pass
        }

        if message.count == 32 {
            return .block(reason: "eth_sign over a raw 32-byte hash is blind signing")
        }

        if String(data: message, encoding: .utf8) == nil {
            return .caution(reason: "eth_sign message is not readable text")
        }

        return .pass
    }
}
