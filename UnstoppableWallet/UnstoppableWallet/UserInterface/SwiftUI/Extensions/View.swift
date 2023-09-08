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

    func toNavigationViewController() -> UIViewController {
        UIHostingController(rootView: ThemeNavigationView { self })
    }
}
