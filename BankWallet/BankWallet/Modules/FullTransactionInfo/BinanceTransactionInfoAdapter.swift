import Foundation

class BinanceTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private let provider: IBinanceProvider
    private let coin: Coin

    init(provider: IBinanceProvider, coin: Coin) {
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
        if let blockHeight = txResponse.blockHeight {
            topSectionItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockHeight)"))
        }
        if let centValue = txResponse.value {
            let value = centValue / pow(10, 8)
            let coinValue = CoinValue(coin: coin, value: value)
            topSectionItems.append(FullTransactionItem(title: "full_info.amount".localized, value: ValueFormatter.instance.format(coinValue: coinValue)))
        }
        if !topSectionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: topSectionItems))
        }

        // Fee

        // todo: use BNB coin instead of coin code
//        var feeGasItems = [FullTransactionItem]()
//        if let fee = txResponse.fee {
//            let feeValue = CoinValue(coin: "BNB", value: fee)
//            feeGasItems.append(FullTransactionItem(title: "full_info.fee".localized, value: ValueFormatter.instance.format(coinValue: feeValue)))
//        }
//        if !feeGasItems.isEmpty {
//            sections.append(FullTransactionSection(title: nil, items: feeGasItems))
//        }

        // From / To

        var inputOutputItems = [FullTransactionItem]()
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
