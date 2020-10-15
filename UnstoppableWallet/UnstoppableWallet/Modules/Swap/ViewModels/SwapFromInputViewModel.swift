import UniswapKit

class SwapFromInputViewModel: BaseSwapInputViewModel {
    static private let insufficientBalanceIndex = 1

    override var type: TradeType {
        .exactIn
    }

    override var _description: String {
        "swap.you_pay"
    }

    override var coin: Coin? {
        service.coinIn
    }

    override func subscribeToService() {
        super.subscribeToService()

        update(amount: service.amountIn)
        handle(coin: service.coinIn)
        subscribe(disposeBag, service.amountInObservable) { [weak self] in self?.update(amount: $0) }
        subscribe(disposeBag, service.coinInObservable) { [weak self] in self?.handle(coin: $0) }
        subscribe(disposeBag, service.balanceInObservable) { [weak self] in self?.handle(balance: $0) }
    }

    override func handle(errors: [Error]) {
        let error = errors.first(where: { .insufficientBalance == $0 as? SwapValidationError })
        balanceErrors.set(to: Self.insufficientBalanceIndex, value: error)

        super.handle(errors: errors)
    }

}
