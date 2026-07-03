import Foundation
import MarketKit
import Testing
@testable import Unstoppable
@testable import WalletCore

@Suite(.serialized)
struct AllowancePolicyTests {
    private static let token = Token(
        coin: Coin(uid: "test-coin", name: "Test", code: "TST"),
        blockchain: Blockchain(type: .ethereum, name: "Test", explorerUrl: nil),
        type: .native,
        decimals: 8
    )

    init() {
        AllowancePolicy.reset()
    }

    @Test func emptyRegistryReturnsNil() async {
        let state = await AllowancePolicy.state(spenderAddress: Address(raw: "spender"), token: Self.token, amount: 1)

        #expect(state == nil)
    }

    @Test func prependedPolicyWins() async {
        AllowancePolicy.prepend(NotRequiredPolicy.self)

        let state = await AllowancePolicy.state(spenderAddress: Address(raw: "spender"), token: Self.token, amount: 1)

        #expect(state == .notRequired)
    }

    @Test func decliningPolicyFallsThrough() async {
        AllowancePolicy.prepend(DecliningPolicy.self)

        let state = await AllowancePolicy.state(spenderAddress: Address(raw: "spender"), token: Self.token, amount: 1)

        #expect(state == nil)
    }
}

private enum NotRequiredPolicy: IAllowancePolicy {
    static func allowanceState(spenderAddress _: Address, token _: Token, amount _: Decimal) async -> AllowancePolicyState? {
        .notRequired
    }
}

private enum DecliningPolicy: IAllowancePolicy {
    static func allowanceState(spenderAddress _: Address, token _: Token, amount _: Decimal) async -> AllowancePolicyState? {
        nil
    }
}
