import UIKit

class LaunchRouter {

    static func module(lock: Bool = true) -> UIViewController {
        if let words = WordsManager.shared.words {
            LockManager.shared.lock()
            AdapterManager.shared.initAdapters(words: words)
            return MainRouter.module()
        } else {
            try? PinManager.shared.store(pin: nil)
            return GuestRouter.module()
        }
    }

}
