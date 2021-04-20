import UIKit

private var window: UIWindow!

extension UIAlertController {

    public static func showSimpleAlert(fromController: UIViewController? = nil, title: String? = nil, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let ok = UIAlertAction(title: "button.ok".localized, style: .cancel, handler:nil)
        alert.addAction(ok)

        alert.show(forView: nil, barButtonItem: nil, fromController: fromController, sourceRect: nil)
    }

    public func show(forView view: UIView? = nil, barButtonItem: UIBarButtonItem? = nil, fromController: UIViewController? = nil, sourceRect: CGRect? = nil) {
        if fromController != nil, let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            fromController?.view.endEditing(true)
            window = keyWindow
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)

            window.rootViewController = UIViewController()
            window.isHidden = false
        }

        popoverPresentationController?.sourceView = view ?? window
        if let rect = sourceRect {
            popoverPresentationController?.sourceRect = rect
        }
        popoverPresentationController?.barButtonItem = barButtonItem

        if let fromController = fromController {
            fromController.present(self, animated: true)
        } else {
            window.rootViewController?.present(self, animated: true, completion: nil)
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        window = nil
    }

}
