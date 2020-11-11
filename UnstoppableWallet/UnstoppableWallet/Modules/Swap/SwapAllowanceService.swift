import Foundation
import EthereumKit
import RxSwift
import RxRelay

class SwapAllowanceService {
    private let spenderAddress: Address
    private let adapterManager: IAdapterManager

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

}

extension SwapAllowanceService {

    enum State {
        case loading
        case ready(allowance: Decimal)
        case notReady(error: Error)
    }

}
