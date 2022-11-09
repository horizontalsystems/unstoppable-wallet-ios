import RxSwift
import RxRelay
import PinKit

class MainBadgeService {
    private let disposeBag = DisposeBag()

    private let backupManager: BackupManager
    private let pinKit: IPinKit
    private let termsManager: TermsManager
    private let walletConnectV2SessionManager: WalletConnectV2SessionManager

    private let settingsBadgeRelay = BehaviorRelay<(Bool, Int)>(value: (false, 0))

    init(backupManager: BackupManager, pinKit: IPinKit, termsManager: TermsManager, walletConnectV2SessionManager: WalletConnectV2SessionManager) {
        self.backupManager = backupManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.walletConnectV2SessionManager = walletConnectV2SessionManager

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

        walletConnectV2SessionManager.pendingRequestsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

        syncSettingsBadge()
    }

    var settingsBadgeObservable: Observable<(Bool, Int)> {
        settingsBadgeRelay.asObservable()
    }

    private func syncSettingsBadge() {
        let count = walletConnectV2SessionManager.pendingRequests().count
        let visible = !backupManager.allBackedUp || !pinKit.isPinSet || !termsManager.termsAccepted || count != 0
        settingsBadgeRelay.accept((visible, count))
    }

}
