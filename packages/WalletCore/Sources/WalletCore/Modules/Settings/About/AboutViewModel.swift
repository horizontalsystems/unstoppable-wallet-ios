import Combine
import Foundation

class AboutViewModel: ObservableObject {
    private let systemInfoManager: SystemInfoManager
    private let releaseNotesService: ReleaseNotesService

    init(systemInfoManager: SystemInfoManager, releaseNotesService: ReleaseNotesService) {
        self.systemInfoManager = systemInfoManager
        self.releaseNotesService = releaseNotesService
    }

    var appVersion: String {
        systemInfoManager.appVersion.description
    }

    var releaseNotesUrl: URL? {
        releaseNotesService.lastVersionUrl
    }
}
