import BitcoinKit
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit
    private let feeRateProvider: IFeeRateProvider

    init(wallet: Wallet, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        self.feeRateProvider = feeRateProvider

        let networkType: BitcoinKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinKit = try BitcoinKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, minLogLevel: .error)

        super.init(wallet: wallet, abstractKit: bitcoinKit, addressParser: addressParser)

        bitcoinKit.delegate = self
    }

    override func feeRate(priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinFeeRate(for: priority)
    }

    override var receiveAddress: String {
        return bitcoinKit.receiveAddress(for: .p2wpkhSh)
    }

}

extension BitcoinAdapter {

    static func clear() throws {
        try BitcoinKit.clear()
    }

}
