import EthereumKit
import RxSwift

class AllowanceProvider {
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
    }

}

extension AllowanceProvider {

    func allowanceObservable(coin: Coin, spenderAddress: Address) -> Single<Decimal> {
        guard let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
            return .error(SendTransactionError.wrongAmount)     // todo: add error if adapter not found
        }

        return adapter.allowanceSingle(spenderAddress: spenderAddress)
    }

}
