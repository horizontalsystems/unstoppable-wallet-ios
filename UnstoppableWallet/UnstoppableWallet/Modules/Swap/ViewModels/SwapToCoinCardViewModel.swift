import UniswapKit

class SwapToCoinCardViewModel: SwapCoinCardViewModel {

    override var type: TradeType {
        .exactOut
    }

    override var _description: String {
        "swap.you_get"
    }

    override var coin: Coin? {
        tradeService.coinOut
    }

    override func subscribeToService() {
        super.subscribeToService()

        update(amount: tradeService.amountOut)
        handle(coin: tradeService.coinOut)
        subscribe(disposeBag, tradeService.amountOutObservable) { [weak self] in self?.update(amount: $0) }
        subscribe(disposeBag, tradeService.coinOutObservable) { [weak self] in self?.handle(coin: $0) }
        subscribe(disposeBag, service.balanceOutObservable) { [weak self] in self?.handle(balance: $0) }
    }

    override func onChange(amount: String?) {
        tradeService.set(amountOut: decimalParser.parseAnyDecimal(from: amount))
    }

    override var tokensForSelection: [SwapModule.CoinBalanceItem] {
        coinService.coins(accountCoins: false, exclude: [])
    }

    override func onSelect(coin: SwapModule.CoinBalanceItem) {
        tradeService.set(coinOut: coin.coin)
    }

}
