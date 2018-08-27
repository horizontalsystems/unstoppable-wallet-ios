import UIKit

class LaunchRouter {

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
//            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words))
//            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words, networkType: .testNet))
            AdapterManager.shared.add(adapter: BitcoinAdapter(words: words, networkType: .regTest))
//            AdapterManager.shared.add(adapter: BitcoinAdapter(words: ["black", "correct", "snap", "west", "clever", "knock", "honey", "head", "divide", "admit", "file", "swarm"], networkType: .regTest))

            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
