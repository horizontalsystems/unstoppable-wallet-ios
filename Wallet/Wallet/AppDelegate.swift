import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

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
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        App.shared.lockManager.willEnterForeground()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}
