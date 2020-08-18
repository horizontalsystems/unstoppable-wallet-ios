import Foundation
import RxSwift
import EthereumKit

class SwapApproveInteractor {
    private let feeDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let feeAdapter: IFeeAdapter
    private let sendAdapter: IErc20Adapter
    private let provider: IFeeRateProvider

    weak var delegate: ISwapApproveInteractorDelegate?


    init(feeAdapter: IFeeAdapter, provider: IFeeRateProvider, sendAdapter: IErc20Adapter) {
        self.feeAdapter = feeAdapter
        self.sendAdapter = sendAdapter
        self.provider = provider
    }

}

extension SwapApproveInteractor: ISwapApproveInteractor {

    var ethereumBalance: Decimal {
        sendAdapter.ethereumBalance
    }

    func fetchFee(address: String, amount: Decimal, feeRate: Int) {
        feeAdapter.fee(address: address, amount: amount, feeRate: feeRate).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fee in
                    self?.delegate?.onReceive(fee: fee)
                }, onError: { [weak self] error in
                    self?.delegate?.onFailReceiveFee(error)
                })
                .disposed(by: feeDisposeBag)
    }

    func fetchFeeRate() {
        provider.feeRate
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] feeRate in
                    self?.delegate?.onReceive(feeRate: feeRate)
                }, onError: { [weak self] error in
                    self?.delegate?.onFailReceiveFeeRate(error)
                })
                .disposed(by: feeDisposeBag)
    }

    func approve(spenderAddress: Address, amount: Decimal, gasLimit: Int, gasPrice: Int) {
        sendAdapter.approveSingle(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.delegate?.onApproveSend()
                }, onError: { [weak self] error in
                    self?.delegate?.onFailApprove(error: error)
                })
                .disposed(by: disposeBag)
    }

}
