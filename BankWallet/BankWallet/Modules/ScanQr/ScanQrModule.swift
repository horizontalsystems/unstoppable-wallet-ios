import Foundation

class ScanQrModule {
    enum Result {
        case success
        case error(type: ErrorType)
    }

    enum ErrorType {
        case address
    }

}

protocol IScanQrView: class {
    func start()
    func stop()
    func set(error: ScanQrModule.ErrorType)
}

protocol IScanQrViewDelegate {
    func didScan(string: String)
}

protocol IScanQrRouter {
    func close()
}

protocol INotificationTimer {
    func start(interval: TimeInterval)
}

protocol INotificationTimerDelegate: class {
    func onFire()
}

protocol IScanQrModuleDelegate {
    func didScan(string: String) -> ScanQrModule.Result
}
