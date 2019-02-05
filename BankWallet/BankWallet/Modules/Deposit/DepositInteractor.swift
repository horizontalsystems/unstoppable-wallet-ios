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

    func adapters(forCoin coinCode: CoinCode?) -> [IAdapter] {
        return adapterManager.adapters.filter { coinCode == nil || coinCode == $0.coin.code }
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

}
