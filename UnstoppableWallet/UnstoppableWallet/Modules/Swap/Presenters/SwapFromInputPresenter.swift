import UniswapKit
import UIExtensions

class SwapFromInputPresenter: BaseSwapInputPresenter {

    override var type: TradeType {
        .exactIn
    }

    override var _description: String {
        "swap.you_pay"
    }

    override func subscribeToService() {
        super.subscribeToService()

        update(amount: service.amountIn)
        handle(coin: service.coinIn)
        subscribe(disposeBag, service.amountInObservable) { [weak self] in self?.update(amount: $0) }
        subscribe(disposeBag, service.coinInObservable) { [weak self] in self?.handle(coin: $0) }
    }

}
