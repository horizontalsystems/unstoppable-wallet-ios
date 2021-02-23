import Foundation
import EthereumKit
import RxSwift
import RxRelay
import CoinKit

class SwapAllowanceService {
    private let spenderAddress: EthereumKit.Address
    private let adapterManager: IAdapterManager

    private var coin: Coin?

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

    init(spenderAddress: EthereumKit.Address, adapterManager: IAdapterManager, evmKit: EthereumKit.Kit) {
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

        guard let coin = coin, let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
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
                    self?.state = .ready(allowance: CoinValue(coin: coin, value: allowance))
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

    func set(coin: Coin?) {
        self.coin = coin
        sync()
    }

    func approveData(dex: SwapModule.Dex, amount: Decimal) -> ApproveData? {
        guard case .ready(let allowance) = state else {
            return nil
        }

        guard let coin = coin else {
            return nil
        }

        return ApproveData(
                dex: dex,
                coin: coin,
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
        let coin: Coin
        let spenderAddress: EthereumKit.Address
        let amount: Decimal
        let allowance: Decimal
    }

}
