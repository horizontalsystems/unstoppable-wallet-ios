import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        window?.backgroundColor = AppTheme.controllerBackground

        LaunchRouter.presenter(window: window).launch()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        App.shared.blurManager.willResignActive()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        App.shared.blurManager.didBecomeActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        App.shared.lockManager.didEnterBackground()

        backgroundTask = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskInvalid
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        App.shared.lockManager.willEnterForeground()

        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            //disable custom keyboards
            return false
        }
        return true
    }

}
