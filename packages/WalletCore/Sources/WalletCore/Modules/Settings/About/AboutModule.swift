import SwiftUI

enum AboutModule {
    static func view() -> some View {
        let releaseNotesService = Core.shared.releaseNotesService

        let viewModel = AboutViewModel(
            termsManager: Core.shared.termsManager,
            systemInfoManager: Core.shared.systemInfoManager,
            releaseNotesService: releaseNotesService
        )

        return AboutView(viewModel: viewModel)
    }
}
