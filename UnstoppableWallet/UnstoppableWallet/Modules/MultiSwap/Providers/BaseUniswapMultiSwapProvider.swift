import Foundation

class BaseUniswapMultiSwapProvider: BaseEvmMultiSwapProvider {
    let marketKit = App.shared.marketKit
    let evmSyncSourceManager = App.shared.evmSyncSourceManager
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
        case invalidQuote
    }
}

extension BaseUniswapMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        private let recipient: Address?
        private let slippage: Decimal

        init(recipient: Address?, slippage: Decimal, estimatedGas: Int?, allowanceState: AllowanceState) {
            self.recipient = recipient
            self.slippage = slippage

            super.init(estimatedGas: estimatedGas, allowanceState: allowanceState)
        }

        override var mainFields: [MultiSwapMainField] {
            var fields = super.mainFields

            if let recipient {
                fields.append(
                    MultiSwapMainField(
                        title: "Recipient",
                        value: recipient.title,
                        valueLevel: .regular
                    )
                )
            }

            if slippage != MultiSwapSlippage.default {
                fields.append(
                    MultiSwapMainField(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        valueLevel: MultiSwapSlippage.validate(slippage: slippage).valueLevel
                    )
                )
            }

            return fields
        }

        override var cautions: [CautionNew] {
            var cautions = super.cautions

            switch MultiSwapSlippage.validate(slippage: slippage) {
            case .none: ()
            case let .caution(caution): cautions.append(caution.cautionNew(title: "swap.advanced_settings.slippage".localized))
            }

            return cautions
        }
    }
}
