import EvmKit
import Foundation
import MarketKit
import SwiftUI

class BaseEvmMultiSwapProvider: IMultiSwapProvider {
    private static let unlockStepId = "unlock"

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

    func preSwapView(stepId: String, tokenIn: Token, tokenOut _: Token, amount: Decimal, isPresented: Binding<Bool>) -> AnyView {
        if stepId == Self.unlockStepId {
            do {
                let chain = evmBlockchainManager.chain(blockchainType: tokenIn.blockchainType)
                let spenderAddress = try spenderAddress(chain: chain)
                let viewModel = try MultiSwapApproveViewModel(token: tokenIn, amount: amount, spenderAddress: spenderAddress)
                let view = ThemeNavigationView { MultiSwapApproveView(viewModel: viewModel, isPresented: isPresented) }
                return AnyView(view)
            } catch {
                return AnyView(Text("Can't Create Evm Allowance View"))
            }
        }

        return AnyView(Text("Evm Allowance View"))
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

    private func pendingAllowance(pendingTransactions: [TransactionRecord]) -> Decimal? {
        for transaction in pendingTransactions {
            if let approve = transaction as? ApproveTransactionRecord, let value = approve.value.decimalValue {
                return value
            }
        }

        return nil
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
        let allowanceState: AllowanceState

        init(allowanceState: AllowanceState) {
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

        func cautions() -> [CautionNew] {
            []
        }

        func fields(tokenIn _: Token, tokenOut _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?) -> [MultiSwapMainField] {
            var fields = [MultiSwapMainField]()

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
    }

    class ConfirmationQuote: IMultiSwapConfirmationQuote {
        let gasPrice: GasPrice?
        let gasLimit: Int?
        let nonce: Int?

        init(gasPrice: GasPrice?, gasLimit: Int?, nonce: Int?) {
            self.gasPrice = gasPrice
            self.gasLimit = gasLimit
            self.nonce = nonce
        }

        var amountOut: Decimal {
            fatalError("Must be implemented in subclass")
        }

        var feeData: FeeData? {
            gasLimit.map { .evm(gasLimit: $0) }
        }

        var canSwap: Bool {
            gasPrice != nil && gasLimit != nil
        }

        func cautions(feeToken _: Token) -> [CautionNew] {
            []
        }

        private func feeData(feeToken: Token, currency: Currency, feeTokenRate: Decimal?) -> AmountData? {
            guard let gasPrice, let gasLimit else {
                return nil
            }

            let amount = Decimal(gasLimit) * Decimal(gasPrice.max) / pow(10, feeToken.decimals)
            let coinValue = CoinValue(kind: .token(token: feeToken), value: amount)
            let currencyValue = feeTokenRate.map { CurrencyValue(currency: currency, value: amount * $0) }

            return AmountData(coinValue: coinValue, currencyValue: currencyValue)
        }

        func priceSectionFields(tokenIn _: Token, tokenOut _: Token, feeToken _: Token, currency _: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate _: Decimal?) -> [MultiSwapConfirmField] {
            []
        }

        func otherSections(tokenIn _: Token, tokenOut _: Token, feeToken: Token, currency: Currency, tokenInRate _: Decimal?, tokenOutRate _: Decimal?, feeTokenRate: Decimal?) -> [[MultiSwapConfirmField]] {
            var sections = [[MultiSwapConfirmField]]()

            let feeData = feeData(feeToken: feeToken, currency: currency, feeTokenRate: feeTokenRate)

            sections.append(
                [
                    .value(
                        title: "Network Fee",
                        description: .init(title: "Network Fee", description: "Network Fee Description"),
                        coinValue: feeData?.coinValue,
                        currencyValue: feeData?.currencyValue
                    ),
                ]
            )

            return sections
        }
    }
}
