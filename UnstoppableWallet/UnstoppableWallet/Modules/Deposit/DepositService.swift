import MarketKit

class DepositService {
    private let wallet: WalletNew
    private let adapter: IDepositAdapter
    let address: String

    init(wallet: WalletNew, adapter: IDepositAdapter) {
        self.wallet = wallet
        self.adapter = adapter

        address = adapter.receiveAddress
    }
}

extension DepositService {

    var coin: Coin {
        wallet.coin
    }

    var isMainNet: Bool {
        adapter.isMainNet
    }

    var mnemonicDerivation: MnemonicDerivation? {
        wallet.coinSettings.derivation
    }

}
