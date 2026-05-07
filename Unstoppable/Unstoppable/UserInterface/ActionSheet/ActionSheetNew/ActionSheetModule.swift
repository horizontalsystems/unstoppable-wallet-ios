import UIKit

public protocol IActionSheetView: AnyObject {
    func contentWillDismissed() // child viewController will start dismissing programmatically
    func dismissView(animated: Bool) // child viewController can't get access to parentVC from iOS 5.*
    func didChangeHeight() // Change height flicker for .sheet
}

public protocol ActionSheetViewDelegate: AnyObject {
    var actionSheetView: IActionSheetView? { get set }
    var height: CGFloat? { get }

    func didInteractiveDismissed()
}

public extension ActionSheetViewDelegate {
    var actionSheetView: IActionSheetView? {
        get { nil }
        set { () }
    }

    var height: CGFloat? {
        nil
    }

    func didInteractiveDismissed() {}
}
