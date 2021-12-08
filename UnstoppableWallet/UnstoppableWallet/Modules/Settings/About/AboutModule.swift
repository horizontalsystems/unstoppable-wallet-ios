import UIKit

struct AboutModule {

    static func viewController() -> UIViewController {
        let service = AboutService(
                termsManager: App.shared.termsManager,
                systemInfoManager: App.shared.systemInfoManager,
                appConfigProvider: App.shared.appConfigProvider,
                rateAppManager: App.shared.rateAppManager
        )
        let releaseNotesService = ReleaseNotesService(appVersionManager: App.shared.appVersionManager)

        let viewModel = AboutViewModel(service: service, releaseNotesService: releaseNotesService)

        return AboutViewController(viewModel: viewModel, urlManager: UrlManager(inApp: true))
    }

}
