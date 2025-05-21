import Combine
import ComponentKit
import HsExtensions
import RxSwift

class NoAccountWalletTokenListService: IWalletTokenListService {
    let reachabilityManager: IReachabilityManager
    let appSettingManager: AppSettingManager

    let balanceHiddenObservable: Observable<Bool> = Observable.just(false)
    let balanceHidden: Bool = false

    var state: WalletTokenListService.State = .noAccount
    var stateUpdatedPublisher: AnyPublisher<WalletTokenListService.State, Never> {
        Just(state).eraseToAnyPublisher()
    }

    init(reachabilityManager: IReachabilityManager, appSettingManager: AppSettingManager) {
        self.reachabilityManager = reachabilityManager
        self.appSettingManager = appSettingManager
    }
}

extension NoAccountWalletTokenListService {
    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    var balancePrimaryValueObservable: Observable<BalancePrimaryValue> {
        appSettingManager.balancePrimaryValueObservable
    }

    var balancePrimaryValue: BalancePrimaryValue {
        appSettingManager.balancePrimaryValue
    }

    var itemUpdatedObservable: Observable<WalletTokenListService.Item> {
        .never()
    }

    func item(element _: WalletModule.Element) -> WalletTokenListService.Item? {
        nil
    }
}
