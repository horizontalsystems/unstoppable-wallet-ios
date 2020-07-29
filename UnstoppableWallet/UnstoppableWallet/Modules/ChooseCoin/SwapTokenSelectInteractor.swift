import RxSwift

class SwapTokenSelectInteractor {
    private let disposeBag = DisposeBag()

    private let swapCoinManager: ISwapCoinManager

    init(swapCoinManager: ISwapCoinManager) {
        self.swapCoinManager = swapCoinManager
    }

}

extension SwapTokenSelectInteractor: ISwapTokenSelectInteractor {

    func coins(path: SwapPath, exclude: [Coin]) -> [CoinBalanceItem] {
        swapCoinManager.items(path: path, exclude: exclude)
    }

}
