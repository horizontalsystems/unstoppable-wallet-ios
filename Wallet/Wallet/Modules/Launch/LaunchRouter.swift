import Foundation
import RealmSwift

class LaunchRouter {

    static func module() -> UIViewController {
        if Factory.instance.userDefaultsStorage.savedWords != nil && SyncUser.current != nil {
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
