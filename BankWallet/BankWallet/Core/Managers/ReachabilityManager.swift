import RxSwift
import Alamofire

class ReachabilityManager {
    let subject = PublishSubject<Bool>()

    let manager: NetworkReachabilityManager?

    init(appConfigProvider: IAppConfigProvider) {
        manager = NetworkReachabilityManager(host: appConfigProvider.reachabilityHost)

        manager?.listener = { [weak self] status in
            switch status {
            case .reachable:
                self?.subject.onNext(true)
            default:
                self?.subject.onNext(false)
            }
        }

        manager?.startListening()
    }
}

extension ReachabilityManager: IReachabilityManager {
}
