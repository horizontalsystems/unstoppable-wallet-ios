import UIKit
import RealmSwift
import WalletKit

class LaunchRouter {
    private static let realmFileName = "WalletKit.realm"

    static func module() -> UIViewController {
        if let words = WordsManager.shared.words {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            let configuration = Realm.Configuration(fileURL: documentsUrl?.appendingPathComponent(realmFileName))

            WalletKitManager.shared.configure(withWords: words, realmConfiguration: configuration)

            _ = WalletSyncer.shared

            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
