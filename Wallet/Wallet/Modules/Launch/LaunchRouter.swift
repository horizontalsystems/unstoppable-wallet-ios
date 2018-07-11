import Foundation
import WalletKit

class LaunchRouter {

    static func module() -> UIViewController {
        if Singletons.instance.walletManager.hasWallet {
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
