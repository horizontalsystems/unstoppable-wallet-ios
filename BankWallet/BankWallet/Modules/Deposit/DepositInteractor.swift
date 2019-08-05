import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let adapterManager: IAdapterManager
    private let pasteboardManager: IPasteboardManager

    init(adapterManager: IAdapterManager, pasteboardManager: IPasteboardManager) {
        self.adapterManager = adapterManager
        self.pasteboardManager = pasteboardManager
    }
}

extension DepositInteractor: IDepositInteractor {

    func adapters(forCoin coin: Coin?) -> [IAdapter] {
        return adapterManager.adapters.filter { coin == nil || coin == $0.wallet.coin }
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}
