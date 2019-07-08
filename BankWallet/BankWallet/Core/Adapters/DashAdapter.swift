import DashKit
import RxSwift

class DashAdapter: BitcoinBaseAdapter {
    private let dashKit: DashKit
    private let feeRateProvider: IFeeRateProvider

    init(wallet: Wallet, addressParser: IAddressParser, feeRateProvider: IFeeRateProvider, testMode: Bool) throws {
        guard case let .mnemonic(words, _, _) = wallet.account.type else {
            throw AdapterError.unsupportedAccount
        }

        self.feeRateProvider = feeRateProvider

        let networkType: DashKit.NetworkType = testMode ? .testNet : .mainNet
        dashKit = try DashKit(withWords: words, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: wallet.syncMode ?? .fast), networkType: networkType, minLogLevel: .error)

        super.init(wallet: wallet, abstractKit: dashKit, addressParser: addressParser)

        dashKit.delegate = self
    }

    override func feeRate(priority: FeeRatePriority) -> Int {
        return feeRateProvider.dashFeeRate(for: priority)
    }

}

extension DashAdapter: DashKitDelegate {

    public func transactionsUpdated(inserted: [DashTransactionInfo], updated: [DashTransactionInfo]) {
        var records = [TransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

}

extension DashAdapter {

    static func clear() throws {
        try DashKit.clear()
    }

}
