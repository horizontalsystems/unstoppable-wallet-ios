import Combine
import Foundation
import RxSwift

class MainBadgeViewModel: ObservableObject {
    private let backupManager = Core.shared.backupManager
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let passcodeManager = Core.shared.passcodeManager
    private let termsManager = Core.shared.termsManager
    private let walletConnectSessionManager = Core.shared.walletConnectSessionManager
    private let contactManager = Core.shared.contactManager

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    @Published private(set) var badge: String?

    init() {
        accountRestoreWarningManager.hasNonStandardPublisher
            .sink { [weak self] _ in self?.syncSettingsBadge() }
            .store(in: &cancellables)

        backupManager.allBackedUpObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { [weak self] _ in
                self?.syncSettingsBadge()
            })
            .disposed(by: disposeBag)

        passcodeManager.$isPasscodeSet
            .sink { [weak self] _ in self?.syncSettingsBadge() }
            .store(in: &cancellables)

        termsManager.$termsAccepted
            .sink { [weak self] _ in self?.syncSettingsBadge() }
            .store(in: &cancellables)

        walletConnectSessionManager.activePendingRequestsObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { [weak self] _ in
                self?.syncSettingsBadge()
            })
            .disposed(by: disposeBag)

        contactManager.iCloudErrorObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onNext: { [weak self] _ in
                self?.syncSettingsBadge()
            })
            .disposed(by: disposeBag)

        badge = resolvedBadge
    }

    private var resolvedBadge: String? {
        let count = walletConnectSessionManager.activePendingRequests.count

        if count > 0 {
            return count.description
        }

        let cloudError = contactManager.iCloudError != nil && contactManager.remoteSync
        let visible = accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !passcodeManager.isPasscodeSet || !termsManager.termsAccepted || cloudError

        return visible ? "" : nil
    }

    private func syncSettingsBadge() {
        let badge = resolvedBadge

        DispatchQueue.main.async {
            self.badge = badge
        }
    }
}
