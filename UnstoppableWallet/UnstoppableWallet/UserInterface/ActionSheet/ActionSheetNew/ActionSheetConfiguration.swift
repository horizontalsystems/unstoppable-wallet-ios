import Foundation
import UIKit

public struct ActionSheetConfiguration {
    public var style: ActionStyleNew
    public var tapToDismiss: Bool = true

    public var ignoreInteractiveFalseMoving: Bool = true

    public var coverBackgroundColor: UIColor = UIColor(white: 0, alpha: 0.5)

    public var presentAnimationDuration: TimeInterval = 0.3
    public var presentAnimationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: 5 << 16)
    public var dismissAnimationDuration: TimeInterval = 0.2
    public var dismissAnimationCurve: UIView.AnimationCurve = .easeIn

    public var sideMargin: CGFloat
    public var cornerRadius: CGFloat = 16

    public init(style: ActionStyleNew) {
        self.style = style

        switch style {
        case .alert:
            sideMargin = 52
        case .sheet:
            sideMargin = 0
        }
    }

}
