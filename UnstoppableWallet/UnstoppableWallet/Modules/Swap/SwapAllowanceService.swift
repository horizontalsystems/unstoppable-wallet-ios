import Foundation
import EthereumKit
import RxSwift
import RxRelay

class SwapAllowanceService {
    private let spenderAddress: Address
    private let adapterManager: IAdapterManager

    private var coin: Coin?

    private var disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State?>()
    private(set) var state: State? {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(spenderAddress: Address, adapterManager: IAdapterManager) {
        self.spenderAddress = spenderAddress
        self.adapterManager = adapterManager
    }

}

extension SwapAllowanceService {

    var stateObservable: Observable<State?> {
        stateRelay.asObservable()
    }

    func set(coin: Coin?) {
        guard let coin = coin, let adapter = adapterManager.adapter(for: coin) as? IErc20Adapter else {
            state = nil
            return
        }

        self.coin = coin

        disposeBag = DisposeBag()

        state = .loading

        adapter
                .allowanceSingle(spenderAddress: spenderAddress)
                .subscribe(onSuccess: { [weak self] allowance in
                    self?.state = .ready(allowance: allowance)
                }, onError: { [weak self] error in
                    self?.state = .notReady(error: error)
                })
                .disposed(by: disposeBag)
    }

    func approveData(amount: Decimal) -> ApproveData? {
        guard case .ready(let allowance) = state else {
            return nil
        }

        guard let coin = coin else {
            return nil
        }

        return ApproveData(
                coin: coin,
                spenderAddress: spenderAddress,
                amount: amount,
                allowance: allowance
        )
    }

}

extension SwapAllowanceService {

    enum State {
        case loading
        case ready(allowance: Decimal)
        case notReady(error: Error)
    }

    struct ApproveData {
        let coin: Coin
        let spenderAddress: Address
        let amount: Decimal
        let allowance: Decimal
    }

}
