import Foundation

class EthereumTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private static let gWeiCode = "GWei"

    private let provider: IEthereumForksProvider
    private let coin: Coin

    init(provider: IEthereumForksProvider, coin: Coin) {
        self.provider = provider
        self.coin = coin
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = provider.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // Top Section

        var topSectionItems = [FullTransactionItem]()
        if let txId = txResponse.txId {
            topSectionItems.append(FullTransactionItem(icon: "Hash Icon", title: "", value: txId, clickable: true))
        }
        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            topSectionItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatTransactionInfoTime(from: blockDate)))
        }
        if let blockHeight = txResponse.blockHeight {
            topSectionItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockHeight)"))
        }
        if let confirmations = txResponse.confirmations {
            topSectionItems.append(FullTransactionItem(icon: "Confirmations Icon", title: "full_info.confirmations".localized, value: "\(confirmations)"))
        }
        if let weiValue = txResponse.value {
            var value: Decimal = 0
            if case .erc20(_, let decimal) = coin.type {
                value = weiValue / pow(10, decimal)
            } else {
                value = weiValue / pow(10, 18)
            }
            let coinValue = CoinValue(coinCode: coin.code, value: value)
            topSectionItems.append(FullTransactionItem(title: "full_info.amount".localized, value: ValueFormatter.instance.format(coinValue: coinValue)))
        }
        if let nonce = txResponse.nonce {
            topSectionItems.append(FullTransactionItem(title: "full_info.nonce".localized, value: "\(nonce)"))
        }
        if !topSectionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: topSectionItems))
        }

        // Fee and Gas

        var feeGasItems = [FullTransactionItem]()
        if let fee = txResponse.fee {
            let feeValue = CoinValue(coinCode: "ETH", value: fee)
            feeGasItems.append(FullTransactionItem(title: "full_info.fee".localized, value: ValueFormatter.instance.format(coinValue: feeValue)))
        }
        if let size = txResponse.size {
            feeGasItems.append(FullTransactionItem(title: "full_info.size".localized, value: "\(size) (bytes)"))
        }
        if let gasLimit = txResponse.gasLimit {
            feeGasItems.append(FullTransactionItem(title: "full_info.gas_limit".localized, titleColor: .cryptoGray, value: "\(gasLimit)"))
        }
        if let gasPrice = txResponse.gasPrice {
            let gasValue = CoinValue(coinCode: EthereumTransactionInfoAdapter.gWeiCode, value: gasPrice)
            feeGasItems.append(FullTransactionItem(title: "full_info.gas_price".localized, titleColor: .cryptoGray, value: ValueFormatter.instance.format(coinValue: gasValue)))
        }
        if let gasUsed = txResponse.gasUsed {
            feeGasItems.append(FullTransactionItem(title: "full_info.gas_used".localized, titleColor: .cryptoGray, value: "\(gasUsed)"))
        }
        if !feeGasItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: feeGasItems))
        }

        // From / To

        var inputOutputItems = [FullTransactionItem]()
        if let contractAddress = txResponse.contractAddress {
            inputOutputItems.append(FullTransactionItem(title: "full_info.contract".localized, value: contractAddress, clickable: true, showExtra: .token))
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
