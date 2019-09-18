import BitcoinKit
import BitcoinCore
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit

    init(wallet: Wallet, testMode: Bool) throws {
        guard case let .mnemonic(words, derivation, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: BitcoinKit.NetworkType = testMode ? .testNet : .mainNet
        let bip = BitcoinAdapter.bip(from: derivation)
        let syncMode = BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast)

        bitcoinKit = try BitcoinKit(withWords: words, bip: bip, walletId: wallet.account.id, syncMode: syncMode, networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.defaultConfirmationsThreshold, minLogLevel: .error)

        super.init(abstractKit: bitcoinKit)

        bitcoinKit.delegate = self
    }

}

extension BitcoinAdapter {
    
    private static func bip(from derivation: MnemonicDerivation) -> Bip {
        switch derivation {
        case .bip44: return Bip.bip44
        case .bip49: return Bip.bip49
        }
    }
    
}

extension BitcoinAdapter: ISendBitcoinAdapter {
}

extension BitcoinAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try BitcoinKit.clear(exceptFor: excludedWalletIds)
    }

}
