import UIKit

class InfoRouter {

    static func module(title: String, text: String) -> UIViewController {
        WalletNavigationController(rootViewController: InfoViewController(title: title, text: text))
    }

}
