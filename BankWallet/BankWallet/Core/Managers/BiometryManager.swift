import RxSwift

class BiometryManager: IBiometryManager {
    private let disposeBag = DisposeBag()

    private let systemInfoManager: ISystemInfoManager
    private let subject = PublishSubject<BiometryType>()

    var biometryType: BiometryType = .none {
        didSet {
            if oldValue != biometryType {
                subject.onNext(biometryType)
            }
        }
    }

    init(systemInfoManager: ISystemInfoManager) {
        self.systemInfoManager = systemInfoManager
    }

    var biometryTypeObservable: Observable<BiometryType> {
        return subject.asObservable()
    }

    func refresh() {
        systemInfoManager.biometryType
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] biometryType in
                    self?.biometryType = biometryType
                })
                .disposed(by: disposeBag)
    }

}
