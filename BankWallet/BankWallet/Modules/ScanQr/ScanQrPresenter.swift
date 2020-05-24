import Foundation

class ScanQrPresenter {
    private static let validationInterval: TimeInterval = 3

    weak var view: IScanQrView?

    private let router: IScanQrRouter

    private let timer: INotificationTimer
    private let delegate: IScanQrModuleDelegate

    init(router: IScanQrRouter, delegate: IScanQrModuleDelegate, timer: INotificationTimer) {
        self.router = router

        self.timer = timer
        self.delegate = delegate
    }

}

extension ScanQrPresenter: IScanQrViewDelegate {

    func didScan(string: String) {
        view?.stop()

        let result = delegate.didScan(string: string)

        guard case .error(let type) = result else {
            router.close()
            return
        }

        timer.start(interval: ScanQrPresenter.validationInterval)
        view?.set(error: type)
    }

}

extension ScanQrPresenter: INotificationTimerDelegate {

    func onFire() {
        view?.start()
    }

}
