import UniswapKit

class SwapPresenter {
    private let maxCoinDecimal = 8

    private let interactor: ISwapInteractor
    private let router: ISwapRouter

    private let factory: ISwapViewItemFactory
    private let decimalParser: ISendAmountDecimalParser

    weak var view: ISwapView?

    private var coinIn: Coin
    private var coinOut: Coin?

    private var balanceIn: Decimal?

    private var swapData: SwapData?
    private var tradeData: TradeData?

    private var tradeType: TradeType = .exactIn

    init(interactor: ISwapInteractor, router: ISwapRouter, factory: ISwapViewItemFactory, decimalParser: ISendAmountDecimalParser, coinIn: Coin) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.decimalParser = decimalParser
        self.coinIn = coinIn
    }

    private func sync() {
        balanceIn = interactor.balance(coin: coinIn)

        view?.bind(viewItem: factory.viewItem(coinIn: coinIn, balance: balanceIn, coinOut: coinOut, type: tradeType, tradeData: tradeData))
    }

    private func tradeData(type: TradeType) -> TradeData? {
        guard let swapData = swapData,
              let amount = decimalParser.parseAnyDecimal(from: view?.amount(type: type)) else {
            return nil
        }

        switch type {
        case .exactIn: return try? interactor.bestTradeExactIn(swapData: swapData, amount: amount)
        case .exactOut: return try? interactor.bestTradeExactOut(swapData: swapData, amount: amount)
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

    func willChangeAmount(type: TradeType, text: String?) {
        self.tradeType = type

        tradeData = tradeData(type: type)
        sync()
    }

    func isValid(type: TradeType, text: String) -> Bool {
        guard let value = decimalParser.parseAnyDecimal(from: text) else {
            return false
        }

        let decimal: Int
        var balance: Decimal? = nil

        switch type {
        case .exactIn:
            decimal = min(coinIn.decimal, maxCoinDecimal)
            balance = self.balanceIn
        case .exactOut: decimal = min(coinOut?.decimal ?? maxCoinDecimal, maxCoinDecimal)
        }

        let insufficientAmount = balance.map { value > $0 } ?? false
        return value.decimalCount <= decimal && !insufficientAmount
    }

    func onTokenSelect(type: TradeType) {
        let exclude = type == .exactOut ? [coinIn] : []

        router.openTokenSelect(accountCoins: type == .exactIn, exclude: exclude, delegate: self)
    }

    func onProceed() {
        guard let coinOut = coinOut,
              let tradeData = tradeData else {

            return
        }

        router.showConfirmation(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData, delegate: self)
    }

}

extension SwapPresenter: ISwapInteractorDelegate {

    func clearSwapData() {
        swapData = nil

        sync()
    }

    func didReceive(swapData: SwapData) {
        self.swapData = swapData

        tradeData = tradeData(type: tradeType)
        sync()
    }

    func didFailReceiveSwapData(error: Error) {
        swapData = nil

        sync()
    }

}

extension SwapPresenter: ICoinSelectDelegate {

    func didSelect(accountCoins: Bool, coin: Coin) {
        if accountCoins {
            coinIn = coin
            if coinOut == coin {
                coinOut = nil
            }
        } else {
            coinOut = coin
        }

        interactor.requestSwapData(coinIn: coinIn, coinOut: coinOut)

        sync()
    }

}

extension SwapPresenter: ISwapConfirmationDelegate {

    func onSwapClicked() {
        view?.dismissWithSuccess()
    }

    func onCancelClicked() {
        router.dismiss()
    }

}
