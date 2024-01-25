import Foundation

class BaseUniswapMultiSwapProvider: BaseEvmMultiSwapProvider {
    let marketKit = App.shared.marketKit
    let evmSyncSourceManager = App.shared.evmSyncSourceManager
}

extension BaseUniswapMultiSwapProvider {
    enum SwapError: Error {
        case invalidToken
        case noHttpRpcSource
    }
}

extension BaseUniswapMultiSwapProvider {
    class Quote: BaseEvmMultiSwapProvider.Quote {
        private let slippage: Decimal

        init(slippage: Decimal, estimatedGas: Int?, allowanceState: AllowanceState) {
            self.slippage = slippage

            super.init(estimatedGas: estimatedGas, allowanceState: allowanceState)
        }

        override var mainFields: [MultiSwapMainField] {
            var fields = super.mainFields

            if slippage != BaseUniswapMultiSwapProvider.defaultSlippage {
                fields.append(
                    MultiSwapMainField(
                        title: "Slippage",
                        value: "\(slippage.description)%",
                        valueLevel: .warning
                    )
                )
            }

            return fields
        }
    }
}
