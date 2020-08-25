import EthereumKit
import RxSwift

class AllowanceRepository {
    static private let refreshInterval = 10

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
    }

}

extension AllowanceRepository {

    func allowanceObservable(coin: Coin, spenderAddress: Address) -> Observable<Decimal> {
        guard let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
            return .error(SendTransactionError.wrongAmount)     // todo: add error if adapter not found
        }

        return Observable<Int>
                .timer(.seconds(0), period: RxTimeInterval.seconds(AllowanceRepository.refreshInterval), scheduler: MainScheduler.instance)
                .flatMap { _ in
                    adapter.allowanceSingle(spenderAddress: spenderAddress)
                }
    }

    func allowanceSingle(coin: Coin, spenderAddress: Address) -> Single<Decimal> {
        guard let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
            return .error(SendTransactionError.wrongAmount)     // todo: add error if adapter not found
        }

        return adapter.allowanceSingle(spenderAddress: spenderAddress)
    }

}
