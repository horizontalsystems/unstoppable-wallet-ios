import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let pasteboardManager: IPasteboardManager
    private let blockchainSettingsManager: ICoinSettingsManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, pasteboardManager: IPasteboardManager, blockchainSettingsManager: ICoinSettingsManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.pasteboardManager = pasteboardManager
        self.blockchainSettingsManager = blockchainSettingsManager
    }
}

extension DepositInteractor: IDepositInteractor {

    func wallets() -> [Wallet] {
        walletManager.wallets
    }

    func adapter(forWallet wallet: Wallet) -> IDepositAdapter? {
        adapterManager.depositAdapter(for: wallet)
    }

    func copy(address: String) {
        pasteboardManager.set(value: address)
    }

    func blockchainSettings(coinType: CoinType) -> BlockchainSetting? {
        blockchainSettingsManager.settings(coinType: coinType)
    }

}
