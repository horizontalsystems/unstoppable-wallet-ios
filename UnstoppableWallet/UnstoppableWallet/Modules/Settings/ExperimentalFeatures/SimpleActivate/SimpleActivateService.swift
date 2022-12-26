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

class TestNetActivateService {
    private let testNetManager: TestNetManager
    private let activatedChangedRelay = BehaviorRelay<Bool>(value: false)

    init(testNetManager: TestNetManager) {
        self.testNetManager = testNetManager
    }

}

extension TestNetActivateService: ISimpleActivateService {

    var activated: Bool {
        get {
            testNetManager.testNetEnabled
        }
        set {
            testNetManager.testNetEnabled = newValue
        }
    }

    var activatedChangedObservable: Observable<Bool> {
        testNetManager.testNetEnabledObservable
    }

    func toggle() {
        activated = !activated
    }

}
