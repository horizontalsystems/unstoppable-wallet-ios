import Foundation
import EthereumKit

class SwapApprovePresenter {
    static private let feePriority: FeeRatePriority = .high

    weak var view: ISwapApproveView?

    private let interactor: ISwapApproveInteractor
    private let router: ISwapApproveRouter
    private let factory: ISwapApproveViewItemFactory
    private let delegate: ISwapApproveDelegate

    private let coin: Coin
    private let amount: Decimal
    private let spenderAddress: Address

    private var fee: DataStatus<Int> = .loading
    private var feeRate: DataStatus<FeeRate> = .loading

    init(interactor: ISwapApproveInteractor, router: ISwapApproveRouter, factory: ISwapApproveViewItemFactory, delegate: ISwapApproveDelegate, coin: Coin, amount: Decimal, spenderAddress: Address) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.delegate = delegate

        self.coin = coin
        self.amount = amount
        self.spenderAddress = spenderAddress
    }

    private func sync() {
        view?.set(viewItem: factory.viewItem(coin: coin, amount: amount, fee: fee, feeRate: feeRate, feeRatePriority: SwapApprovePresenter.feePriority))
    }

}

extension SwapApprovePresenter: ISwapApproveViewDelegate {

    func onLoad() {
        interactor.fetchFeeRate()

        sync()
    }

    func onTapApprove() {
        guard let gasLimit = fee.data, let gasPrice = feeRate.data else {
            return
        }
        onApproveSend()
//        interactor.approve(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice.feeRate(priority: SwapApprovePresenter.feePriority))
    }

    func onTapClose() {
        router.close()
    }

}

extension SwapApprovePresenter: ISwapApproveInteractorDelegate {

    func onReceive(feeRate: FeeRate) {
        self.feeRate = .completed(feeRate)
        interactor.fetchFee(address: spenderAddress.hex, amount: amount, feeRate: feeRate.feeRate(priority: SwapApprovePresenter.feePriority))

        sync()
    }

    func onFailReceiveFeeRate(_ error: Error) {
        self.feeRate = .failed(error)

        sync()
    }

    func onReceive(fee: Int) {
        self.fee = .completed(fee)

        sync()
    }

    func onFailReceiveFee(_ error: Error) {
        self.fee = .failed(error)

        sync()
    }

    func onApproveSend() {
        view?.showSuccess()

        delegate.didApprove()
        router.close()
    }

    func onFailApprove(error: Error) {
        view?.show(error: error)
    }

}