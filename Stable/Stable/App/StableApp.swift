import SwiftUI

@main
struct StableApp: App {
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .default

    private let initResult: Result<Void, Error>

    init() {
        do {
            try Core.initApp()

            // Core.shared.appManager.didFinishLaunching()

            initResult = .success(())
        } catch {
            initResult = .failure(error)
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                switch initResult {
                case .success:
                    AppView()
                case let .failure(error):
                    LaunchErrorView(error: error)
                }
            }
            .preferredColorScheme(theme.colorScheme)
        }
    }
}
