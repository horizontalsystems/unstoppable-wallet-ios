import Combine
import Foundation

class AboutViewModel: ObservableObject {
    private let termsManager: TermsManager
    private let systemInfoManager: SystemInfoManager
    private let releaseNotesService: ReleaseNotesService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var termsAlert = false

    init(termsManager: TermsManager, systemInfoManager: SystemInfoManager, releaseNotesService: ReleaseNotesService) {
        self.termsManager = termsManager
        self.systemInfoManager = systemInfoManager
        self.releaseNotesService = releaseNotesService

        termsManager.$state.sink { [weak self] in self?.syncTermsAlert(termsAccepted: $0.allAccepted) }.store(in: &cancellables)

        syncTermsAlert(termsAccepted: termsManager.state.allAccepted)
    }

    private func syncTermsAlert(termsAccepted: Bool) {
        termsAlert = !termsAccepted
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    var releaseNotesUrl: URL? {
        releaseNotesService.lastVersionUrl
    }
}
