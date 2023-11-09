import UIKit

public protocol ActionSheetView: AnyObject {
    func contentWillDismissed()             //child viewController will start dismissing programmatically
    func dismissView(animated: Bool)       // child viewController can't get access to parentVC from iOS 5.*
    func didChangeHeight()               // Change height flicker for .sheet
}

public protocol ActionSheetViewDelegate: AnyObject {
    var actionSheetView: ActionSheetView? { get set }
    var height: CGFloat? { get }

    func didInteractiveDismissed()
}

extension ActionSheetViewDelegate {

    public var actionSheetView: ActionSheetView? {
        get { nil }
        set { ()  }
    }

    public var height: CGFloat? {
        nil
    }

    public func didInteractiveDismissed() {}
}
