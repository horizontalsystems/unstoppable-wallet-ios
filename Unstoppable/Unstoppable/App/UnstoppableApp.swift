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
            try Self.initCore()

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

    private static func initCore() throws {
        try Core.initApp(widgetRefresher: WidgetRefresher())

        EvmKitConfigFactory.register(UnstoppableEvmKitConfigProvider.self)

        Core.shared.appManager.didFinishLaunching()
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
