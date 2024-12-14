import UIKit

extension UIWindow {
    static var keyWindow: UIWindow? {
        let allScenes = UIApplication.shared.connectedScenes

        for scene in allScenes {
            guard let windowScene = scene as? UIWindowScene else {
                continue
            }

            for window in windowScene.windows where window.isKeyWindow {
                return window
            }
        }

        return nil
    }
}

extension UIScreen {
    static var currentSize: CGSize {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.screen.bounds.size
        }
        return UIScreen.main.bounds.size
    }
}
