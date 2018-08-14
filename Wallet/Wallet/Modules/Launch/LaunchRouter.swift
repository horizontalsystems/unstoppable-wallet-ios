import UIKit
import RealmSwift
import WalletKit

class LaunchRouter {

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words))

            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
