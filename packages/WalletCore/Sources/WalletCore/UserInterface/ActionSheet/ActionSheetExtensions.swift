import SwiftUI
import UIKit

public extension UIViewController {
    var toBottomSheet: UIViewController {
        ActionSheetControllerNew(content: self, configuration: ActionSheetConfiguration(style: .sheet))
    }

    var toAlert: UIViewController {
        ActionSheetControllerNew(content: self, configuration: ActionSheetConfiguration(style: .alert))
    }

    func toActionSheet(configuration: ActionSheetConfiguration) -> UIViewController {
        ActionSheetControllerNew(content: self, configuration: configuration)
    }
}
