import RxSwift
import RxRelay
import PinKit

class MainBadgeService {
    private let disposeBag = DisposeBag()

    private let backupManager: BackupManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager

    private let pinKit: IPinKit
    private let termsManager: TermsManager

    private let settingsBadgeRelay = BehaviorRelay<Bool>(value: false)

    init(backupManager: BackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, pinKit: IPinKit, termsManager: TermsManager) {
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.pinKit = pinKit
        self.termsManager = termsManager

        accountRestoreWarningManager.hasNonStandardObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

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
        settingsBadgeRelay.accept(accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !pinKit.isPinSet || !termsManager.termsAccepted)
    }

}
