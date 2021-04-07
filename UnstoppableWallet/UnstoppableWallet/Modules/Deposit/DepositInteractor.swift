import CoinKit

class DepositInteractor {
    private let depositAdapter: IDepositAdapter
    private let pasteboardManager: IPasteboardManager

    init(depositAdapter: IDepositAdapter, pasteboardManager: IPasteboardManager) {
        self.depositAdapter = depositAdapter
        self.pasteboardManager = pasteboardManager
    }
}

extension DepositInteractor: IDepositInteractor {

    var address: String {
        depositAdapter.receiveAddress
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}
