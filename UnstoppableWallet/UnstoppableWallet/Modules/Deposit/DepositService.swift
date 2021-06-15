import CoinKit

class DepositService {
    private let activeWallet: ActiveWallet
    let address: String

    init(activeWallet: ActiveWallet, depositAdapter: IDepositAdapter) {
        self.activeWallet = activeWallet
        address = depositAdapter.receiveAddress
    }
}

extension DepositService {

    var coin: Coin {
        activeWallet.wallet.coin
    }

    var isMainNet: Bool {
        activeWallet.isMainNet
    }

    var mnemonicDerivation: MnemonicDerivation? {
        activeWallet.wallet.configuredCoin.settings.derivation
    }

}
