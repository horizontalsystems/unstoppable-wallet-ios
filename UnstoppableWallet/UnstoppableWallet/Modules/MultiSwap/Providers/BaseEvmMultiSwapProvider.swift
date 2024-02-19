import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider {
    private static let unlockStepId = "unlock"

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

    func preSwapView(stepId: Binding<String?>, tokenIn: Token, tokenOut _: Token, amount: Decimal) -> AnyView {
        if stepId.wrappedValue == Self.unlockStepId {
            let amount = tokenIn.fractionalMonetaryValue(value: amount)
            let chain = evmBlockchainManager.chain(blockchainType: tokenIn.blockchainType)
            do {
                let spenderAddress = try spenderAddress(chain: chain)

                let approvePresented = Binding<Bool>(get: {
                    stepId.wrappedValue == Self.unlockStepId
                }, set: { newValue in
                    if !newValue { stepId.wrappedValue = nil } else {}
                })

                let viewModel = MultiSwapApproveViewModel(token: tokenIn, amount: amount, spenderAddress: spenderAddress, presented: approvePresented)
                return AnyView(ThemeNavigationView { MultiSwapApproveView(viewModel: viewModel) })
            } catch {
                return AnyView(Text("Can't Create Evm Allowance View"))
            }
        }
        return AnyView(Text("Evm Allowance View"))
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
        let gasPrice: GasPrice?
        let gasLimit: Int?
        let nonce: Int?
        let allowanceState: AllowanceState

        init(gasPrice: GasPrice?, gasLimit: Int?, nonce: Int?, allowanceState: AllowanceState) {
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.nonce = nonce
            self.allowanceState = allowanceState
        }

        var amountOut: Decimal {
            fatalError("Must be implemented in subclass")
        }

        var customButtonState: MultiSwapButtonState? {
            switch allowanceState {
            case .notEnough: return .init(title: "Unlock", preSwapStepId: BaseEvmMultiSwapProvider.unlockStepId)
            case .pending: return .init(title: "Unlocking...", disabled: true, showProgress: true)
            case .unknown: return .init(title: "Allowance Error", disabled: true)
            default: return nil
            }
        }

        var settingsModified: Bool {
            false
        }

        func cautions(feeToken: Token?) -> [CautionNew] {
            []
        }

        func feeData(feeToken: Token?, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let gasPrice, let gasLimit, let feeToken else {
                return nil
            }

            let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)
            let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

            return AmountData(coinValue: coinValue, currencyValue: currencyValue)
        }

        func mainFields(tokenIn _: Token, tokenOut _: Token, feeToken: Token?, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate: Decimal?) -> [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

            let feeData = feeData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

            fields.append(
                MultiSwapMainField(
                    title: "Network Fee",
                    description: .init(title: "Network Fee", description: "Network Fee Description"),
                    value: feeData?.formattedShort ?? "n/a".localized,
                    valueLevel: feeData != nil ? .regular : .notAvailable
                )
            )

            switch allowanceState {
            case let .notEnough(amount):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
                    fields.append(
                        MultiSwapMainField(
                            title: "Allowance",
                            value: "\(formatted)",
                            valueLevel: .error
                        )
                    )
                }
            case let .pending(amount):
                if let formatted = ValueFormatter.instance.formatShort(coinValue: amount) {
                    fields.append(
                        MultiSwapMainField(
                            title: "Pending Allowance",
                            value: "\(formatted)",
                            valueLevel: .warning
                        )
                    )
                }
            default: ()
            }

            return fields
        }

        func confirmationPriceSectionFields(tokenIn _: Token, tokenOut _: Token, feeToken _: Token?, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [MultiSwapConfirmField] {
            []
        }

        func confirmationOtherSections(tokenIn _: Token, tokenOut _: Token, feeToken: Token?, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate: Decimal?) -> [[MultiSwapConfirmField]] {
            var sections = [[MultiSwapConfirmField]]()

            if let feeData = feeData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate) {
                sections.append(
                    [
                        .value(
                            title: "Network Fee",
                            description: .init(title: "Network Fee", description: "Network Fee Description"),
                            coinValue: feeData.coinValue,
                            currencyValue: feeData.currencyValue
                        ),
                    ]
                )
            }

            return sections
        }
    }
}
