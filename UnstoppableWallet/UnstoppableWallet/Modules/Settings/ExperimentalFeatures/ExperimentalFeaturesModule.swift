import SwiftUI
import UIKit

struct ExperimentalFeaturesModule {

    static func viewController() -> UIViewController {
        let view = ExperimentalFeaturesView()

        let viewController = UIHostingController(rootView: view)
        viewController.title = "settings.experimental_features.title".localized

        return viewController
    }

}
