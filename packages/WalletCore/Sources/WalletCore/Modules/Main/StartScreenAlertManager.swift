import Combine
import Foundation

class StartScreenAlertManager {
    private var cancellables = Set<AnyCancellable>()
    private var isPresentingLostAccounts = false

    let accountManager: AccountManager
    let jailbreakService: JailbreakService
    let lockManager: LockManager
    let releaseNotesService: ReleaseNotesService
    let deeplinkManager: DeepLinkManager
    let deeplinkStorage: DeeplinkStorage

    init(accountManager: AccountManager, lockManager: LockManager, jailbreakService: JailbreakService, releaseNotesService: ReleaseNotesService, deeplinkManager: DeepLinkManager, deeplinkStorage: DeeplinkStorage) {
        self.accountManager = accountManager
        self.lockManager = lockManager
        self.jailbreakService = jailbreakService
        self.releaseNotesService = releaseNotesService
        self.deeplinkManager = deeplinkManager
        self.deeplinkStorage = deeplinkStorage

        lockManager.$isLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNextAlert() }
            .store(in: &cancellables)

        accountManager.$lostAccountRecords
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.handleNextAlert() }
            .store(in: &cancellables)

        deeplinkStorage.$deepLinkUrl
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deeplinkUrl in
                guard deeplinkUrl != nil else {
                    return
                }

                self?.handleNextAlert()
            }
            .store(in: &cancellables)

        handleNextAlert()
    }

    func handleNextAlert() {
        guard !lockManager.isLocked, !isPresentingLostAccounts else {
            return
        }

        if let releaseNotesUrl = releaseNotesService.releaseNotesUrl {
            Coordinator.shared.present { _ in
                MarkdownModule.gitReleaseNotesMarkdownView(url: releaseNotesUrl, presented: true).ignoresSafeArea()
            } onDismiss: { [weak self] in
                self?.handleNextAlert()
            }
        } else if let records = accountManager.lostAccountRecords {
            isPresentingLostAccounts = true
            Coordinator.shared.present(type: .bottomSheet) { [accountManager] isPresented in
                AccountsLostView(records: records, isPresented: isPresented) {
                    try accountManager.removeLostAccounts(ids: Set(records.map(\.id)))
                }
            } onDismiss: { [weak self] in
                self?.accountManager.lostAccountRecords = nil
                self?.isPresentingLostAccounts = false
            }
        } else if jailbreakService.needToShowAlert {
            Coordinator.shared.present { isPresented in
                JailbreakView(isPresented: isPresented)
            } onDismiss: { [weak self] in
                self?.handleNextAlert()
            }

            jailbreakService.setAlertShown()
        } else if let deeplinkUrl = deeplinkStorage.deepLinkUrl {
            deeplinkManager.handle(url: deeplinkUrl)

            deeplinkStorage.deepLinkUrl = nil
        }
    }
}
