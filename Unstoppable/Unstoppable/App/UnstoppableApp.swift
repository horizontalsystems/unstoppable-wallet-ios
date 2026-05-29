import SwiftUI
import WalletCore
import WidgetKit

@main
struct UnstoppableApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate

    private let initResult: Result<Void, Error>

    init() {
        #if DEV
            AppEnvironment.configure(.dev)
        #endif

        Theme.updateNavigationBarTheme() // TODO: get rid of this

        do {
            try Core.initApp(widgetRefresher: WidgetRefresher())

            Core.shared.appManager.didFinishLaunching()

            initResult = .success(())
        } catch {
            initResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch initResult {
            case .success:
                AppView()
            case let .failure(error):
                LaunchErrorView(error: error)
            }
        }
    }
}

struct WidgetRefresher: IWidgetRefresher {
    func refreshAll() {
        AppWidgetConstants.allKinds.forEach { WidgetCenter.shared.reloadTimelines(ofKind: $0) }
    }

    func refreshWatchlist() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppWidgetConstants.watchlistWidgetKind)
    }
}
