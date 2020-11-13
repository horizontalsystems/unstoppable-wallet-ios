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
            return .error(AdapterError.unsupportedAccount)
        }

        return adapter.allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: .latest)
    }

}
