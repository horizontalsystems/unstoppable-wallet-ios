import BitcoinCashKit
import RxSwift

class BitcoinCashAdapter: BitcoinBaseAdapter {
    private let bitcoinCashKit: BitcoinCashKit
    private let feeRateProvider: IFeeRateProvider

    init(coin: Coin, authData: AuthData, newWallet: Bool, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        self.feeRateProvider = feeRateProvider

        let networkType: BitcoinCashKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinCashKit = try BitcoinCashKit(withWords: authData.words, walletId: authData.walletId, newWallet: newWallet, networkType: networkType, minLogLevel: .error)

        super.init(coin: coin, abstractKit: bitcoinCashKit, addressParser: addressParser)

        bitcoinCashKit.delegate = self
    }

    override func feeRate(priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinCashFeeRate(for: priority)
    }

}
