import MarketKit

class DepositService {
    private let wallet: Wallet
    private let adapter: IDepositAdapter
    let address: String

    init(wallet: Wallet, adapter: IDepositAdapter) {
        self.wallet = wallet
        self.adapter = adapter

        address = adapter.receiveAddress
    }
}

extension DepositService {

    var coin: Coin {
        wallet.coin
    }

    var coinType: CoinType {
        wallet.coinType
    }

    var isMainNet: Bool {
        adapter.isMainNet
    }

    var mnemonicDerivation: MnemonicDerivation? {
        wallet.coinSettings.derivation
    }

}
