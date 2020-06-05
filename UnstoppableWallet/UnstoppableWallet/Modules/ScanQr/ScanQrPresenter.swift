import Foundation

class ScanQrPresenter {
    private let validationInterval: TimeInterval = 3

    weak var view: IScanQrView?

    private let router: IScanQrRouter

    private var timer: Timer?
    private let delegate: IScanQrModuleDelegate

    init(router: IScanQrRouter, delegate: IScanQrModuleDelegate) {
        self.router = router

        self.delegate = delegate
    }

    deinit {
        timer?.invalidate()
    }

    @objc private func onFire() {
        view?.start()
    }

    private func startTimer() {
        timer?.invalidate()

        timer = Timer(fireAt: Date(timeIntervalSinceNow: validationInterval), interval: 0, target: self, selector: #selector(onFire), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

}

extension ScanQrPresenter: IScanQrViewDelegate {

    func didScan(string: String) {
        view?.stop()

        do {
            try delegate.validate(string: string)

            delegate.didScan(string: string)
            router.close()
        } catch {
            startTimer()
            view?.set(error: error.convertedError)
        }
    }

    func onCancel() {
        router.close()
    }

}
