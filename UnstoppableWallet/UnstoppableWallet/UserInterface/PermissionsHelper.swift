import UIKit
import AVFoundation

class PermissionsHelper {
    static let shared = PermissionsHelper()

    func performWithCameraPermission(fromController: UIViewController, action: @escaping () -> ()) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            action()
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        action()
                    } else {
                        self?.showPermissionAlert(fromController: fromController, message: "access_camera.message".localized(AppConfig.appName, AppConfig.appName))
                    }
                }
            })
        }
    }

    private func showPermissionAlert(fromController: UIViewController, title: String? = nil, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let settingsAction = UIAlertAction(title: "access_camera.settings".localized, style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alertController.addAction(settingsAction)
        alertController.addAction(UIAlertAction(title: "button.cancel".localized, style: .cancel))
        alertController.preferredAction = settingsAction

        alertController.show(fromController: fromController)
    }

}
