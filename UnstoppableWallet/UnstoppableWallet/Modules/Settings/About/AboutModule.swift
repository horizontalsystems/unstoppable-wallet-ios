import SwiftUI

struct AboutModule {
    static func view() -> some View {
        let releaseNotesService = ReleaseNotesService(appVersionManager: App.shared.appVersionManager)

        let viewModel = AboutViewModel(
            termsManager: App.shared.termsManager,
            systemInfoManager: App.shared.systemInfoManager,
            releaseNotesService: releaseNotesService
        )

        return AboutView(viewModel: viewModel)
    }
}
