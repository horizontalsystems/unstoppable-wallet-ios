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
    private let walletConnectSessionManager: WalletConnectSessionManager
    private let contactBookManager: ContactBookManager

    private let settingsBadgeRelay = BehaviorRelay<(Bool, Int)>(value: (false, 0))

    init(backupManager: BackupManager, accountRestoreWarningManager: AccountRestoreWarningManager, pinKit: PinKit.Kit, termsManager: TermsManager, walletConnectSessionManager: WalletConnectSessionManager, contactBookManager: ContactBookManager) {
        self.backupManager = backupManager
        self.accountRestoreWarningManager = accountRestoreWarningManager
        self.pinKit = pinKit
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
        let visible = accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !pinKit.isPinSet || !termsManager.termsAccepted || cloudError || count != 0
        settingsBadgeRelay.accept((visible, count))
    }

}
