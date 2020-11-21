import UniswapKit

class SwapFromCoinCardViewModel: SwapCoinCardViewModel {
    static private let insufficientBalanceIndex = 1

    override var type: TradeType {
        .exactIn
    }

    override var _description: String {
        "swap.you_pay"
    }

    override var coin: Coin? {
        tradeService.coinIn
    }

    override func subscribeToService() {
        super.subscribeToService()

        update(amount: tradeService.amountIn)
        handle(coin: tradeService.coinIn)
        handle(balance: service.balanceIn)

        subscribe(disposeBag, tradeService.amountInObservable) { [weak self] in self?.update(amount: $0) }
        subscribe(disposeBag, tradeService.coinInObservable) { [weak self] in self?.handle(coin: $0) }
        subscribe(disposeBag, service.balanceInObservable) { [weak self] in self?.handle(balance: $0) }
    }

    override func handle(errors: [Error]) {
        super.handle(errors: errors)

        let error = errors.first(where: { .insufficientBalanceIn == $0 as? SwapService.SwapError })
        balanceErrorRelay.accept(error != nil)
    }

    override func onChange(amount: String?) {
        tradeService.set(amountIn: decimalParser.parseAnyDecimal(from: amount))
    }

    override func onSelect(coin: Coin) {
        tradeService.set(coinIn: coin)
    }

}
