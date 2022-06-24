import HsToolKit
import RxSwift

class ReachabilityService {
    private let reachabilityManager: IReachabilityManager

    init(reachabilityManager: IReachabilityManager) {
        self.reachabilityManager = reachabilityManager
    }

    var isReachable: Bool {
        reachabilityManager.isReachable
    }

    var reachabilityObservable: Observable<Bool> {
        reachabilityManager.reachabilityObservable
    }

}
