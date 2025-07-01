import Foundation
import SwiftUI

class AppSceneDelegate: NSObject, UIWindowSceneDelegate {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        let windowScene = scene as? UIWindowScene

        Core.shared.coverManager.windowScene = windowScene
        Core.shared.lockManager.windowScene = windowScene
    }

    func sceneDidEnterBackground(_: UIScene) {
        Core.shared.appManager.didEnterBackground()

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func sceneWillEnterForeground(_: UIScene) {
        Core.shared.appManager.willEnterForeground()

        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func sceneDidBecomeActive(_: UIScene) {
        Core.shared.appManager.didBecomeActive()
    }

    func sceneWillResignActive(_: UIScene) {
        Core.shared.appManager.willResignActive()
    }

    func scene(_: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            Core.instance?.appManager.didReceive(url: context.url)
        }
    }

    func scene(_: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            Core.instance?.appManager.didReceive(url: url)
        }
    }
}
