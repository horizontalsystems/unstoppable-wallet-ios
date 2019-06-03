import BitcoinKit
import RxSwift

class BitcoinAdapter: BitcoinBaseAdapter {
    private let bitcoinKit: BitcoinKit
    private let feeRateProvider: IFeeRateProvider

    init(coin: Coin, authData: AuthData, newWallet: Bool, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        self.feeRateProvider = feeRateProvider

        let networkType: BitcoinKit.NetworkType = testMode ? .testNet : .mainNet
        bitcoinKit = try BitcoinKit(withWords: authData.words, walletId: authData.walletId, newWallet: newWallet, networkType: networkType, minLogLevel: .error)

        super.init(coin: coin, abstractKit: bitcoinKit, addressParser: addressParser)

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
