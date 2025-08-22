import EvmKit
import Foundation
import MarketKit
import SwiftUI

class MultiSwapAllowanceHelper {
    private let adapterManager = Core.shared.adapterManager
    private let addressesForRevoke: [BlockchainType: String] = [
        .ethereum: "0xdac17f958d2ee523a2206206994597c13d831ec7",
        .tron: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
    ]

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        switch step {
        case let unlockStep as UnlockStep:
            if unlockStep.isRevoke {
                let view = MultiSwapRevokeView(tokenIn: tokenIn, spenderAddress: unlockStep.spenderAddress, isPresented: isPresented, onSuccess: onSuccess)
                return AnyView(ThemeNavigationStack { view })
            } else {
                let view = MultiSwapApproveView(tokenIn: tokenIn, amount: amount, spenderAddress: unlockStep.spenderAddress, isPresented: isPresented, onSuccess: onSuccess)
                return AnyView(ThemeNavigationStack { view })
            }
        default:
            return AnyView(Text("Invalid Pre Swap Step"))
        }
    }

    func allowanceState(spenderAddress: Address, token: Token, amount: Decimal) async -> AllowanceState {
        if token.type.isNative {
            return .notRequired
        }

        guard let adapter = adapterManager.adapter(for: token) as? IAllowanceAdapter else {
            return .unknown
        }

        do {
            if let pendingAllowance = pendingAllowance(pendingTransactions: adapter.pendingTransactions, spenderAddress: spenderAddress) {
                if pendingAllowance == 0 {
                    return .pendingRevoke
                } else {
                    return .pendingAllowance(appValue: AppValue(token: token, value: pendingAllowance))
                }
            }

            let allowance = try await adapter.allowance(spenderAddress: spenderAddress, defaultBlockParameter: .latest)
            if amount <= allowance {
                return .allowed
            } else {
                return .notEnough(
                    appValue: AppValue(token: token, value: allowance),
                    spenderAddress: spenderAddress,
                    revokeRequired: allowance > 0 && mustBeRevoked(token: token)
                )
            }
        } catch {
            return .unknown
        }
    }

    private func pendingAllowance(pendingTransactions: [TransactionRecord], spenderAddress: Address) -> Decimal? {
        for transaction in pendingTransactions {
            if let record = transaction as? IApproveTransaction, record.spender.lowercased() == spenderAddress.raw.lowercased() {
                return record.value.value
            }
        }

        return nil
    }

    private func mustBeRevoked(token: Token) -> Bool {
        for (blockchainType, addressToRevoke) in addressesForRevoke {
            if blockchainType == token.blockchainType, case let .eip20(address) = token.type, address.lowercased() == addressToRevoke.lowercased() {
                return true
            }
        }

        return false
    }
}

extension MultiSwapAllowanceHelper {
    enum AllowanceState {
        case notRequired
        case pendingAllowance(appValue: AppValue)
        case pendingRevoke
        case notEnough(appValue: AppValue, spenderAddress: Address, revokeRequired: Bool)
        case allowed
        case unknown

        var customButtonState: MultiSwapButtonState? {
            switch self {
            case let .notEnough(_, spenderAddress, revokeRequired): return .init(title: revokeRequired ? "swap.revoke".localized : "swap.approve".localized, preSwapStep: UnlockStep(spenderAddress: spenderAddress, isRevoke: revokeRequired))
            case .pendingAllowance: return .init(title: "swap.approving".localized, disabled: true, showProgress: true)
            case .pendingRevoke: return .init(title: "swap.revoking".localized, disabled: true, showProgress: true)
            case .unknown: return .init(title: "swap.allowance_error".localized, disabled: true)
            default: return nil
            }
        }

        func cautions() -> [CautionNew] {
            var cautions = [CautionNew]()

            switch self {
            case let .notEnough(appValue, _, revokeRequired):
                if revokeRequired {
                    cautions.append(.init(text: "swap.revoke_warning".localized(appValue.formattedShort() ?? ""), type: .warning))
                }
            default: ()
            }

            return cautions
        }

        func fields() -> [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

            switch self {
            case let .notEnough(appValue, _, _):
                if let formatted = appValue.formattedShort() {
                    fields.append(
                        MultiSwapMainField(
                            title: "swap.allowance".localized,
                            infoDescription: .init(title: "swap.allowance".localized, description: "swap.allowance.description".localized),
                            value: "\(formatted)",
                            valueLevel: .error
                        )
                    )
                }
            case let .pendingAllowance(appValue):
                if let formatted = appValue.formattedShort() {
                    fields.append(
                        MultiSwapMainField(
                            title: "swap.pending_allowance".localized,
                            value: "\(formatted)",
                            valueLevel: .warning
                        )
                    )
                }
            default: ()
            }

            return fields
        }
    }

    class UnlockStep: MultiSwapPreSwapStep {
        let spenderAddress: Address
        let isRevoke: Bool

        init(spenderAddress: Address, isRevoke: Bool) {
            self.spenderAddress = spenderAddress
            self.isRevoke = isRevoke
        }

        override var id: String {
            "eip20_unlock"
        }
    }
}
