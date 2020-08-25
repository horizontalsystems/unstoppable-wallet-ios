import UniswapKit

class SwapToInputPresenter: BaseSwapInputPresenter {

    override var type: TradeType {
        .exactOut
    }

    override var _description: String {
        "swap.you_get"
    }

    override func subscribeToService() {
        super.subscribeToService()

        subscribe(disposeBag, service.amountOut.withLatestFrom(service.estimated) { ($0, $1) }) { amount, type in self.update(amount: amount, type: type) }
        subscribe(disposeBag, service.coinOut) { [weak self] in self?.handle(coin: $0) }
    }

}
