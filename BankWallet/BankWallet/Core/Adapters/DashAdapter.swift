import DashKit
import RxSwift

class DashAdapter: BitcoinBaseAdapter {
    private let dashKit: DashKit
    private let feeRateProvider: IFeeRateProvider

    init(coin: Coin, authData: AuthData, newWallet: Bool, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        self.feeRateProvider = feeRateProvider

        let networkType: DashKit.NetworkType = testMode ? .testNet : .mainNet
        dashKit = try DashKit(withWords: authData.words, walletId: authData.walletId, newWallet: newWallet, networkType: networkType, minLogLevel: .error)

        super.init(coin: coin, abstractKit: dashKit, addressParser: addressParser)

        dashKit.delegate = self
    }

    override func feeRate(priority: FeeRatePriority) -> Int {
        return feeRateProvider.bitcoinFeeRate(for: priority)
    }

}
