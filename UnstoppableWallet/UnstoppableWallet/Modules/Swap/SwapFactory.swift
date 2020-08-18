import Foundation
import UniswapKit

class SwapFactory {

    private func allowanceState(allowance: DataStatus<Decimal>, amount: Decimal) -> SwapProcessState {
        if let allowanceValue = allowance.data, allowanceValue >= amount {     // if allow to send
            return .proceed
        }

        return .approve
    }

}
extension SwapFactory: ISwapFactory {

    func swapState(coinIn: Coin, allowance: DataStatus<Decimal>?, tradeData: DataStatus<TradeData>?, approving: Bool) -> SwapProcessState {
        guard let amount = tradeData?.data?.amountIn else {
            return .hidden
        }
        guard let allowance = allowance else {
            return .proceed
        }
        if approving {
            return .approving
        }

        return allowanceState(allowance: allowance, amount: amount)
    }

}
