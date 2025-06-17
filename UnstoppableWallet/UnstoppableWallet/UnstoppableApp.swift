import SwiftUI

@main
struct UnstoppableApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var scenePhase
    @State private var lastPhase: ScenePhase?
    @State private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private let initResult: Result<Void, Error>

    init() {
        Theme.updateNavigationBarTheme() // TODO: get rid of this

        do {
            try Core.initApp()

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
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                Core.shared.appManager.didEnterBackground()

                backgroundTask = UIApplication.shared.beginBackgroundTask {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = UIBackgroundTaskIdentifier.invalid
                }
            case .inactive:
                if lastPhase == .background {
                    Core.shared.appManager.willEnterForeground()
                } else {
                    Core.shared.appManager.willResignActive()
                }
            case .active:
                Core.shared.appManager.didBecomeActive()

                if backgroundTask != UIBackgroundTaskIdentifier.invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = UIBackgroundTaskIdentifier.invalid
                }
            @unknown default:
                break
            }

            lastPhase = phase
        }
    }
}
