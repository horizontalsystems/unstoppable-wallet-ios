import EthereumKit
import Erc20Kit
import UniswapKit
import RxSwift

class SwapInteractor {
    private let disposeBag = DisposeBag()
    private var allowanceDisposeBag = DisposeBag()
    private let swapKit: ISwapKit
    private let swapTokenManager: SwapTokenManager

    weak var delegate: ISwapInteractorDelegate?

    init(swapKit: ISwapKit, swapTokenManager: SwapTokenManager) {
        self.swapKit = swapKit
        self.swapTokenManager = swapTokenManager
    }

    private func uniswapToken(coin: Coin) throws -> Token {
        if case let .erc20(address, _, _, _) = coin.type {
            return swapKit.token(contractAddress: try Address(hex: address), decimals: coin.decimal)
        }

        return swapKit.etherToken
    }

}

extension SwapInteractor: ISwapInteractor {

    var spenderAddress: Address {
        swapKit.routerAddress
    }

    func balance(coin: Coin) -> Decimal? {
        swapTokenManager.balance(coin: coin)
    }

    func requestSwapData(coinIn: Coin?, coinOut: Coin?) {
        guard let coinIn = coinIn, let coinOut = coinOut else {
            delegate?.clearSwapData()

            return
        }

        do {
            let tokenIn = try uniswapToken(coin: coinIn)
            let tokenOut = try uniswapToken(coin: coinOut)

            swapKit.swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] swapData in
                        self?.delegate?.didReceive(swapData: swapData)
                    }, onError: { [weak self] error in
                        self?.delegate?.didFailReceiveSwapData(error: error)
                    })
                    .disposed(by: disposeBag)
        } catch {
            self.delegate?.didFailReceiveSwapData(error: error)
        }
    }

    func requestAllowance(coin: Coin) {
        guard case .erc20 = coin.type else {
            self.delegate?.didReceive(allowance: nil)
            return
        }

        swapTokenManager.allowanceSingle(coin: coin, spenderAddress: swapKit.routerAddress)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.delegate?.didReceive(allowance: allowance)
                }, onError: { [weak self] error in
                    self?.delegate?.didFailReceiveAllowance(error: error)
                })
                .disposed(by: disposeBag)
    }

    func allowanceChanging(subscribe: Bool, coin: Coin) {
        if subscribe {
            Observable<Int>.interval(.seconds(10), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] time in
                        self?.requestAllowance(coin: coin)
                    })
                    .disposed(by: allowanceDisposeBag)
        } else {
            allowanceDisposeBag = DisposeBag()
        }
    }

    func bestTradeExactIn(swapData: SwapData, amount: Decimal) throws -> TradeData {
        try swapKit.bestTradeExactIn(swapData: swapData, amountIn: amount, options: TradeOptions())
    }

    func bestTradeExactOut(swapData: SwapData, amount: Decimal) throws -> TradeData {
        try swapKit.bestTradeExactOut(swapData: swapData, amountOut: amount, options: TradeOptions())
    }

}
