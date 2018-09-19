import UIKit

class LaunchRouter {

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
            App.shared.lock()
            AdapterManager.shared.initAdapters(words: words)
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
