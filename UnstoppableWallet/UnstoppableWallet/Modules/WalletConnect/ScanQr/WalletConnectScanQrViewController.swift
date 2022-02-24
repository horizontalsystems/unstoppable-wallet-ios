import ThemeKit

class WalletConnectScanQrViewController: ScanQrViewController {

    override func onScan(string: String) {
        delegate?.didScan(viewController: self, string: string)
    }

}

extension WalletConnectScanQrViewController: IWalletConnectErrorDelegate {

    func onDismiss() {
        startCaptureSession()
    }

}