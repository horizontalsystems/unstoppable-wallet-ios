import ReownWalletKit
import WalletConnectUtils

struct WCVerificationContext {
    let payload: WCRequestPayload
    let verifyContext: VerifyContext?
    let accountId: String
    let approvedAccounts: [WalletConnectUtils.Account]
}
