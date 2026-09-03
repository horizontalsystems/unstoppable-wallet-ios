import ReownWalletKit
import WalletConnectUtils

struct WCNVerificationContext {
    let parsed: WCNParsedRequest
    let verifyContext: VerifyContext?
    let accountId: String
    let approvedAccounts: [WalletConnectUtils.Account]
}
