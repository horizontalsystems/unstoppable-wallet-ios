import Foundation
import RxSwift

class ReachabilityManager {
    let subject = PublishSubject<Bool>()

    init() {
    }
}

extension ReachabilityManager: IReachabilityManager {
}
