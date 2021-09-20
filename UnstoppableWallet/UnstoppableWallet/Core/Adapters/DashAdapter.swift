import DashKit
import RxSwift
import HsToolKit

class DashAdapter: BitcoinBaseAdapter {
    private let feeRate = 1

    private let dashKit: Kit

    init(wallet: Wallet, syncMode: SyncMode, testMode: Bool) throws {
        guard let seed = wallet.account.type.mnemonicSeed else {
            throw AdapterError.unsupportedAccount
        }

        let networkType: Kit.NetworkType = testMode ? .testNet : .mainNet
        let logger = App.shared.logger.scoped(with: "DashKit")

        dashKit = try Kit(seed: seed, walletId: wallet.account.id, syncMode: BitcoinBaseAdapter.kitMode(from: syncMode), networkType: networkType, confirmationsThreshold: BitcoinBaseAdapter.confirmationsThreshold, logger: logger)

        super.init(abstractKit: dashKit, wallet: wallet, testMode: testMode)

        dashKit.delegate = self
    }

    override var explorerTitle: String {
        "dash.org"
    }

    override func explorerUrl(transactionHash: String) -> String? {
        testMode ? nil : "https://insight.dash.org/insight/tx/" + transactionHash
    }

}

extension DashAdapter: DashKitDelegate {

    public func transactionsUpdated(inserted: [DashTransactionInfo], updated: [DashTransactionInfo]) {
        var records = [BitcoinTransactionRecord]()

        for info in inserted {
            records.append(transactionRecord(fromTransaction: info))
        }
        for info in updated {
            records.append(transactionRecord(fromTransaction: info))
        }

        transactionRecordsSubject.onNext(records)
    }

}

extension DashAdapter: ISendDashAdapter {

    func availableBalance(address: String?) -> Decimal {
        availableBalance(feeRate: feeRate, address: address)
    }

    func validate(address: String) throws {
        try validate(address: address, pluginData: [:])
    }

    func fee(amount: Decimal, address: String?) -> Decimal {
        fee(amount: amount, feeRate: feeRate, address: address)
    }

    func sendSingle(amount: Decimal, address: String, sortMode: TransactionDataSortMode, logger: Logger) -> Single<Void> {
        sendSingle(amount: amount, address: address, feeRate: feeRate, sortMode: sortMode, logger: logger)
    }

}

extension DashAdapter {

    static func clear(except excludedWalletIds: [String]) throws {
        try Kit.clear(exceptFor: excludedWalletIds)
    }

}
