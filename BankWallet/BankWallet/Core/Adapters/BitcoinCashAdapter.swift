import BitcoinCashKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit
    private let feeRateProvider: IFeeRateProvider

    init(wallet: Wallet, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        self.feeRateProvider = feeRateProvider

        let networkType: BitcoinCashKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinCashKit = try BitcoinCashKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, minLogLevel: .error)

        super.init(wallet: wallet, abstractKit: bitcoinCashKit, addressParser: addressParser)

        bitcoinCashKit.delegate = self
    }

    override func feeRate(priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinCashFeeRate(for: priority)
    }

}

extension BitcoinCashAdapter {

    static func clear() throws {
        try BitcoinCashKit.clear()
    }

}
