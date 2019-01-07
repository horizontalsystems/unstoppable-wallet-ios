import RxSwift
import Alamofire

class ReachabilityManager {
    let subject = PublishSubject<Bool>()

    let manager: NetworkReachabilityManager?

    private let subjectNew: OptionalSubject<Bool>

    init(appConfigProvider: IAppConfigProvider) {
        manager = NetworkReachabilityManager(host: appConfigProvider.reachabilityHost)

        subjectNew = OptionalSubject(initialValue: manager?.isReachable ?? false)

        manager?.listener = { [weak self] status in
            switch status {
            case .reachable:
                self?.subject.onNext(true)

                if let value = self?.subjectNew.value, !value {
                    self?.subjectNew.onNext(true)
                }
            default:
                self?.subject.onNext(false)

                if let value = self?.subjectNew.value, value {
                    self?.subjectNew.onNext(false)
                }
            }
        }

        manager?.startListening()
    }
}

extension ReachabilityManager: IReachabilityManager {

    var stateObservable: Observable<Bool> {
        return subjectNew.asObservable()
    }

}
