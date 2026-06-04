import Combine
import Foundation

class OpenCryptoPayTransactionInfoProvider: ITransactionInfoExtraProvider {
    private let manager: OpenCryptoPayPaymentManager
    private let accountManager: AccountManager

    var updatedPublisher: AnyPublisher<Void, Never> { manager.updatedPublisher }

    init(manager: OpenCryptoPayPaymentManager, accountManager: AccountManager) {
        self.manager = manager
        self.accountManager = accountManager
    }

    func sections(item: TransactionInfoService.Item) -> [TransactionInfoModule.SectionViewItem] {
        guard let accountId = accountManager.activeAccount?.id,
              let record = try? manager.record(transactionHash: item.record.transactionHash, accountId: accountId)
        else {
            return []
        }

        var viewItems = [TransactionInfoModule.ViewItem]()

        if let merchant = record.merchant {
            viewItems.append(.value(title: "open_crypto_pay.tx_info.merchant".localized, value: merchant))
        }
        viewItems.append(.value(title: "open_crypto_pay.tx_info.payment_id".localized, value: record.paymentId))
        viewItems.append(.value(title: "open_crypto_pay.tx_info.quote_id".localized, value: record.quoteId))
        viewItems.append(.value(title: "open_crypto_pay.tx_info.proof_status".localized, value: record.proofStatus.localizedTitle))

        return [.init(viewItems)]
    }
}
