class BalanceErrorInteractor {
    private let pasteboardManager: IPasteboardManager
    private let adapterManager: IAdapterManager

    init(pasteboardManager: IPasteboardManager, adapterManager: IAdapterManager) {
        self.pasteboardManager = pasteboardManager
        self.adapterManager = adapterManager
    }

}

extension BalanceErrorInteractor: IBalanceErrorInteractor {

    func copyToClipboard(text: String) {
        pasteboardManager.set(value: text)
    }

    func refresh(wallet: Wallet) {
        adapterManager.refresh(wallet: wallet)
    }

}
