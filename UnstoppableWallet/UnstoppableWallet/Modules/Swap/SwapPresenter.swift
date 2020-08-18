import UniswapKit

class SwapPresenter {
    private let maxCoinDecimal = 8

    private let interactor: ISwapInteractor
    private let router: ISwapRouter

    private let stateFactory: ISwapFactory
    private let viewItemFactory: ISwapViewItemFactory
    private let decimalParser: ISendAmountDecimalParser

    weak var view: ISwapView?

    private var coinIn: Coin
    private var coinOut: Coin?

    private var balance: Decimal?
    private var allowance: DataStatus<Decimal>?

    private var approving: Bool = false
    private var swapState: SwapProcessState = .approve

    private var swapData: DataStatus<SwapData>?
    private var tradeData: DataStatus<TradeData>?

    private var tradeType: TradeType = .exactIn

    init(interactor: ISwapInteractor, router: ISwapRouter, viewItemFactory: ISwapViewItemFactory, stateFactory: ISwapFactory, decimalParser: ISendAmountDecimalParser, coinIn: Coin) {
        self.interactor = interactor
        self.router = router
        self.viewItemFactory = viewItemFactory
        self.stateFactory = stateFactory
        self.decimalParser = decimalParser
        self.coinIn = coinIn
    }

    private func sync() {
        balance = interactor.balance(coin: coinIn)
        tradeData = tradeData(type: tradeType)
        swapState = stateFactory.swapState(coinIn: coinIn, allowance: allowance, tradeData: tradeData, approving: approving)

        view?.bind(viewItem: viewItemFactory.viewItem(coinIn: coinIn, balance: balance, coinOut: coinOut, type: tradeType, allowance: allowance, tradeData: tradeData, state: swapState))
    }

    private func syncAllowance() {
        allowance = .loading
        interactor.requestAllowance(coin: coinIn)
    }

    private func syncSwapData() {
        swapData = .loading
        interactor.requestSwapData(coinIn: coinIn, coinOut: coinOut)
    }

    private func tradeData(type: TradeType) -> DataStatus<TradeData>? {
        guard let swapData = swapData else {
            return nil
        }

        switch swapData {
        case .loading: return .loading
        case .failed(let error): return .failed(error)
        case .completed(let data):
            let amount = decimalParser.parseAnyDecimal(from: view?.amount(type: type)) ?? 0

            do {
                switch type {
                case .exactIn: return try .completed(interactor.bestTradeExactIn(swapData: data, amount: amount))
                case .exactOut: return try .completed(interactor.bestTradeExactOut(swapData: data, amount: amount))
                }
            } catch {
                return .failed(error)
            }
        }
    }

    private func setCoin(tradeType: TradeType, coin: Coin) {
        switch tradeType {
        case .exactIn:
            coinIn = coin
            if coinOut == coin {
                coinOut = nil
            }
        case .exactOut:
            coinOut = coin
        }
    }

    private func set(approving: Bool) {
        self.approving = approving

        interactor.allowanceChanging(subscribe: approving, coin: coinIn)
    }

}

extension SwapPresenter: ISwapViewDelegate {

    func onViewDidLoad() {
        syncAllowance()
        sync()
    }

    func onTapInfo() {
        router.showUniswapInfo()
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
            balance = self.balance
        case .exactOut: decimal = min(coinOut?.decimal ?? maxCoinDecimal, maxCoinDecimal)
        }

        let insufficientAmount = balance.map {
            value > $0
        } ?? false
        return value.decimalCount <= decimal && !insufficientAmount
    }

    func onTokenSelect(type: TradeType) {
        let exclude = type == .exactOut ? [coinIn] : []

        router.openTokenSelect(accountCoins: type == .exactIn, exclude: exclude, delegate: self)
    }

    func onButtonClicked() {
        guard let coinOut = coinOut,
              let tradeData = tradeData?.data,
              let amount = tradeData.amountIn else {
            return
        }

        switch swapState {
        case .approve: router.showApprove(delegate: self, coin: coinIn, spenderAddress: interactor.spenderAddress, amount: amount)
        case .proceed: router.showConfirmation(coinIn: coinIn, coinOut: coinOut, tradeData: tradeData, delegate: self)
        default: ()
        }
    }

}

extension SwapPresenter: ISwapInteractorDelegate {

    func clearSwapData() {
        swapData = nil
        set(approving: false)

        sync()
    }

    func didReceive(swapData: SwapData) {
        self.swapData = .completed(swapData)
        set(approving: false)

        sync()
    }

    func didFailReceiveSwapData(error: Error) {
        swapData = .failed(error)
        set(approving: false)

        sync()
    }

    func didReceive(allowance: Decimal?) {
        if let allowance = allowance {
            if let previous = self.allowance?.data, previous != allowance {
                set(approving: false)
            }

            self.allowance = .completed(allowance)
        } else {
            set(approving: false)

            self.allowance = nil
        }

        sync()
    }

    func didFailReceiveAllowance(error: Error) {
        allowance = .failed(error)

        sync()
    }

}

extension SwapPresenter: ICoinSelectDelegate {

    func didSelect(accountCoins: Bool, coin: Coin) {
        setCoin(tradeType: accountCoins ? .exactIn : .exactOut, coin: coin)

        if accountCoins {
            syncAllowance()
        }
        syncSwapData()

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

extension SwapPresenter: ISwapApproveDelegate {

    func didApprove() {
        set(approving: true)

        sync()
    }

}