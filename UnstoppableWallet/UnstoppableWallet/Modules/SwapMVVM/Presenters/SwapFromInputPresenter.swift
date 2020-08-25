import UniswapKit

class SwapFromInputPresenter: BaseSwapInputPresenter {

    override var type: TradeType {
        .exactIn
    }

    override var _description: String {
        "swap.you_pay"
    }

    override func subscribeToService() {
        super.subscribeToService()

        subscribe(disposeBag, service.amountIn.withLatestFrom(service.estimated) { ($0, $1) }) { amount, type in self.update(amount: amount, type: type) }
        subscribe(disposeBag, service.coinIn) { [weak self] in self?.handle(coin: $0) }
    }

}
