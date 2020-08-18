import Foundation
import RxSwift

protocol IFeeAdapter {
    func fee(address: String, amount: Decimal, feeRate: Int) -> Single<Int>
}

protocol IFeeAdapterFactory {
    func swapAdapter(adapter: IAdapter) -> IFeeAdapter?
}

class FeeAdapterFactory {
}

extension FeeAdapterFactory: IFeeAdapterFactory {

    func swapAdapter(adapter: IAdapter) -> IFeeAdapter? {
        guard let adapter = adapter as? IErc20Adapter else {
            return nil
        }
        return SwapFeeAdapter(adapter: adapter)
    }

}
