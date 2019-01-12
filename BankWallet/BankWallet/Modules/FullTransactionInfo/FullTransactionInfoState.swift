import Foundation

class FullTransactionInfoState: IFullTransactionInfoState {
    let providerName: String
    let fullUrl: String

    let transactionHash: String
    var transactionRecord: FullTransactionRecord?

    func set(transactionRecord: FullTransactionRecord) {
        self.transactionRecord = transactionRecord
    }

    init(providerName: String, url: String, transactionHash: String) {
        self.providerName = providerName
        self.fullUrl = url + transactionHash
        self.transactionHash = transactionHash
    }

}
