import ReownWalletKit
import WalletConnectUtils

struct WCNVerificationContext {
    let payload: WCNRequestPayload
    let verifyContext: VerifyContext?
    let accountId: String
    let approvedAccounts: [WalletConnectUtils.Account]
}
