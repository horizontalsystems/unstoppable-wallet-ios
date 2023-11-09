import UIKit
import SwiftUI

extension UIViewController {

    public var toBottomSheet: UIViewController {
        ActionSheetControllerNew(content: self, configuration: ActionSheetConfiguration(style: .sheet))
    }

    public var toAlert: UIViewController {
        ActionSheetControllerNew(content: self, configuration: ActionSheetConfiguration(style: .alert))
    }

    public func toActionSheet(configuration: ActionSheetConfiguration) -> UIViewController {
        ActionSheetControllerNew(content: self, configuration: configuration)
    }

}
