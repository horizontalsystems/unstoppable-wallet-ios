import RxRelay
import RxSwift

class BitcoinHodlingService {
    private let localStorage: LocalStorage
    private let activatedChangedRelay = BehaviorRelay<Bool>(value: false)

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

}

extension BitcoinHodlingService: ISimpleActivateService {

    var activated: Bool {
        get {
            localStorage.lockTimeEnabled
        }
        set {
            localStorage.lockTimeEnabled = newValue
            activatedChangedRelay.accept(newValue)
        }
    }

    var activatedChangedObservable: Observable<Bool> {
        activatedChangedRelay.asObservable()
    }

    func toggle() {
        activated = !activated
    }

}
