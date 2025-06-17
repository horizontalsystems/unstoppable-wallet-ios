import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == .keyboard {
            // disable custom keyboards
            return false
        }
        return true
    }

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        Core.instance?.appManager.didReceive(url: url) ?? false
    }

    func application(_: UIApplication, continue userActivity: NSUserActivity, restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
            return Core.instance?.appManager.didReceive(url: url) ?? false
        }

        return false
    }
}
