import Foundation

protocol IScanQrView: class {
    func start()
    func stop()
    func set(error: Error)
}

protocol IScanQrViewDelegate {
    func didScan(string: String)
    func onCancel()
}

protocol IScanQrRouter {
    func close()
}

protocol IScanQrModuleDelegate {
    func validate(string: String) throws
    func didScan(string: String)
}
