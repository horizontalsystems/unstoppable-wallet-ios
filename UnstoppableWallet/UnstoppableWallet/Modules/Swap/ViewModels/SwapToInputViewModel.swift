import UniswapKit

class SwapToInputViewModel: BaseSwapInputViewModel {

    override var type: TradeType {
        .exactOut
    }

    override var _description: String {
        "swap.you_get"
    }

    override var coin: Coin? {
        service.coinOut
    }

    override func subscribeToService() {
        super.subscribeToService()

        update(amount: service.amountOut)
        handle(coin: service.coinOut)
        subscribe(disposeBag, service.amountOutObservable) { [weak self] in self?.update(amount: $0) }
        subscribe(disposeBag, service.coinOutObservable) { [weak self] in self?.handle(coin: $0) }
        subscribe(disposeBag, service.balanceOutObservable) { [weak self] in self?.handle(balance: $0) }
    }

}
