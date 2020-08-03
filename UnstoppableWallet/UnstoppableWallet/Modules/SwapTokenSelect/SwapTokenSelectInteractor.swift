import RxSwift

class SwapTokenSelectInteractor {
    private let disposeBag = DisposeBag()

    private let swapCoinManager: ISwapCoinManager

    init(swapCoinManager: ISwapCoinManager) {
        self.swapCoinManager = swapCoinManager
    }

}

extension SwapTokenSelectInteractor: ISwapTokenSelectInteractor {

    func coins(accountCoins: Bool, exclude: [Coin]) -> [CoinBalanceItem] {
        swapCoinManager.items(accountCoins: accountCoins, exclude: exclude)
    }

}
