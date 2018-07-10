import Foundation
import RealmSwift

class LaunchRouter {

    static func module() -> UIViewController {
        if Factory.instance.userDefaultsStorage.savedWords != nil {
            Factory.instance.syncManager.performInitialSync()
//            Factory.instance.syncManager.check()
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
