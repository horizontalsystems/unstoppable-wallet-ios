import RxSwift
import RxRelay
import PinKit

class MainBadgeService {
    private let disposeBag = DisposeBag()

    private let backupManager: IBackupManager
    private let pinKit: IPinKit
    private let termsManager: ITermsManager

    private let settingsBadgeRelay = BehaviorRelay<Bool>(value: false)

    init(backupManager: IBackupManager, pinKit: IPinKit, termsManager: ITermsManager) {
        self.backupManager = backupManager
        self.pinKit = pinKit
        self.termsManager = termsManager

        backupManager.allBackedUpObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

        pinKit.isPinSetObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

        termsManager.termsAcceptedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

        syncSettingsBadge()
    }

    var settingsBadgeObservable: Observable<Bool> {
        settingsBadgeRelay.asObservable()
    }

    private func syncSettingsBadge() {
        settingsBadgeRelay.accept(!backupManager.allBackedUp || !pinKit.isPinSet || !termsManager.termsAccepted)
    }

}
