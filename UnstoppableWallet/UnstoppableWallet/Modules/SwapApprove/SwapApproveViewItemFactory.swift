import Foundation

class SwapApproveViewItemFactory {
    private let feeModule: IFeeModule

    init(feeModule: IFeeModule) {
        self.feeModule = feeModule
    }

}

extension SwapApproveViewItemFactory: ISwapApproveViewItemFactory {

    func viewItem(coin: Coin, amount: Decimal, fee: DataStatus<Int>, feeRate: DataStatus<FeeRate>, feeRatePriority: FeeRatePriority) -> SwapApproveModule.ViewItem {
        let feeData = DataStatus<(Int, Int)>.zip(fee, feeRate)
        let feeValue = feeData.map { fee, feeRate in // Adapter.fee(:)
            feeModule.viewItem(coin: coin, fee: Decimal(fee) * Decimal(feeRate.feeRate(priority: feeRatePriority)) / pow(10, EthereumAdapter.decimal), reversed: false).value
        }

        return SwapApproveModule.ViewItem(coinCode: coin.code,
                amount: amount.description,
                fee: feeValue,
                transactionSpeed: feeRatePriority.title)
    }

}
