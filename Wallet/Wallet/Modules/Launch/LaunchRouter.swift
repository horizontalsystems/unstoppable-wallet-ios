import UIKit

class LaunchRouter {

    static func module(lock: Bool = true) -> UIViewController {
        if let words = WordsManager.shared.words {
            App.shared.lock()
            AdapterManager.shared.initAdapters(words: words)
            return MainRouter.module()
        } else {
            try? UnlockHelper.shared.store(pin: nil)
            return GuestRouter.module()
        }
    }

}
