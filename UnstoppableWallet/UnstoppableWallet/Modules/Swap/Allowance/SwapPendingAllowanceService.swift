import Foundation
import EthereumKit
import RxSwift
import RxRelay
import CoinKit

class SwapPendingAllowanceService {
    private let spenderAddress: EthereumKit.Address
    private let adapterManager: AdapterManager
    private let allowanceService: SwapAllowanceService

    private var coin: Coin?
    private var pendingAllowance: Decimal?

    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notAllowed {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    init(spenderAddress: EthereumKit.Address, adapterManager: AdapterManager, allowanceService: SwapAllowanceService) {
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
//        print("Pending allowance: \(pendingAllowance ?? -1)")
        guard let pendingAllowance = pendingAllowance else {
            print("new state: .notAllowed")
            state = .notAllowed
            return
        }

//        print("allowance state: \(allowanceService.state)")
        guard case .ready(let allowance) = allowanceService.state else {
            print("new state: .notAllowed")
            state = .notAllowed
            return
        }

//        print("new state: \(pendingAllowance != allowance.value ? State.pending : State.approved)")
        state = pendingAllowance != allowance.value ? .pending : .approved
    }

}

extension SwapPendingAllowanceService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
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
            if let approve = transaction as? ApproveTransactionRecord {
                pendingAllowance = approve.value.value
            }
        }

        sync()
    }

}

extension SwapPendingAllowanceService {

    enum State: Int {
        case notAllowed, pending, approved
    }

}
