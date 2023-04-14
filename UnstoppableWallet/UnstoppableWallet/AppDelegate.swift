import UIKit
import ThemeKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        App.shared.appManager.didFinishLaunching()
        Theme.updateNavigationBarTheme()

        window = ThemeWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        window?.rootViewController = LaunchModule.viewController()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        App.shared.appManager.willResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        App.shared.appManager.didBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        App.shared.appManager.didEnterBackground()

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        App.shared.appManager.willEnterForeground()

        if backgroundTask != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskIdentifier.invalid
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        App.shared.appManager.willTerminate()
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            //disable custom keyboards
            return false
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        App.shared.appManager.didReceive(url: url)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> ()) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            return App.shared.appManager.didReceive(url: url)
        }

        return false
    }

}
