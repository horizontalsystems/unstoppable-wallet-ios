import BitcoinCashKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: BitcoinCashKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinCashKit = try BitcoinCashKit(withWords: words, walletId: wallet.account.id, syncMode: .newWallet, networkType: networkType, minLogLevel: .error)

        super.init(abstractKit: bitcoinCashKit)

        bitcoinCashKit.delegate = self
    }

}

extension BitcoinCashAdapter {

    static func clear() throws {
        try BitcoinCashKit.clear()
    }

}

extension BitcoinCashAdapter: ISendBitcoinAdapter {
}
