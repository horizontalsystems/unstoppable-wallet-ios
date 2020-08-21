import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveService {
    private let feeDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let feeAdapter: IFeeAdapter
    private let sendAdapter: IErc20Adapter
    private let provider: IFeeRateProvider

    private let approveRelay = BehaviorRelay<ApproveState>(value: .idle)
    private let feeRelay = BehaviorRelay<DataState<Int>>(value: .loading)
    private let feeRateRelay = BehaviorRelay<DataState<FeeRate>>(value: .loading)

    init(feeAdapter: IFeeAdapter, provider: IFeeRateProvider, sendAdapter: IErc20Adapter) {
        self.feeAdapter = feeAdapter
        self.sendAdapter = sendAdapter
        self.provider = provider
    }

}

extension SwapApproveService {

    var ethereumBalance: Decimal {
        sendAdapter.ethereumBalance
    }

    var approve: Observable<ApproveState> {
        approveRelay.asObservable()
    }

    var fee: Observable<DataState<Int>> {
        feeRelay.asObservable()
    }

    var feeRate: Observable<DataState<FeeRate>> {
        feeRateRelay.asObservable()
    }

    func fetchFee(address: String, amount: Decimal, feeRate: Int) {
        feeRelay.accept(.loading)

        feeAdapter.fee(address: address, amount: amount, feeRate: feeRate).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fee in
                    self?.feeRelay.accept(.success(result: fee))
                }, onError: { [weak self] error in
                    self?.feeRelay.accept(.error(error: error))
                })
                .disposed(by: feeDisposeBag)
    }

    func fetchFeeRate() {
        feeRateRelay.accept(.loading)

        provider.feeRate
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] feeRate in
                    self?.feeRateRelay.accept(.success(result: feeRate))
                }, onError: { [weak self] error in
                    self?.feeRateRelay.accept(.error(error: error))
                })
                .disposed(by: feeDisposeBag)
    }

    func approve(spenderAddress: Address, amount: Decimal, gasLimit: Int, gasPrice: Int) {
        approveRelay.accept(.loading)

        sendAdapter.approveSingle(spenderAddress: spenderAddress, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] _ in
                    self?.approveRelay.accept(.success)
                }, onError: { [weak self] error in
                    self?.approveRelay.accept(.error(error: error))
                })
                .disposed(by: disposeBag)
    }

}
