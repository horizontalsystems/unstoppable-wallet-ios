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
        let balance = interactor.balance(coin: coinIn)
        view?.bind(viewItem: factory.viewItem(coinIn: coinIn, balance: balance, coinOut: coinOut, path: path, tradeData: tradeData))
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
        sync()
    }

    func onTokenSelect(path: SwapPath) {
        let exclude = path == .to ? [coinIn] : []

        router.openTokenSelect(path: path, exclude: exclude, delegate: self)
    }

}

extension SwapPresenter: ISwapInteractorDelegate {

    func clearSwapData() {
        swapData = nil

        sync()
    }

    func didReceive(swapData: SwapData) {
        self.swapData = swapData

        tradeData = tradeData(path: path)
        sync()
    }

    func didFailReceiveSwapData(error: Error) {
        swapData = nil

        sync()
    }

}

extension SwapPresenter: ICoinSelectDelegate {

    func didSelect(path: SwapPath, coin: Coin) {
        switch path {
        case .from:
            coinIn = coin
            if coinOut == coin {
                coinOut = nil
            }
        case .to:
            coinOut = coin
        }

        interactor.requestSwapData(coinIn: coinIn, coinOut: coinOut)

        sync()
    }

}