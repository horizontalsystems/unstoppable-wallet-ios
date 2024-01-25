import EvmKit
import Foundation
import MarketKit

class BaseEvmMultiSwapProvider {
    static let defaultSlippage: Decimal = 1

    private let adapterManager = App.shared.adapterManager
    let evmBlockchainManager = App.shared.evmBlockchainManager
    let storage: MultiSwapSettingStorage

    init(storage: MultiSwapSettingStorage) {
        self.storage = storage
    }

    private func pendingAllowance(pendingTransactions: [TransactionRecord]) -> Decimal? {
        for transaction in pendingTransactions {
            if let approve = transaction as? ApproveTransactionRecord, let value = approve.value.decimalValue {
                return value
            }
        }

        return nil
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

        if let pendingAllowance = pendingAllowance(pendingTransactions: adapter.pendingTransactions) {
            return .pending(amount: CoinValue(kind: .token(token: token), value: pendingAllowance))
        }

        let chain = evmBlockchainManager.chain(blockchainType: token.blockchainType)

        do {
            let spenderAddress = try spenderAddress(chain: chain)
            let allowance = try await adapter.allowance(spenderAddress: spenderAddress, defaultBlockParameter: .latest)

            if amount <= allowance {
                return .allowed
            } else {
                return .notEnough(amount: CoinValue(kind: .token(token: token), value: allowance))
            }
        } catch {
            return .unknown
        }
    }
}

extension BaseEvmMultiSwapProvider {
    enum AllowanceState {
        case notRequired
        case pending(amount: CoinValue)
        case notEnough(amount: CoinValue)
        case allowed
        case unknown
    }
}

extension BaseEvmMultiSwapProvider {
    class Quote: IMultiSwapQuote {
        private let estimatedGas: Int?
        private let allowanceState: AllowanceState

        init(estimatedGas: Int?, allowanceState: AllowanceState) {
            self.estimatedGas = estimatedGas
            self.allowanceState = allowanceState
        }

        var amountOut: Decimal {
            0
        }

        var feeQuote: MultiSwapFeeQuote? {
            guard let estimatedGas else {
                return nil
            }

            return .evm(gasLimit: estimatedGas)
        }

        var mainFields: [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

            switch allowanceState {
            case let .notEnough(amount):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
                    fields.append(
                        MultiSwapMainField(
                            title: "Allowance",
                            value: "\(formatted)",
                            valueLevel: .regular
                        )
                    )
                }
            case let .pending(amount):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
                    fields.append(
                        MultiSwapMainField(
                            title: "Pending Allowance",
                            value: "\(formatted)",
                            valueLevel: .regular
                        )
                    )
                }
            default: ()
            }

            return fields
        }

        var confirmFieldSections: [[MultiSwapConfirmField]] {
            []
        }

        var settingsModified: Bool {
            false
        }

        var canSwap: Bool {
            switch allowanceState {
            case .notRequired, .allowed: return true
            default: return false
            }
        }
    }
}
