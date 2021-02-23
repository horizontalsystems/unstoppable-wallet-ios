import Foundation
import EthereumKit
import RxSwift
import RxRelay
import CoinKit

class SwapPendingAllowanceService {
    private let spenderAddress: EthereumKit.Address
    private let adapterManager: IAdapterManager
    private let allowanceService: SwapAllowanceService

    private var coin: Coin?
    private var pendingAllowance: Decimal?

    private let disposeBag = DisposeBag()

    private let isPendingRelay = PublishRelay<Bool>()
    private(set) var isPending: Bool = false {
        didSet {
            if oldValue != isPending {
                isPendingRelay.accept(isPending)
            }
        }
    }

    init(spenderAddress: EthereumKit.Address, adapterManager: IAdapterManager, allowanceService: SwapAllowanceService) {
        self.spenderAddress = spenderAddress
        self.adapterManager = adapterManager
        self.allowanceService = allowanceService

        allowanceService.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })
                .disposed(by: disposeBag)
    }

    private func sync() {
        guard let pendingAllowance = pendingAllowance else {
            isPending = false
            return
        }

        guard case .ready(let allowance) = allowanceService.state else {
            isPending = false
            return
        }

        isPending = pendingAllowance != allowance.value
    }

}

extension SwapPendingAllowanceService {

    var isPendingObservable: Observable<Bool> {
        isPendingRelay.asObservable()
    }

    func set(coin: Coin?) {
        self.coin = coin
        pendingAllowance = nil

        syncAllowance()
    }

    func syncAllowance() {
        guard let coin = coin, let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
            return
        }

        for transaction in adapter.pendingTransactions {
            if transaction.type == .approve {
                pendingAllowance = transaction.amount
            }
        }

        sync()
    }

}
