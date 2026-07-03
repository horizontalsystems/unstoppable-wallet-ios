import Foundation
import MarketKit

public enum AllowancePolicyState: Equatable {
    case notRequired
}

public protocol IAllowancePolicy {
    static func allowanceState(spenderAddress: Address, token: Token, amount: Decimal) async -> AllowancePolicyState?
}

// registry of externally-supplied allowance policies; first non-nil verdict wins,
// otherwise MultiSwapAllowanceHelper falls through to its own on-chain check
public enum AllowancePolicy {
    private static var policies: [IAllowancePolicy.Type] = []

    public static func prepend(_ policy: IAllowancePolicy.Type) {
        policies.insert(policy, at: 0)
    }

    static func state(spenderAddress: Address, token: Token, amount: Decimal) async -> AllowancePolicyState? {
        for policy in policies {
            if let state = await policy.allowanceState(spenderAddress: spenderAddress, token: token, amount: amount) {
                return state
            }
        }

        return nil
    }

    // test seam: registry is global mutable state
    static func reset() {
        policies = []
    }
}
