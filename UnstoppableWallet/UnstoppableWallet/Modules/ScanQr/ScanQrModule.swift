import Foundation

protocol IScanQrView: class {
    func start()
    func stop()
}

protocol IScanQrViewDelegate {
    func didScan(string: String)
    func onCancel()
}

protocol IScanQrRouter {
    func close()
}

protocol IScanQrModuleDelegate {
    func didScan(string: String)
}
