import UniswapKit

protocol ISwapView: class {
    func dismissKeyboard()

    func bind(viewItem: SwapModule.ViewItem)
    func amount(type: TradeType) -> String?

    func dismissWithSuccess()
}

protocol ISwapViewDelegate {
    func onViewDidLoad()
    func onTapInfo()
    func onClose()

    func isValid(type: TradeType, text: String) -> Bool
    func willChangeAmount(type: TradeType, text: String?)

    func onTokenSelect(type: TradeType)
    func onProceed()
}

protocol ISwapInteractor {
    func balance(coin: Coin) -> Decimal?
    func requestSwapData(coinIn: Coin?, coinOut: Coin?)
    func bestTradeExactIn(swapData: SwapData, amount: Decimal) throws -> TradeData
    func bestTradeExactOut(swapData: SwapData, amount: Decimal) throws -> TradeData
}

protocol ISwapInteractorDelegate: class {
    func clearSwapData()
    func didReceive(swapData: SwapData)
    func didFailReceiveSwapData(error: Error)
}

protocol ISwapRouter {
    func openTokenSelect(accountCoins: Bool, exclude: [Coin], delegate: ICoinSelectDelegate)
    func showUniswapInfo()
    func showConfirmation(coinIn: Coin, coinOut: Coin, tradeData: TradeData, delegate: ISwapConfirmationDelegate)
    func dismiss()
}

protocol ISwapInputViewDelegate: class {
    func isValid(_ inputView: SwapInputView, text: String) -> Bool

    func willChangeAmount(_ inputView: SwapInputView, text: String?)

    func onMaxClicked(_ inputView: SwapInputView)
    func onTokenSelectClicked(_ inputView: SwapInputView)
}

protocol ISwapViewItemFactory {
    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, type: TradeType, tradeData: TradeData?) -> SwapModule.ViewItem
}

extension UniswapKit.Kit: ISwapKit {
}

struct CoinBalanceItem {
    let coin: Coin
    let balance: Decimal?
}

enum SwapValidationError: Error, LocalizedError {
    case insufficientBalance(availableBalance: String?)

    var errorDescription: String? {
        switch self {
        case .insufficientBalance(let availableBalance):
            return "swap.amount_error.maximum_amount".localized(availableBalance ?? "")
        }
    }

}

class SwapModule {

    struct ViewItem {
        let exactType: TradeType
        let estimatedAmount: String?
        let error: Error?

        let tokenIn: String
        let tokenOut: String?

        let availableBalance: String?

        let minMaxTitle: String
        let minMaxValue: String
        let executionPriceValue: String?
        let priceImpactValue: String
        let priceImpactColor: UIColor

        let swapButtonEnabled: Bool
    }

}
