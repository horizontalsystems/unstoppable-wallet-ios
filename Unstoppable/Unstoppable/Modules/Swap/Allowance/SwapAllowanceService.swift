import Combine
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
    private var allowanceTask: Task<Void, Never>?

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
        allowanceTask?.cancel()

        guard let token, let adapter = adapterManager.adapter(for: token) as? IAllowanceAdapter else {
            state = nil
            return
        }

        if let state, case .ready = state {
            // no need to set loading, simply update to new allowance value
        } else {
            state = .loading
        }

        let address = Address(raw: spenderAddress.hex) // todo
        allowanceTask = Task { [weak self] in
            do {
                let allowance = try await adapter.allowance(spenderAddress: address, defaultBlockParameter: .latest)

                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    self?.state = .ready(allowance: AppValue(token: token, value: allowance))
                }
            } catch {
                guard !Task.isCancelled else { return }

                await MainActor.run { [weak self] in
                    self?.state = .notReady(error: error)
                }
            }
        }
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
        case ready(allowance: AppValue)
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
