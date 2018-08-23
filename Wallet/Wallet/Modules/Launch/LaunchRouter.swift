import UIKit

class LaunchRouter {

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
//            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words))
//            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words, network: .testNet))
            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words, network: .regTest))

            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
