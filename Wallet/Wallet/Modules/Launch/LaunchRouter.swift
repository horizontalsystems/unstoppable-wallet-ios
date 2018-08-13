import UIKit
import RealmSwift
import WalletKit

class LaunchRouter {
    private static let realmFileName = "WalletKit.realm"

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let configuration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

            let walletKit = WalletKit(withWords: words, realmConfiguration: configuration)

            WalletSyncer.shared.walletKit = walletKit

            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
