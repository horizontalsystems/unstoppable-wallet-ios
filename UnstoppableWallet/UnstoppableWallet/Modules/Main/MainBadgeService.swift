import Combine
import RxRelay
import RxSwift

class MainBadgeService {
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let backupManager: BackupManager
    private let accountRestoreWarningManager: AccountRestoreWarningManager

    private let passcodeManager: PasscodeManager
    private let termsManager: TermsManager
    private let walletConnectSessionManager: WalletConnectSessionManager
    private let contactBookManager: ContactBookManager

    private let settingsBadgeRelay = BehaviorRelay<(Bool, Int)>(value: (false, 0))

    init(backupManager: BackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, passcodeManager: PasscodeManager, termsManager: TermsManager, walletConnectSessionManager: WalletConnectSessionManager, contactBookManager: ContactBookManager) {
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.passcodeManager = passcodeManager
        self.termsManager = termsManager
        self.walletConnectSessionManager = walletConnectSessionManager
        self.contactBookManager = contactBookManager

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

        passcodeManager.$isPasscodeSet
            .sink { [weak self] _ in
                self?.syncSettingsBadge()
            }
            .store(in: &cancellables)

        termsManager.$termsAccepted
            .sink { [weak self] _ in
                self?.syncSettingsBadge()
            }
            .store(in: &cancellables)

        walletConnectSessionManager.activePendingRequestsObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { [weak self] _ in
                self?.syncSettingsBadge()
            })
            .disposed(by: disposeBag)

        contactBookManager.iCloudErrorObservable
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
        let count = walletConnectSessionManager.activePendingRequests.count
        let cloudError = contactBookManager.iCloudError != nil && contactBookManager.remoteSync
        let visible = accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !passcodeManager.isPasscodeSet || !termsManager.termsAccepted || cloudError || count != 0
        settingsBadgeRelay.accept((visible, count))
    }
}
