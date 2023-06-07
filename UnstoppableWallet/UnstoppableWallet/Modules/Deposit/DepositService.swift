import MarketKit

class DepositService {
    private let wallet: Wallet
    let address: String

    init(wallet: Wallet, adapter: IDepositAdapter) {
        self.wallet = wallet

        address = adapter.receiveAddress.address
    }
}

extension DepositService {

    var coin: Coin {
        wallet.coin
    }

    var token: Token {
        wallet.token
    }

    var watchAccount: Bool {
        wallet.account.watchAccount
    }

}
