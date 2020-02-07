import UIKit
import ThemeKit

class InfoRouter {

    static func module(title: String, text: String) -> UIViewController {
        ThemeNavigationController(rootViewController: InfoViewController(title: title, text: text))
    }

}
