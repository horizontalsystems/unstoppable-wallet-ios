import Combine
import ComponentKit
import HsExtensions
import RxSwift

class NoAccountWalletTokenListService: IWalletTokenListService {
    let reachabilityManager: IReachabilityManager
    let balancePrimaryValueManager: BalancePrimaryValueManager

    let balanceHiddenObservable: Observable<Bool> = Observable.just(false)
    let balanceHidden: Bool = false

    var state: WalletTokenListService.State = .noAccount
    var stateUpdatedPublisher: AnyPublisher<WalletTokenListService.State, Never> {
        Just(state).eraseToAnyPublisher()
    }

    init(reachabilityManager: IReachabilityManager, balancePrimaryValueManager: BalancePrimaryValueManager) {
        self.reachabilityManager = reachabilityManager
        self.balancePrimaryValueManager = balancePrimaryValueManager
    }
}

extension NoAccountWalletTokenListService {
    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        balancePrimaryValueManager.balancePrimaryValueObservable
    }

    var balancePrimaryValue: BalancePrimaryValue {
        balancePrimaryValueManager.balancePrimaryValue
    }

    var itemUpdatedObservable: Observable<WalletTokenListService.Item> {
        .never()
    }

    func item(element _: WalletModule.Element) -> WalletTokenListService.Item? {
        nil
    }
}
