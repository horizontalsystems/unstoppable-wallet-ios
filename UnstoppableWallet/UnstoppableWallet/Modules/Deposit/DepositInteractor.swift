class DepositInteractor {
    private let depositAdapter: IDepositAdapter
    private let derivationSettingsManager: IDerivationSettingsManager
    private let pasteboardManager: IPasteboardManager

    init(depositAdapter: IDepositAdapter, derivationSettingsManager: IDerivationSettingsManager, pasteboardManager: IPasteboardManager) {
        self.depositAdapter = depositAdapter
        self.derivationSettingsManager = derivationSettingsManager
        self.pasteboardManager = pasteboardManager
    }
}

extension DepositInteractor: IDepositInteractor {

    var address: String {
        depositAdapter.receiveAddress
    }

    func derivationSetting(coinType: CoinType) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coinType)
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}
