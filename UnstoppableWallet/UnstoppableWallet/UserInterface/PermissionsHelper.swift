import AVFoundation

enum PermissionsHelper {
    static func performWithCameraPermission(onComplete: @escaping (Bool) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized {
            onComplete(true)
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { granted in
                DispatchQueue.main.async {
                    if granted {
                        onComplete(true)
                    } else {
                        onComplete(false)
                    }
                }
            })
        }
    }
}
