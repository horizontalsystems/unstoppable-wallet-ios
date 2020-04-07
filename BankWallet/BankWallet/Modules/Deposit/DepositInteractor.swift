import UIKit

class DepositInteractor {
    weak var delegate: IDepositInteractorDelegate?

    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let pasteboardManager: IPasteboardManager
    private let derivationSettingsManager: IDerivationSettingsManager

    init(walletManager: IWalletManager, adapterManager: IAdapterManager, pasteboardManager: IPasteboardManager, derivationSettingsManager: IDerivationSettingsManager) {
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.pasteboardManager = pasteboardManager
        self.derivationSettingsManager = derivationSettingsManager
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

    func derivationSettings(coinType: CoinType) -> DerivationSetting? {
        derivationSettingsManager.setting(coinType: coinType)
    }

}
