import UIKit

enum ModuleStartMode {
    case push(navigationController: UINavigationController?)
    case present(viewController: UIViewController?)
}
