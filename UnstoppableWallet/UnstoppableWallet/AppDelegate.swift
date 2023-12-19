import ThemeKit
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Theme.updateNavigationBarTheme()

        window = ThemeWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        do {
            try App.initApp()
            App.instance?.appManager.didFinishLaunching()
            window?.rootViewController = LaunchModule.viewController()
        } catch {
            window?.rootViewController = LaunchErrorViewController(error: error)
        }

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        App.instance?.appManager.willResignActive()
    }

    func applicationDidBecomeActive(_: UIApplication) {
        App.instance?.appManager.didBecomeActive()
    }

    func applicationDidEnterBackground(_: UIApplication) {
        App.instance?.appManager.didEnterBackground()

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillEnterForeground(_: UIApplication) {
        App.instance?.appManager.willEnterForeground()

        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillTerminate(_: UIApplication) {
        App.instance?.appManager.willTerminate()
    }

    func application(_: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            // disable custom keyboards
            return false
        }
        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken _: Data) {}

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        App.instance?.appManager.didReceive(url: url) ?? false
    }

    func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            return App.instance?.appManager.didReceive(url: url) ?? false
        }

        return false
    }
}
