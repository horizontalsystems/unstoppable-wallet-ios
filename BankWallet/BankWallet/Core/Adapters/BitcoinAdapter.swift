import BitcoinKit
import BitcoinCore
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: BitcoinKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinKit = try BitcoinKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, minLogLevel: .error)

        super.init(abstractKit: bitcoinKit)

        bitcoinKit.delegate = self
    }

}

extension BitcoinAdapter: ISendBitcoinAdapter {
}

extension BitcoinAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try BitcoinKit.clear(exceptFor: excludedWalletIds)
    }

}
