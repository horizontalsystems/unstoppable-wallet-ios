import ThemeKit

class WalletConnectScanQrViewController: ScanQrViewController {
    private let baseView: WalletConnectView

    init(baseView: WalletConnectView) {
        self.baseView = baseView

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func onScan(string: String) {
        baseView.viewModel.onScan(string: string)
    }

}
