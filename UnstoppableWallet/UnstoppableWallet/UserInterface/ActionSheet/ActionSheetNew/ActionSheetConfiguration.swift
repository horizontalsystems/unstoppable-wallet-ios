import Foundation
import UIKit

public class ActionSheetConfiguration {
    public var style: ActionStyleNew
    public var tapToDismiss: Bool = true
    
    public var ignoreInteractiveFalseMoving: Bool = true
    public var ignoreKeyboard: Bool = false
    public var focusFirstTextField: Bool = false
    
    public var coverBackgroundColor: UIColor = .init(white: 0, alpha: 0.5)
    
    public var presentAnimationDuration: TimeInterval = 0.3
    public var presentAnimationCurve: UIView.AnimationOptions = .init(rawValue: 5 << 16)
    public var dismissAnimationDuration: TimeInterval = 0.2
    public var dismissAnimationCurve: UIView.AnimationCurve = .easeIn
    
    public var contentBackgroundColor: UIColor = .clear
    public var sideMargin: CGFloat
    public var cornerRadius: CGFloat = 16
    public var corners: CACornerMask = .all
    
    public init(style: ActionStyleNew) {
        self.style = style
        
        switch style {
        case .alert:
            sideMargin = 52
        case .sheet:
            sideMargin = 0
        }
    }
    
    public func set(corners: CACornerMask) -> Self {
        self.corners = corners
        return self
    }
    
    public func set(ignoreKeyboard: Bool) -> Self {
        self.ignoreKeyboard = ignoreKeyboard
        return self
    }

    public func set(focusFirstTextField: Bool) -> Self {
        self.focusFirstTextField = focusFirstTextField
        return self
    }

    public func set(contentBackgroundColor: UIColor) -> Self {
        self.contentBackgroundColor = contentBackgroundColor
        return self
    }
}

extension CACornerMask {
    static let all: CACornerMask = [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
}
