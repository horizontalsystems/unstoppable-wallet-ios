class WalletConnectScanQrViewModel {
    private let service: WalletConnectService

    init(service: WalletConnectService) {
        self.service = service
    }

    func didScan(string: String) {
        service.connect(string: string)
    }

}
