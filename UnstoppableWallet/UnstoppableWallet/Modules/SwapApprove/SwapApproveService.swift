import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveService {
    static let feePriority: FeeRatePriority = .high

    private let feeDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let feeAdapter: IFeeAdapter
    private let sendAdapter: IErc20Adapter
    private let provider: IFeeRateProvider

    var coin: Coin
    var amount: Decimal
    var spenderAddress: Address
    var feeRate: FeeRate? = nil

    private let approveRelay = BehaviorRelay<ApproveState>(value: .approveNotAllowed)
    private let feeRelay = BehaviorRelay<DataState<Int>>(value: .loading)

    init(feeAdapter: IFeeAdapter, provider: IFeeRateProvider, sendAdapter: IErc20Adapter, coin: Coin, amount: Decimal, spenderAddress: Address) {
        self.feeAdapter = feeAdapter
        self.sendAdapter = sendAdapter
        self.provider = provider

        self.coin = coin
        self.amount = amount
        self.spenderAddress = spenderAddress

        fetchFeeRate()
    }

    func fetchFee(feeRate: FeeRate) {
        self.feeRate = feeRate
        feeRelay.accept(.loading)

        feeAdapter.fee(address: spenderAddress.hex, amount: amount, feeRate: feeRate.feeRate(priority: SwapApproveService.feePriority))
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] fee in
                    self?.feeRelay.accept(.success(result: fee))
                    self?.approveRelay.accept(.approveAllowed)
                }, onError: { [weak self] error in
                    self?.feeRelay.accept(.error(error: error))
                })
                .disposed(by: feeDisposeBag)
    }

    func fetchFeeRate() {
        provider.feeRate
                .observeOn(MainScheduler.instance)
                .subscribe(onSuccess: { [weak self] feeRate in
                    self?.fetchFee(feeRate: feeRate)
                }, onError: { [weak self] error in
                    self?.feeRelay.accept(.error(error: error))
                })
                .disposed(by: feeDisposeBag)
    }

}

extension SwapApproveService {

    var approveState: Observable<ApproveState> {
        approveRelay.asObservable()
    }

    var fee: Observable<DataState<Int>> {
        feeRelay.asObservable()
    }

    func approve() {
        guard let gasPrice = feeRate?.feeRate(priority: SwapApproveService.feePriority), case .success(let gasLimit) = feeRelay.value else {
            return
        }

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
