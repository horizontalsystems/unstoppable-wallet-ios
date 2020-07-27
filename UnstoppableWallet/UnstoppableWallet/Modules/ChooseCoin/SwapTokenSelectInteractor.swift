import RxSwift

class SwapTokenSelectInteractor {
    private let disposeBag = DisposeBag()

    private let swapCoinManager: ISwapCoinManager
    private let walletManager: IWalletManager
    private let accountManager: IAccountManager

    init(swapCoinManager: ISwapCoinManager, walletManager: IWalletManager, accountManager: IAccountManager) {
        self.swapCoinManager = swapCoinManager
        self.walletManager = walletManager
        self.accountManager = accountManager
    }

}

extension SwapTokenSelectInteractor: ISwapTokenSelectInteractor {

    func coins(path: SwapPath, exclude: [Coin]) -> [CoinBalanceItem] {
        swapCoinManager.items(path: path, exclude: exclude)
    }

}
