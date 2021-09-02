import Foundation
import EthereumKit
import RxSwift
import RxRelay
import MarketKit

class SwapAllowanceService {
    private let spenderAddress: EthereumKit.Address
    private let adapterManager: AdapterManagerNew

    private var platformCoin: PlatformCoin?

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

    init(spenderAddress: EthereumKit.Address, adapterManager: AdapterManagerNew, evmKit: EthereumKit.Kit) {
        self.spenderAddress = spenderAddress
        self.adapterManager = adapterManager

        evmKit.lastBlockHeightObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] blockNumber in
                    self?.sync()
                })
                .disposed(by: disposeBag)
    }

    private func sync() {
        allowanceDisposeBag = DisposeBag()

        guard let platformCoin = platformCoin, let adapter = adapterManager.adapter(for: platformCoin) as? IErc20Adapter else {
            state = nil
            return
        }

        if let state = state, case .ready = state {
            // no need to set loading, simply update to new allowance value
        } else {
            state = .loading
        }

        adapter
                .allowanceSingle(spenderAddress: spenderAddress, defaultBlockParameter: .latest)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.state = .ready(allowance: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: allowance))
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

    func set(platformCoin: PlatformCoin?) {
        self.platformCoin = platformCoin
        sync()
    }

    func approveData(dex: SwapModule.Dex, amount: Decimal) -> ApproveData? {
        guard case .ready(let allowance) = state else {
            return nil
        }

        guard let platformCoin = platformCoin else {
            return nil
        }

        return ApproveData(
                dex: dex,
                platformCoin: platformCoin,
                spenderAddress: spenderAddress,
                amount: amount,
                allowance: allowance.value
        )
    }

}

extension SwapAllowanceService {

    enum State: Equatable {
        case loading
        case ready(allowance: CoinValueNew)
        case notReady(error: Error)

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.ready(let lhsAllowance), .ready(let rhsAllowance)): return lhsAllowance == rhsAllowance
            default: return false
            }
        }
    }

    struct ApproveData {
        let dex: SwapModule.Dex
        let platformCoin: PlatformCoin
        let spenderAddress: EthereumKit.Address
        let amount: Decimal
        let allowance: Decimal
    }

}
