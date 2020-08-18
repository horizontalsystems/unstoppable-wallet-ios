import Foundation
import EthereumKit

protocol ISwapApproveView: class {
    func set(viewItem: SwapApproveModule.ViewItem)
    func show(error: Error)
    func showSuccess()
}

protocol ISwapApproveViewDelegate {
    func onLoad()
    func onTapApprove()
    func onTapClose()
}

protocol ISwapApproveInteractor {
    func fetchFeeRate()
    func fetchFee(address: String, amount: Decimal, feeRate: Int)
    func approve(spenderAddress: Address, amount: Decimal, gasLimit: Int, gasPrice: Int)
}

protocol ISwapApproveInteractorDelegate: AnyObject {
    func onReceive(feeRate: FeeRate)
    func onFailReceiveFeeRate(_ error: Error)
    func onReceive(fee: Int)
    func onFailReceiveFee(_ error: Error)
    func onApproveSend()
    func onFailApprove(error: Error)
}

protocol ISwapApproveRouter {
    func close()
}

protocol ISwapApproveViewItemFactory {
    func viewItem(coin: Coin, amount: Decimal, fee: DataStatus<Int>, feeRate: DataStatus<FeeRate>, feeRatePriority: FeeRatePriority) -> SwapApproveModule.ViewItem
}

protocol ISwapApproveDelegate {
    func didApprove()
}

class SwapApproveModule {

    struct ViewItem {
        let coinCode: String
        let amount: String?
        let fee: DataStatus<String?>
        let transactionSpeed: String?
    }

}
