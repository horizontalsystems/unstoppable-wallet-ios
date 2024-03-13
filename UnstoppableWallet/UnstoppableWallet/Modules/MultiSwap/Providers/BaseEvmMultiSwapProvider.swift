import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private let adapterManager = App.shared.adapterManager
    let evmBlockchainManager = App.shared.evmBlockchainManager
    let storage: MultiSwapSettingStorage

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    var id: String {
        fatalError("Must be implemented in subclass")
    }

    var name: String {
        fatalError("Must be implemented in subclass")
    }

    var icon: String {
        fatalError("Must be implemented in subclass")
    }

    func supports(tokenIn _: Token, tokenOut _: Token) -> Bool {
        fatalError("Must be implemented in subclass")
    }

    func quote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal) async throws -> IMultiSwapQuote {
        fatalError("Must be implemented in subclass")
    }

    func confirmationQuote(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, transactionSettings _: TransactionSettings?) async throws -> IMultiSwapConfirmationQuote {
        fatalError("Must be implemented in subclass")
    }

    func settingsView(tokenIn _: Token, tokenOut _: Token, onChangeSettings _: @escaping () -> Void) -> AnyView {
        fatalError("settingsView(tokenIn:tokenOut:onChangeSettings:) has not been implemented")
    }

    func settingView(settingId _: String) -> AnyView {
        fatalError("settingView(settingId:) has not been implemented")
    }

    func preSwapView(step: MultiSwapPreSwapStep, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView {
        switch step {
        case let unlockStep as UnlockStep:
            if unlockStep.isRevoke {
                let view = MultiSwapRevokeView(tokenIn: tokenIn, spenderAddress: unlockStep.spenderAddress, isPresented: isPresented, onSuccess: onSuccess)
                return AnyView(ThemeNavigationView { view })
            } else {
                let view = MultiSwapApproveView(tokenIn: tokenIn, amount: amount, spenderAddress: unlockStep.spenderAddress, isPresented: isPresented, onSuccess: onSuccess)
                return AnyView(ThemeNavigationView { view })
            }
        default:
            return AnyView(Text("Invalid Pre Swap Step"))
        }
    }

    func swap(tokenIn _: Token, tokenOut _: Token, amountIn _: Decimal, quote _: IMultiSwapConfirmationQuote) async throws {
        fatalError("Must be implemented in subclass")
    }

    func spenderAddress(chain _: Chain) throws -> EvmKit.Address {
        fatalError("Must be implemented in subclass")
    }

    func allowanceState(token: Token, amount: Decimal) async -> AllowanceState {
        if token.type.isNative {
            return .notRequired
        }

        guard let adapter = adapterManager.adapter(for: token) as? IErc20Adapter else {
            return .unknown
        }

        do {
            let chain = evmBlockchainManager.chain(blockchainType: token.blockchainType)
            let spenderAddress = try spenderAddress(chain: chain)

            if let pendingAllowance = pendingAllowance(pendingTransactions: adapter.pendingTransactions, spenderAddress: spenderAddress) {
                if pendingAllowance == 0 {
                    return .pendingRevoke
                } else {
                    return .pendingAllowance(amount: CoinValue(kind: .token(token: token), value: pendingAllowance))
                }
            }

            let allowance = try await adapter.allowance(spenderAddress: spenderAddress, defaultBlockParameter: .latest)

            if amount <= allowance {
                return .allowed
            } else {
                return .notEnough(
                    amount: CoinValue(kind: .token(token: token), value: allowance),
                    spenderAddress: spenderAddress,
                    revokeRequired: allowance > 0 && mustBeRevoked(token: token)
                )
            }
        } catch {
            return .unknown
        }
    }

    private func pendingAllowance(pendingTransactions: [TransactionRecord], spenderAddress: EvmKit.Address) -> Decimal? {
        for transaction in pendingTransactions {
            if let record = transaction as? ApproveTransactionRecord, record.spender == spenderAddress.eip55, let value = record.value.decimalValue {
                return value
            }
        }

        return nil
    }

    private func mustBeRevoked(token: Token) -> Bool {
        let addressesForRevoke = ["0xdac17f958d2ee523a2206206994597c13d831ec7"]

        if case .ethereum = token.blockchainType, case let .eip20(address) = token.type, addressesForRevoke.contains(address.lowercased()) {
            return true
        }

        return false
    }
}

extension BaseEvmMultiSwapProvider {
    enum AllowanceState {
        case notRequired
        case pendingAllowance(amount: CoinValue)
        case pendingRevoke
        case notEnough(amount: CoinValue, spenderAddress: EvmKit.Address, revokeRequired: Bool)
        case allowed
        case unknown
    }

    class UnlockStep: MultiSwapPreSwapStep {
        let spenderAddress: EvmKit.Address
        let isRevoke: Bool

        init(spenderAddress: EvmKit.Address, isRevoke: Bool) {
            self.spenderAddress = spenderAddress
            self.isRevoke = isRevoke
        }

        override var id: String {
            "evm_unlock"
        }
    }
}

extension BaseEvmMultiSwapProvider {
    class Quote: IMultiSwapQuote {
        let allowanceState: AllowanceState

        init(allowanceState: AllowanceState) {
            self.allowanceState = allowanceState
        }

        var amountOut: Decimal {
            fatalError("Must be implemented in subclass")
        }

        var customButtonState: MultiSwapButtonState? {
            switch allowanceState {
            case let .notEnough(_, spenderAddress, revokeRequired): return .init(title: revokeRequired ? "swap.revoke".localized : "swap.unlock".localized, preSwapStep: UnlockStep(spenderAddress: spenderAddress, isRevoke: revokeRequired))
            case .pendingAllowance: return .init(title: "swap.unlocking".localized, disabled: true, showProgress: true)
            case .pendingRevoke: return .init(title: "swap.revoking".localized, disabled: true, showProgress: true)
            case .unknown: return .init(title: "swap.allowance_error".localized, disabled: true)
            default: return nil
            }
        }

        var settingsModified: Bool {
            false
        }

        func cautions() -> [CautionNew] {
            var cautions = [CautionNew]()

            switch allowanceState {
            case let .notEnough(amount, _, revokeRequired):
                if revokeRequired {
                    cautions.append(.init(text: "swap.revoke_warning".localized(ValueFormatter.instance.formatShort(coinValue: amount) ?? ""), type: .warning))
                }
            default: ()
            }

            return cautions
        }

        func fields(tokenIn _: Token, tokenOut _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

            switch allowanceState {
            case let .notEnough(amount, _, _):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
                    fields.append(
                        MultiSwapMainField(
                            title: "swap.allowance".localized,
                            description: .init(title: "swap.allowance".localized, description: "swap.allowance.description".localized),
                            value: "\(formatted)",
                            valueLevel: .error
                        )
                    )
                }
            case let .pendingAllowance(amount):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
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

    class ConfirmationQuote: BaseSendEvmData, IMultiSwapConfirmationQuote {
        var amountOut: Decimal {
            fatalError("Must be implemented in subclass")
        }

        var feeData: FeeData? {
            evmFeeData.map { .evm(evmFeeData: $0) }
        }

        var canSwap: Bool {
            gasPrice != nil && evmFeeData != nil
        }

        func cautions(feeToken _: Token?) -> [CautionNew] {
            []
        }

        func priceSectionFields(tokenIn _: Token, tokenOut _: Token, feeToken _: Token?, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [SendConfirmField] {
            []
        }

        func otherSections(tokenIn _: Token, tokenOut _: Token, feeToken: Token?, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate: Decimal?) -> [[SendConfirmField]] {
            var sections = [[SendConfirmField]]()

            if let nonce {
                sections.append(
                    [
                        .levelValue(title: "send.confirmation.nonce".localized, value: String(nonce), level: .regular),
                    ]
                )
            }

            if let feeToken {
                sections.append(feeSection(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate))
            }

            return sections
        }
    }
}
