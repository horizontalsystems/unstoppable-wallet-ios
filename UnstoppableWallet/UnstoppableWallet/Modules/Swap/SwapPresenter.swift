import UniswapKit

class SwapPresenter {
    private let interactor: ISwapInteractor
    private let router: ISwapRouter

    private let factory: ISwapViewItemFactory
    private let decimalParser: ISendAmountDecimalParser

    weak var view: ISwapView?

    private var coinIn: Coin
    private var coinOut: Coin?

    private var swapData: SwapData?
    private var tradeData: TradeData?

    private var path: SwapPath = .from

    init(interactor: ISwapInteractor, router: ISwapRouter, factory: ISwapViewItemFactory, decimalParser: ISendAmountDecimalParser, coinIn: Coin) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.decimalParser = decimalParser
        self.coinIn = coinIn
    }

    private func sync() {
        view?.bind(viewItem: factory.viewItem(coinIn: coinIn, coinOut: coinOut, path: path, tradeData: tradeData))
    }

    private func tradeData(path: SwapPath) -> TradeData? {
        guard let swapData = swapData,
              let amount = decimalParser.parseAnyDecimal(from: view?.amount(path: path)) else {
            return nil
        }

        switch path {
        case .to: return try? interactor.bestTradeExactOut(swapData: swapData, amount: amount)
        case .from: return try? interactor.bestTradeExactIn(swapData: swapData, amount: amount)
        }
    }

}

extension SwapPresenter: ISwapViewDelegate {

    func onViewDidLoad() {
        sync()
    }

    func onClose() {
        view?.dismissKeyboard()

        router.dismiss()
    }

    func didChangeAmount(path: SwapPath) {
        self.path = path

        tradeData = tradeData(path: path)
        view?.bind(viewItem: factory.viewItem(coinIn: coinIn, coinOut: coinOut, path: path, tradeData: tradeData))
    }

}

extension SwapPresenter: ISwapInteractorDelegate {

    func didReceive(swapData: UniswapKit.SwapData) {

    }

    func didFailReceiveSwapData(error: Error) {
    }

}