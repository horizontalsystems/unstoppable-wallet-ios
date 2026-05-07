import UIKit

public class HUDKeyboardHelper {
    public static let shared = HUDKeyboardHelper()

    public var lastNotification: Notification?
    weak var delegate: HUDKeyboardHelperDelegate?

    init() {
        registerKeyboardNotifications()
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardChangePosition), name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    public var visibleKeyboardHeight: CGFloat {
        var possibleKeyboardWindow: UIWindow?
        if UIApplication.shared.windows.count > 1, let window = UIApplication.shared.windows.max(by: { $0.windowLevel < $1.windowLevel }) {
            possibleKeyboardWindow = window
        }
        guard let keyboardWindow = possibleKeyboardWindow else {
            return 0
        }
        for possibleKeyboard in keyboardWindow.subviews {
            let viewName = String(describing: possibleKeyboard.classForCoder)
            if viewName.hasPrefix("UI") {
                if viewName.hasSuffix("PeripheralHostView") || viewName.hasSuffix("Keyboard") {
                    return possibleKeyboard.bounds.height
                } else if viewName.hasSuffix("InputSetContainerView") {
                    for possibleKeyboardSubview in possibleKeyboard.subviews {
                        let viewName = String(describing: possibleKeyboardSubview.classForCoder)
                        if viewName.hasPrefix("UI") || viewName.hasSuffix("InputSetHostView") {
                            let convertedRect: CGRect = possibleKeyboard.convert(possibleKeyboardSubview.frame, to: nil)
                            let intersectedRect = convertedRect.intersection(UIScreen.main.bounds)
                            return intersectedRect.height
                        }
                    }
                }
            }
        }
        return 0
    }

    func calculateKeyboardOffset(startOffset: CGFloat, viewBottom: CGFloat, onlyOnShow: Bool = false) -> CGFloat {
        var keyboardHeight: CGFloat = 0
        var keyboardOffset: CGFloat = onlyOnShow ? startOffset : 0

        if let notification = lastNotification,
           let keyboardInfo = notification.userInfo,
           let keyboardFrame = keyboardInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        {
            if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardDidShowNotification {
                keyboardHeight = keyboardFrame.height
            }
        } else {
            keyboardHeight = visibleKeyboardHeight
        }
        if viewBottom + keyboardHeight >= UIScreen.main.bounds.height {
            keyboardOffset = UIScreen.main.bounds.height - viewBottom - keyboardHeight
        }

        return keyboardOffset
    }

    // Keyboard Handler

    @objc func keyboardChangePosition(notification: Notification) {
        lastNotification = notification
        delegate?.keyboardDidChangePosition()
    }

    deinit {
        unregisterKeyboardNotifications()
    }
}

protocol HUDKeyboardHelperDelegate: AnyObject {
    func keyboardDidChangePosition()
}
