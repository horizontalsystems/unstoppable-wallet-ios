import Foundation

class LaunchRouter {

    static func module() -> UIViewController {
        if Factory.instance.userDefaultsStorage.savedWords != nil {
            return MainRouter.module()
        } else {
            return GuestRouter.module()
        }
    }

}
