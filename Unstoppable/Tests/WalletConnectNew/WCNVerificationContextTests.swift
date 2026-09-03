import ReownWalletKit
import Testing
import WalletConnectUtils
@testable import WalletCore

struct WCNVerificationContextTests {
    @Test func contextWithoutVerifyContextIsAllowed() throws {
        let context = try WCNTestFixtures.context(verifyContext: nil)
        #expect(context.verifyContext == nil)
        #expect(context.approvedAccounts.isEmpty)
    }

    @Test func contextKeepsOriginAndApprovedAccounts() throws {
        let account = WalletConnectUtils.Account("eip155:1:\(WCNTestFixtures.address)")!
        let verifyContext = VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid)

        let context = try WCNTestFixtures.context(verifyContext: verifyContext, approvedAccounts: [account])

        #expect(context.verifyContext?.origin == "https://react-app.walletconnect.com")
        #expect(context.verifyContext?.validation == .valid)
        #expect(context.approvedAccounts == [account])
        #expect(context.payload.from == WCNTestFixtures.address)
    }
}
