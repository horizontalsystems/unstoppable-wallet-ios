import Foundation

class ScanQrPresenter {
    private let validationInterval: TimeInterval = 3

    weak var view: IScanQrView?

    private let router: IScanQrRouter

    private let delegate: IScanQrModuleDelegate

    init(router: IScanQrRouter, delegate: IScanQrModuleDelegate) {
        self.router = router

        self.delegate = delegate
    }

}

extension ScanQrPresenter: IScanQrViewDelegate {

    func didScan(string: String) {
        view?.stop()
        delegate.didScan(string: string)
        router.close()
    }

    func onCancel() {
        router.close()
    }

}
