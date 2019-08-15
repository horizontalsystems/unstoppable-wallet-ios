import BitcoinKit
import BitcoinCore
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit
    override var receiveAddressScriptType: ScriptType { return .p2wpkhSh }
    override var changeAddressScriptType: ScriptType { return .p2wpkh }

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

extension BitcoinAdapter {

    static func clear() throws {
        try BitcoinKit.clear()
    }

}
