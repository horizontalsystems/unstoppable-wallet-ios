import RxSwift

class BiometryManager: IBiometryManager {
    private let disposeBag = DisposeBag()

    var biometryType: BiometryType = .none

    init(systemInfoManager: ISystemInfoManager) {
        systemInfoManager.biometryType
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] biometryType in
                    self?.biometryType = biometryType
                })
                .disposed(by: disposeBag)
    }

}
