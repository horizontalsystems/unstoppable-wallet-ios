import EthereumKit
import Erc20Kit
import UniswapKit
import RxSwift

class SwapInteractor {
    private let disposeBag = DisposeBag()
    private let swapKit: ISwapKit
    private let swapTokenManager: SwapTokenManager

    weak var delegate: ISwapInteractorDelegate?

    init(swapKit: ISwapKit, swapTokenManager: SwapTokenManager) {
        self.swapKit = swapKit
        self.swapTokenManager = swapTokenManager
    }

    private func uniswapToken(coin: Coin) -> Token {
        if case let .erc20(address, _, _, _) = coin.type {
            return swapKit.token(contractAddress: Data(hex: address)!, decimals: coin.decimal)
        }

        return swapKit.etherToken
    }

}

extension SwapInteractor: ISwapInteractor {

    func balance(coin: Coin) -> Decimal? {
        swapTokenManager.balance(coin: coin)
    }

    func requestSwapData(coinIn: Coin?, coinOut: Coin?) {
        guard let coinIn = coinIn, let coinOut = coinOut else {
            delegate?.clearSwapData()

            return
        }

        let tokenIn = uniswapToken(coin: coinIn)
        let tokenOut = uniswapToken(coin: coinOut)

        swapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] swapData in
                    print("SwapData:\n\(swapData)")

                    self?.delegate?.didReceive(swapData: swapData)
                }, onError: { [weak self] error in
                    print("SwapError: \n\(error.localizedDescription)")

                    self?.delegate?.didFailReceiveSwapData(error: error)
                })
                .disposed(by: disposeBag)
    }

    func bestTradeExactIn(swapData: SwapData, amount: Decimal) throws -> TradeData {
        try swapKit.bestTradeExactIn(swapData: swapData, amountIn: amount, options: TradeOptions())
    }

    func bestTradeExactOut(swapData: SwapData, amount: Decimal) throws -> TradeData {
        try swapKit.bestTradeExactOut(swapData: swapData, amountOut: amount, options: TradeOptions())
    }

}
