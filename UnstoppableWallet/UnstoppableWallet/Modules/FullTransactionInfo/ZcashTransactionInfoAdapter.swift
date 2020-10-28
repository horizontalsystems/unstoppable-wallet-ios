import Foundation

class ZcashTransactionInfoAdapter: IFullTransactionInfoAdapter {
    private let provider: IZcashProvider
    private let feeCoinProvider: IFeeCoinProvider
    private let coin: Coin

    init(provider: IZcashProvider, feeCoinProvider: IFeeCoinProvider, coin: Coin) {
        self.provider = provider
        self.feeCoinProvider = feeCoinProvider
        self.coin = coin
    }

    func convert(json: [String: Any]) -> FullTransactionRecord? {
        guard let txResponse = provider.convert(json: json) else {
            return nil
        }

        var sections = [FullTransactionSection]()

        // Top Section

        var topSectionItems = [FullTransactionItem]()
        if let blockTime = txResponse.blockTime, let time = TimeInterval(exactly: blockTime) {
            let blockDate = Date(timeIntervalSince1970: time)
            topSectionItems.append(FullTransactionItem(icon: "Date Icon", title: "full_info.time".localized, value: DateHelper.instance.formatFullTime(from: blockDate)))
        }
        if let blockHeight = txResponse.blockHeight {
            topSectionItems.append(FullTransactionItem(icon: "Block Icon", title: "full_info.block".localized, value: "#\(blockHeight)"))
        }
        if !topSectionItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: topSectionItems))
        }

        // Fee
        var feeItems = [FullTransactionItem]()
        if let fee = txResponse.fee {
            let feeCoin = feeCoinProvider.feeCoin(coin: coin) ?? coin
            let feeValue = CoinValue(coin: feeCoin, value: fee)
            feeItems.append(FullTransactionItem(title: "full_info.fee".localized, value: ValueFormatter.instance.format(coinValue: feeValue)))
        }
        if !feeItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: feeItems))
        }

        //  INPUTS
        var inputItems = [FullTransactionItem]()
        if !txResponse.inputs.isEmpty {
            let totalInputs = txResponse.inputs.reduce(0) { $0 + $1.value }
            let totalValue = CoinValue(coin: coin, value: totalInputs)

            inputItems.append(FullTransactionItem(title: "full_info.inputs".localized, value: ValueFormatter.instance.format(coinValue: totalValue)))
        }
        for input in txResponse.inputs {
            guard let title = ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: input.value)) else {
                continue
            }
            let clickable = input.address != nil
            inputItems.append(FullTransactionItem(title: title, value: input.address ?? "full_info.no_address", clickable: clickable))
        }
        if !inputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: inputItems))
        }

        //  OUTPUTS
        var outputItems = [FullTransactionItem]()
        if !txResponse.outputs.isEmpty {
            let totalOutputs = txResponse.outputs.reduce(0) { $0 + $1.value }
            let totalValue = CoinValue(coin: coin, value: totalOutputs)

            outputItems.append(FullTransactionItem(title: "full_info.outputs".localized, value: ValueFormatter.instance.format(coinValue: totalValue)))
        }
        for output in txResponse.outputs {
            guard let title = ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: output.value)) else {
                continue
            }
            let clickable = output.address != nil
            let address = output.address ?? "full_info.no_address".localized
            outputItems.append(FullTransactionItem(title: title, value: address, clickable: clickable))
        }
        if !outputItems.isEmpty {
            sections.append(FullTransactionSection(title: nil, items: outputItems))
        }

        return FullTransactionRecord(providerName: provider.name, sections: sections)

//        if let memo = txResponse.memo, !memo.isEmpty {
//            inputOutputItems.append(FullTransactionItem(title: "full_info.memo".localized, value: memo, clickable: true))
//        }
    }

}
