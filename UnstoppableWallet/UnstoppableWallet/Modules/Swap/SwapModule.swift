import UniswapKit

protocol ISwapView: class {
    func showKeyboard(path: SwapPath)
    func dismissKeyboard()

    func bind(viewItem: SwapViewItem)
    func amount(path: SwapPath) -> String?
}

protocol ISwapViewDelegate {
    func onViewDidLoad()
    func onClose()

    func didChangeAmount(path: SwapPath)
}

protocol ISwapInteractor {
    func requestSwapData(coinIn: Coin?, coinOut: Coin?)
    func bestTradeExactIn(swapData: SwapData, amount: Decimal) throws -> TradeData
    func bestTradeExactOut(swapData: SwapData, amount: Decimal) throws -> TradeData
}

protocol ISwapInteractorDelegate: class {
    func didReceive(swapData: SwapData)
    func didFailReceiveSwapData(error: Error)
}

protocol ISwapRouter {
    func dismiss()
}

protocol ISwapInputViewDelegate: class {
    func isValid(_ inputView: SwapInputView, text: String) -> Bool

    func willChangeAmount(_ inputView: SwapInputView, text: String?)
    func didChangeAmount(_ inputView: SwapInputView, text: String?)

    func onMaxClicked(_ inputView: SwapInputView)
    func onTokenSelectClicked(_ inputView: SwapInputView)
}

protocol ISwapViewItemFactory {
    func viewItem(coinIn: Coin, coinOut: Coin?, path: SwapPath, tradeData: TradeData?) -> SwapViewItem
}