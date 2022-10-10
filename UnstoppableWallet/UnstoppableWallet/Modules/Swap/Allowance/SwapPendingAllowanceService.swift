import Foundation
import EvmKit
import RxSwift
import RxRelay
import MarketKit

class SwapPendingAllowanceService {
    private let spenderAddress: EvmKit.Address
    private let adapterManager: AdapterManager
    private let allowanceService: SwapAllowanceService

    private var token: Token?
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

    init(spenderAddress: EvmKit.Address, adapterManager: AdapterManager, allowanceService: SwapAllowanceService) {
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
            state = .notAllowed
            return
        }

//        print("allowance state: \(allowanceService.state)")
        guard case .ready(let allowance) = allowanceService.state else {
            state = .notAllowed
            return
        }

        if pendingAllowance != allowance.value {
            state = pendingAllowance == 0 ? .revoking : .pending
        } else {
            state = .approved
        }
    }

}

extension SwapPendingAllowanceService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(token: Token?) {
        self.token = token
        pendingAllowance = nil

        syncAllowance()
    }

    func syncAllowance() {
        guard let token = token, let adapter = adapterManager.adapter(for: token) as? IErc20Adapter else {
            return
        }

        for transaction in adapter.pendingTransactions {
            if let approve = transaction as? ApproveTransactionRecord, let value = approve.value.decimalValue {
                pendingAllowance = value
            }
        }

        sync()
    }

}

extension SwapPendingAllowanceService {

    enum State: Int {
        case notAllowed, revoking, pending, approved
    }

}
