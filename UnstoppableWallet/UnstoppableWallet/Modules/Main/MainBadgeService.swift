import Combine
import RxSwift
import RxRelay
import PinKit

class MainBadgeService {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let backupManager: BackupManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager

    private let pinKit: PinKit.Kit
    private let termsManager: TermsManager
    private let walletConnectV2SessionManager: WalletConnectV2SessionManager

    private let settingsBadgeRelay = BehaviorRelay<(Bool, Int)>(value: (false, 0))

    init(backupManager: BackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, pinKit: PinKit.Kit, termsManager: TermsManager, walletConnectV2SessionManager: WalletConnectV2SessionManager) {
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.pinKit = pinKit
        self.termsManager = termsManager
        self.walletConnectV2SessionManager = walletConnectV2SessionManager

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

        pinKit.isPinSetPublisher
                .sink { [weak self] _ in
                    self?.syncSettingsBadge()
                }
                .store(in: &cancellables)

        termsManager.termsAcceptedObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncSettingsBadge()
                })
                .disposed(by: disposeBag)

        walletConnectV2SessionManager.activePendingRequestsObservable
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
        let count = walletConnectV2SessionManager.activePendingRequests.count
        let visible = accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !pinKit.isPinSet || !termsManager.termsAccepted || count != 0
        settingsBadgeRelay.accept((visible, count))
    }

}
