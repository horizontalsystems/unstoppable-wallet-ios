import EthereumKit
import RxSwift

class SwapFeeAdapter {
    private let adapter: IErc20Adapter

    init(adapter: IErc20Adapter) {
        self.adapter = adapter
    }

}

extension SwapFeeAdapter: IFeeAdapter {

    func fee(address: String, amount: Decimal, feeRate: Int) -> Single<Int> {
        do {
            let address = try Address(hex: address)

            return adapter.estimateApproveSingle(spenderAddress: address, amount: amount, gasPrice: feeRate)
        } catch {
            return Single.error(error)
        }
    }

}
