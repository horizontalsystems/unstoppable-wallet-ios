import EvmKit
import Foundation
import MarketKit
import RxRelay
import RxSwift

class SwapAllowanceService {
    private let spenderAddress: EvmKit.Address
    private let adapterManager: AdapterManager

    private var token: Token?

    private let disposeBag = DisposeBag()
    private var allowanceDisposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State?>()
    private(set) var state: State? {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    init(spenderAddress: EvmKit.Address, adapterManager: AdapterManager, evmKit: EvmKit.Kit) {
        self.spenderAddress = spenderAddress
        self.adapterManager = adapterManager

        evmKit.lastBlockHeightObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] _ in
                self?.sync()
            })
            .disposed(by: disposeBag)
    }

    private func sync() {
        allowanceDisposeBag = DisposeBag()

        guard let token, let adapter = adapterManager.adapter(for: token) as? IErc20Adapter else {
            state = nil
            return
        }

        if let state, case .ready = state {
            // no need to set loading, simply update to new allowance value
        } else {
            state = .loading
        }

        adapter
            .allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: .latest)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] allowance in
                self?.state = .ready(allowance: CoinValue(kind: .token(token: token), value: allowance))
            }, onError: { [weak self] error in
                self?.state = .notReady(error: error)
            })
            .disposed(by: allowanceDisposeBag)
    }
}

extension SwapAllowanceService {
    var stateObservable: Observable<State?> {
        stateRelay.asObservable()
    }

    func set(token: Token?) {
        self.token = token
        sync()
    }

    func approveData(dex: SwapModule.Dex, amount: Decimal) -> ApproveData? {
        guard case let .ready(allowance) = state else {
            return nil
        }

        guard let token else {
            return nil
        }

        return ApproveData(
            dex: dex,
            token: token,
            spenderAddress: spenderAddress,
            amount: amount,
            allowance: allowance.value
        )
    }
}

extension SwapAllowanceService {
    enum State: Equatable {
        case loading
        case ready(allowance: CoinValue)
        case notReady(error: Error)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case let (.ready(lhsAllowance), .ready(rhsAllowance)): return lhsAllowance == rhsAllowance
            default: return false
            }
        }
    }

    struct ApproveData {
        let dex: SwapModule.Dex
        let token: Token
        let spenderAddress: EvmKit.Address
        let amount: Decimal
        let allowance: Decimal
    }
}
