import Foundation

class EthereumTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private static let gWeiCode = "GWei"

    private let provider: IEthereumForksProvider
    private let coinCode: String

    init(provider: IEthereumForksProvider, coinCode: String) {
        self.provider = provider
        self.coinCode = coinCode
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = provider.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // BLOCK
        var blockItems = [FullTransactionItem]()
        if let txId = txResponse.txId {
            blockItems.append(FullTransactionItem(icon: "Hash Icon", title: "", value: txId, clickable: true))
        }
        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            blockItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockDate)))
        }
        if let blockHeight = txResponse.blockHeight {
            blockItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockHeight)"))
        }
        if let confirmations = txResponse.confirmations {
            blockItems.append(FullTransactionItem(icon: "Confirmations Icon", title: "full_info.confirmations".localized, value: "\(confirmations)"))
        }
        if !blockItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: blockItems))
        }

        // TRANSACTION
        var transactionItems = [FullTransactionItem]()
        if let fee = txResponse.fee {
            let feeValue = CoinValue(coinCode: coinCode, value: fee)
            transactionItems.append(FullTransactionItem(title: "full_info.fee".localized, value: ValueFormatter.instance.format(coinValue: feeValue)))
        }
        if let size = txResponse.size {
            transactionItems.append(FullTransactionItem(title: "full_info.size".localized, value: "\(size) (bytes)"))
        }
        if let gasPrice = txResponse.gasPrice {
            let gasValue = CoinValue(coinCode: EthereumTransactionInfoAdapter.gWeiCode, value: gasPrice)
            transactionItems.append(FullTransactionItem(title: "full_info.gas_price".localized, value: ValueFormatter.instance.format(coinValue: gasValue)))
        }
        if let gasUsed = txResponse.gasUsed {
            let gasValue = CoinValue(coinCode: EthereumTransactionInfoAdapter.gWeiCode, value: gasUsed)
            transactionItems.append(FullTransactionItem(title: "full_info.gas_used".localized, value: ValueFormatter.instance.format(coinValue: gasValue)))
        }
        if let gasLimit = txResponse.gasLimit {
            let gasValue = CoinValue(coinCode: EthereumTransactionInfoAdapter.gWeiCode, value: gasLimit)
            transactionItems.append(FullTransactionItem(title: "full_info.gas_limit".localized, value: ValueFormatter.instance.format(coinValue: gasValue)))
        }
        if !transactionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: transactionItems))
        }

        var inputOutputItems = [FullTransactionItem]()
        if let nonce = txResponse.nonce {
            inputOutputItems.append(FullTransactionItem(title: "full_info.nonce".localized, value: "\(nonce)"))
        }
        if let value = txResponse.value {
            let coinValue = CoinValue(coinCode: coinCode, value: value)
            inputOutputItems.append(FullTransactionItem(title: "full_info.value".localized, value: ValueFormatter.instance.format(coinValue: coinValue)))
        }
        if let from = txResponse.from {
            inputOutputItems.append(FullTransactionItem(title: "full_info.from".localized, value: from, clickable: true, showExtra: .icon))
        }
        if let to = txResponse.to {
            inputOutputItems.append(FullTransactionItem(title: "full_info.to".localized, value: to, clickable: true, showExtra: .icon))
        }
        if !inputOutputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: inputOutputItems))
        }

        return FullTransactionRecord(providerName: provider.name, sections: sections)
    }
}
