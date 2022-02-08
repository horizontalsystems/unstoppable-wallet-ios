import ThemeKit

class WalletConnectXScanQrViewController: ScanQrViewController {

    override func onScan(string: String) {
        delegate?.didScan(viewController: self, string: string)
    }

}

extension WalletConnectXScanQrViewController: IWalletConnectErrorDelegate {

    func onDismiss() {
        startCaptureSession()
    }

}