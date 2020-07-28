import UniswapKit

protocol ISwapView: class {
    func dismissKeyboard()

    func bind(viewItem: SwapViewItem)
    func amount(path: SwapPath) -> String?
}

protocol ISwapViewDelegate {
    func onViewDidLoad()
    func onClose()

    func isValid(path: SwapPath, text: String) -> Bool
    func willChangeAmount(path: SwapPath, text: String?)

    func onTokenSelect(path: SwapPath)
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
    func openTokenSelect(path: SwapPath, exclude: [Coin], delegate: ICoinSelectDelegate)
    func dismiss()
}

protocol ISwapInputViewDelegate: class {
    func isValid(_ inputView: SwapInputView, text: String) -> Bool

    func willChangeAmount(_ inputView: SwapInputView, text: String?)

    func onMaxClicked(_ inputView: SwapInputView)
    func onTokenSelectClicked(_ inputView: SwapInputView)
}

protocol ISwapViewItemFactory {
    func viewItem(coinIn: Coin, balance: Decimal?, coinOut: Coin?, path: SwapPath, tradeData: TradeData?) -> SwapViewItem
}

struct CoinBalanceItem {
    let coin: Coin
    let balance: Decimal?
}
