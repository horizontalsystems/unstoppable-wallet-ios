import Foundation
import WalletKit

class LaunchRouter {

    static func module() -> UIViewController {
        if WalletManager.shared.hasWallet {
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
