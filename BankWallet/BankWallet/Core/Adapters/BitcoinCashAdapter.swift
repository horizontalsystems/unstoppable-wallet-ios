import BitcoinCashKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: BitcoinCashKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinCashKit = try BitcoinCashKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.defaultConfirmationsThreshold, minLogLevel: .error)

        super.init(abstractKit: bitcoinCashKit)

        bitcoinCashKit.delegate = self
    }

}

extension BitcoinCashAdapter: ISendBitcoinAdapter {
}

extension BitcoinCashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try BitcoinCashKit.clear(exceptFor: excludedWalletIds)
    }

}
