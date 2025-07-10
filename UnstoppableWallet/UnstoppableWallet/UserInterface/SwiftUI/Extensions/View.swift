import SwiftUI
import UIKit

extension View {
    func toViewController(title: String? = nil) -> UIViewController {
        let viewController = UIHostingController(rootView: self)

        if let title {
            viewController.title = title
        }

        return viewController
    }

    func toBottomSheetViewController(title: String? = nil) -> UIViewController {
        let viewController = UIHostingController(rootView: self)

        if let title {
            viewController.title = title
        }

        viewController.view.backgroundColor = .themeLawrence

        return viewController
    }

    func toNavigationViewController() -> UIViewController {
        UIHostingController(rootView: ThemeNavigationStack { self })
    }
}

extension UIView {
    static func firstSubview<T>(in view: UIView) -> T? {
        if let viewT = view as? T {
            return viewT
        }

        for subview in view.subviews {
            if let viewT: T = firstSubview(in: subview) {
                return viewT
            }
        }

        return nil
    }
}
