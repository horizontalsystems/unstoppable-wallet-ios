import Combine
import Foundation
import RxSwift

class MainBadgeViewModel: ObservableObject {
    private let backupManager = Core.shared.backupManager
    private let accountRestoreWarningManager = Core.shared.accountRestoreWarningManager
    private let passcodeManager = Core.shared.passcodeManager
    private let termsManager = Core.shared.termsManager
    private let walletConnect = Core.shared.walletConnect
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

        termsManager.$state
            .sink { [weak self] _ in self?.syncSettingsBadge() }
            .store(in: &cancellables)

        walletConnect?.pendingRequestCountPublisher
            .sink { [weak self] _ in self?.syncSettingsBadge() }
            .store(in: &cancellables)

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
        let count = walletConnect?.pendingRequestCount ?? 0

        if count > 0 {
            return count.description
        }

        let cloudError = contactManager.iCloudError != nil && contactManager.remoteSync
        let visible = accountRestoreWarningManager.hasNonStandard || !backupManager.allBackedUp || !passcodeManager.isPasscodeSet || !termsManager.state.allAccepted || cloudError

        return visible ? "" : nil
    }

    private func syncSettingsBadge() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // Resolve on delivery: a queued snapshot can outlive the request's deadline.
            badge = resolvedBadge
        }
    }
}
