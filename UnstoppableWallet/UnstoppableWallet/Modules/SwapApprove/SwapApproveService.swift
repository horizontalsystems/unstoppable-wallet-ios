import Foundation
import RxCocoa
import RxSwift
import EthereumKit

class SwapApproveService {
    private let feeDisposeBag = DisposeBag()
    private let disposeBag = DisposeBag()

    private let feeService: FeeService
    private let sendAdapter: IErc20Adapter

    var coin: Coin
    var amount: Decimal
    var spenderAddress: Address

    private let approveRelay = BehaviorRelay<SwapApproveModule.ApproveState>(value: .approveNotAllowed)

    init(feeService: FeeService, sendAdapter: IErc20Adapter, coin: Coin, amount: Decimal, spenderAddress: Address) {
        self.feeService = feeService
        self.sendAdapter = sendAdapter

        self.coin = coin
        self.amount = amount
        self.spenderAddress = spenderAddress

        subscribe(disposeBag, feeService.feeState) { [weak self] feeState in
            guard case .success(let _) = feeState else {
                return
            }

            self?.approveRelay.accept(.approveAllowed)
        }
    }

}

extension SwapApproveService {

    var approveState: Observable<SwapApproveModule.ApproveState> {
        approveRelay.asObservable()
    }

    func approve() {
        guard let gasPrice = feeService.gasPrice, let gasLimit = feeService.gasLimit else {
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
